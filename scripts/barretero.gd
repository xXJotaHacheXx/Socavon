extends CharacterBody3D

enum Estado { INACTIVO, PERSECUCION, ATAQUE, MUERTO }

const FILA_REPOSO := 0
const FILAS_CAMINAR := [1, 2, 3, 4]
const FILA_ATAQUE := 5
const FILA_DOLOR := 6
const FILA_MUERTE := 7

@export var fps_animacion := 8.0
@export var vida := 40.0
@export var velocidad := 3.2
@export var dano := 12.0
@export var distancia_vision := 20.0
@export var distancia_ataque := 2.0
@export var cadencia_ataque := 1.2

var estado := Estado.INACTIVO
var jugador: Node3D
var puede_atacar := true
var _t_anim := 0.0
var _dolor := 0.0

@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: Sprite3D = $Cuerpo

func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	agente.path_desired_distance = 0.5
	agente.target_desired_distance = distancia_ataque * 0.9
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

		Estado.PERSECUCION:
			if distancia <= distancia_ataque:
				estado = Estado.ATAQUE
			else:
				_perseguir()

		Estado.ATAQUE:
			velocity.x = 0.0
			velocity.z = 0.0
			if distancia > distancia_ataque * 1.4:
				estado = Estado.PERSECUCION
			else:
				_atacar()

	if estado != Estado.INACTIVO:
		_mirar_al_jugador()

	_animar(delta)
	move_and_slide()
	


func _perseguir() -> void:
	agente.target_position = jugador.global_position
	var siguiente := agente.get_next_path_position()
	var direccion := (siguiente - global_position).normalized()
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad


func _mirar_al_jugador() -> void:
	var objetivo := jugador.global_position
	objetivo.y = global_position.y
	if global_position.distance_to(objetivo) > 0.1:
		look_at(objetivo, Vector3.UP)


func _ve_al_jugador() -> bool:
	var espacio := get_world_3d().direct_space_state
	var desde := global_position + Vector3.UP * 1.5
	var hasta := jugador.global_position + Vector3.UP * 1.0

	var consulta := PhysicsRayQueryParameters3D.create(desde, hasta)
	consulta.exclude = [get_rid()]

	var golpe := espacio.intersect_ray(consulta)
	return golpe.is_empty() or golpe.get("collider") == jugador


func _atacar() -> void:
	if not puede_atacar:
		return

	puede_atacar = false
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)

	await get_tree().create_timer(cadencia_ataque).timeout
	puede_atacar = true


func recibir_dano(cantidad: float) -> void:
	if estado == Estado.MUERTO:
		return

	vida -= cantidad
	if estado == Estado.INACTIVO:
		estado = Estado.PERSECUCION

	_destello()

	if vida <= 0.0:
		_morir()


func _animar(delta: float) -> void:
	_t_anim += delta * fps_animacion
	_dolor = max(_dolor - delta, 0.0)

	if estado == Estado.MUERTO:
		sprite.frame = FILA_MUERTE * 8 + clampi(int(_t_anim * 0.35), 0, 4)
		return

	var fila := FILA_REPOSO
	if _dolor > 0.0:
		fila = FILA_DOLOR
	elif estado == Estado.ATAQUE:
		fila = FILA_ATAQUE
	elif estado == Estado.PERSECUCION:
		fila = FILAS_CAMINAR[int(_t_anim) % 4]

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
	_dolor = 0.25
	sprite.modulate = Color(2.5, 0.8, 0.6)

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE


func _morir() -> void:
	estado = Estado.MUERTO
	velocity = Vector3.ZERO
	_t_anim = 0.0
	Partida.enemigo_eliminado()
	$CollisionShape3D.set_deferred("disabled", true)
