extends CharacterBody3D

enum Estado { INACTIVO, PERSECUCION, ATAQUE, RETIRADA, MUERTO }

const FILA_REPOSO := 0
const FILAS_CORRER := [1, 2, 3, 4]
const FILA_ATAQUE := 5
const FILA_DOLOR := 6
const FILA_MUERTE := 7

@export var fps_animacion := 12.0
@export var vida := 20.0
@export var velocidad := 7.5
@export var dano := 10.0
@export var distancia_vision := 26.0
@export var distancia_ataque := 1.9
@export var cadencia_ataque := 0.9
@export var retirada_duracion := 0.7
@export var amplitud_zigzag := 0.55
@export var ritmo_zigzag := 5.0

var estado := Estado.INACTIVO
var jugador: Node3D
var puede_atacar := true
var _t_anim := 0.0
var _dolor := 0.0
var _zigzag := 0.0
var _retirada := 0.0

const S_GRITO := preload("res://assets/audio/nahual_grito.wav")
const S_GOLPE := preload("res://assets/audio/nahual_golpe.wav")
const S_DOLOR := preload("res://assets/audio/nahual_dolor.wav")
const S_MUERTE := preload("res://assets/audio/nahual_muerte.wav")

@onready var voz: AudioStreamPlayer3D = $Voz
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: Sprite3D = $Cuerpo


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	agente.path_desired_distance = 1.0
	agente.target_desired_distance = distancia_ataque * 0.9
	_zigzag = randf() * TAU          # que no vayan todos sincronizados
	await get_tree().physics_frame


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		_animar(delta)
		return

	if jugador == null:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var distancia := global_position.distance_to(jugador.global_position)

	match estado:
		Estado.INACTIVO:
			velocity.x = 0.0
			velocity.z = 0.0
			if distancia < distancia_vision and _ve_al_jugador():
				estado = Estado.PERSECUCION
				_sonar(S_GRITO)

		Estado.PERSECUCION:
			if distancia <= distancia_ataque:
				estado = Estado.ATAQUE
			else:
				_perseguir(delta)

		Estado.ATAQUE:
			velocity.x = 0.0
			velocity.z = 0.0
			if distancia > distancia_ataque * 1.5:
				estado = Estado.PERSECUCION
			else:
				_atacar()

		Estado.RETIRADA:
			_retirar(delta)

	if estado != Estado.INACTIVO:
		_mirar_al_jugador()

	_animar(delta)
	move_and_slide()


func _perseguir(delta: float) -> void:
	agente.target_position = jugador.global_position
	var siguiente := agente.get_next_path_position()

	var direccion := siguiente - global_position
	direccion.y = 0.0
	direccion = direccion.normalized()

	# el zigzag del GDD: se balancea de lado mientras corre
	_zigzag += delta * ritmo_zigzag
	var lado := direccion.cross(Vector3.UP)
	direccion = (direccion + lado * sin(_zigzag) * amplitud_zigzag).normalized()

	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad


func _retirar(delta: float) -> void:
	_retirada = max(_retirada - delta, 0.0)

	var huida := global_position - jugador.global_position
	huida.y = 0.0
	huida = huida.normalized()

	velocity.x = huida.x * velocidad * 0.75
	velocity.z = huida.z * velocidad * 0.75

	if _retirada <= 0.0:
		estado = Estado.PERSECUCION


func _mirar_al_jugador() -> void:
	var objetivo := jugador.global_position
	objetivo.y = global_position.y
	if global_position.distance_to(objetivo) > 0.1:
		look_at(objetivo, Vector3.UP)


func _ve_al_jugador() -> bool:
	var espacio := get_world_3d().direct_space_state
	var desde := global_position + Vector3.UP * 0.8
	var hasta := jugador.global_position + Vector3.UP * 1.0

	var consulta := PhysicsRayQueryParameters3D.create(desde, hasta)
	consulta.exclude = [get_rid()]

	var golpe := espacio.intersect_ray(consulta)
	return golpe.is_empty() or golpe.get("collider") == jugador


func _atacar() -> void:
	if not puede_atacar:
		return

	puede_atacar = false
	_sonar(S_GOLPE)
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)

	# muerde y se va: no se queda pegado como el Barretero
	_retirada = retirada_duracion
	estado = Estado.RETIRADA

	await get_tree().create_timer(cadencia_ataque).timeout
	puede_atacar = true


func recibir_dano(cantidad: float) -> void:
	if estado == Estado.MUERTO:
		return

	if estado == Estado.INACTIVO:
		estado = Estado.PERSECUCION
		_sonar(S_GRITO)

	vida -= cantidad
	_destello()

	if vida <= 0.0:
		_morir()


func _animar(delta: float) -> void:
	_t_anim += delta * fps_animacion
	_dolor = max(_dolor - delta, 0.0)

	if estado == Estado.MUERTO:
		sprite.frame = FILA_MUERTE * 8 + clampi(int(_t_anim * 0.3), 0, 4)
		return

	var fila := FILA_REPOSO
	if _dolor > 0.0:
		fila = FILA_DOLOR
	elif estado == Estado.ATAQUE:
		fila = FILA_ATAQUE
	elif estado == Estado.PERSECUCION or estado == Estado.RETIRADA:
		fila = FILAS_CORRER[int(_t_anim) % 4]

	sprite.frame = fila * 8 + _columna_direccion()


func _columna_direccion() -> int:
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return 0

	var hacia_camara := camara.global_position - global_position
	var adelante := -global_transform.basis.z

	var angulo := atan2(hacia_camara.x, hacia_camara.z) - atan2(adelante.x, adelante.z)
	var col := int(round(angulo / TAU * 8.0)) % 8
	return col if col >= 0 else col + 8


func _destello() -> void:
	if estado != Estado.MUERTO:
		_sonar(S_DOLOR)

	_dolor = 0.2
	sprite.modulate = Color(2.5, 0.8, 0.6)

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE


func _morir() -> void:
	estado = Estado.MUERTO
	_sonar(S_MUERTE)
	velocity = Vector3.ZERO
	_t_anim = 0.0
	Partida.enemigo_eliminado()
	$CollisionShape3D.set_deferred("disabled", true)


func _sonar(s: AudioStream) -> void:
	voz.stream = s
	voz.pitch_scale = randf_range(0.94, 1.1)
	voz.play()
