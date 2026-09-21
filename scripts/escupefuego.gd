extends CharacterBody3D

enum Estado { INACTIVO, ACERCARSE, ALEJARSE, CARGAR, MUERTO }

const FILA_REPOSO := 0
const FILAS_ANDAR := [1, 2, 3, 4]
const FILA_CARGAR := 5
const FILA_ESCUPIR := 6
const FILA_MUERTE := 7

const BOLA := preload("res://escenas/bola.tscn")

@export var fps_animacion := 6.0
@export var vida := 70.0
@export var velocidad := 2.5
@export var distancia_vision := 24.0
@export var distancia_ideal := 9.0
@export var margen := 3.0
@export var cadencia := 2.4
@export var tiempo_carga := 0.65

var estado := Estado.INACTIVO
var jugador: Node3D
var puede_escupir := true
var _t_anim := 0.0
var _dolor := 0.0
var _escupiendo := 0.0

const S_GRITO := preload("res://assets/audio/escupefuego_grito.wav")
const S_ESCUPIR := preload("res://assets/audio/escupefuego_escupir.wav")
const S_DOLOR := preload("res://assets/audio/escupefuego_dolor.wav")
const S_MUERTE := preload("res://assets/audio/escupefuego_muerte.wav")

@onready var voz: AudioStreamPlayer3D = $Voz
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: Sprite3D = $Cuerpo
@onready var boca: Marker3D = $Boca


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	agente.path_desired_distance = 1.0
	agente.target_desired_distance = distancia_ideal
	_t_anim = randf() * 4.0
	await get_tree().physics_frame


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		_animar(delta)
		return

	if jugador == null:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var d := global_position.distance_to(jugador.global_position)
	_escupiendo = max(_escupiendo - delta, 0.0)

	match estado:
		Estado.INACTIVO:
			velocity.x = 0.0
			velocity.z = 0.0
			if d < distancia_vision and _ve_al_jugador():
				estado = Estado.ACERCARSE
				_sonar(S_GRITO)

		Estado.ACERCARSE:
			if d <= distancia_ideal + margen and _ve_al_jugador():
				estado = Estado.CARGAR
			else:
				_caminar(1.0)

		Estado.ALEJARSE:
			if d >= distancia_ideal:
				estado = Estado.CARGAR
			else:
				_caminar(-1.0)

		Estado.CARGAR:
			velocity.x = 0.0
			velocity.z = 0.0
			if d < distancia_ideal - margen:
				estado = Estado.ALEJARSE
			elif d > distancia_ideal + margen or not _ve_al_jugador():
				estado = Estado.ACERCARSE
			else:
				_escupir()

	if estado != Estado.INACTIVO:
		_mirar_al_jugador()

	_animar(delta)
	move_and_slide()


func _caminar(signo: float) -> void:
	var direccion: Vector3

	if signo > 0.0:                       # acercarse: por el navmesh
		agente.target_position = jugador.global_position
		direccion = agente.get_next_path_position() - global_position
	else:                                 # alejarse: en línea recta hacia atrás
		direccion = global_position - jugador.global_position

	direccion.y = 0.0
	direccion = direccion.normalized()

	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad


func _escupir() -> void:
	if not puede_escupir:
		return

	puede_escupir = false
	_escupiendo = tiempo_carga + 0.4      # se hincha, luego escupe

	await get_tree().create_timer(tiempo_carga - 0.2).timeout
	if estado == Estado.MUERTO:
		return

	_sonar(S_ESCUPIR)                     # la arcada dura 0.2 s antes del chorro
	await get_tree().create_timer(0.2).timeout
	if estado == Estado.MUERTO or jugador == null:
		return

	var origen := boca.global_position
	var hacia := (jugador.global_position + Vector3.UP * 0.9) - origen

	var b := BOLA.instantiate()
	get_tree().current_scene.add_child(b)
	b.lanzar(origen, hacia)

	await get_tree().create_timer(cadencia).timeout
	puede_escupir = true


func _mirar_al_jugador() -> void:
	var objetivo := jugador.global_position
	objetivo.y = global_position.y
	if global_position.distance_to(objetivo) > 0.1:
		look_at(objetivo, Vector3.UP)


func _ve_al_jugador() -> bool:
	var espacio := get_world_3d().direct_space_state
	var desde := global_position + Vector3.UP * 1.1
	var hasta := jugador.global_position + Vector3.UP * 1.0

	var consulta := PhysicsRayQueryParameters3D.create(desde, hasta)
	consulta.exclude = [get_rid()]

	var golpe := espacio.intersect_ray(consulta)
	return golpe.is_empty() or golpe.get("collider") == jugador


func recibir_dano(cantidad: float) -> void:
	if estado == Estado.MUERTO:
		return

	if estado == Estado.INACTIVO:
		estado = Estado.ACERCARSE
		_sonar(S_GRITO)

	vida -= cantidad
	_destello()

	if vida <= 0.0:
		_morir()


func _animar(delta: float) -> void:
	_t_anim += delta * fps_animacion
	_dolor = max(_dolor - delta, 0.0)

	if estado == Estado.MUERTO:
		sprite.frame = FILA_MUERTE * 8 + clampi(int(_t_anim * 0.25), 0, 4)
		return

	var fila := FILA_REPOSO
	if _escupiendo > 0.4:
		fila = FILA_CARGAR
	elif _escupiendo > 0.0:
		fila = FILA_ESCUPIR
	elif estado == Estado.ACERCARSE or estado == Estado.ALEJARSE:
		fila = FILAS_ANDAR[int(_t_anim) % 4]

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
	sprite.modulate = Color(2.5, 1.2, 0.6)

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
	$Brasa.visible = false


func _sonar(s: AudioStream) -> void:
	voz.stream = s
	voz.pitch_scale = randf_range(0.9, 1.05)
	voz.play()
