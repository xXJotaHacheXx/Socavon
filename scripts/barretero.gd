extends CharacterBody3D

enum Estado { INACTIVO, PERSECUCION, ATAQUE, MUERTO }

@export var vida := 40.0
@export var velocidad := 3.2
@export var dano := 12.0
@export var distancia_vision := 20.0
@export var distancia_ataque := 2.0
@export var cadencia_ataque := 1.2

var estado := Estado.INACTIVO
var jugador: Node3D
var puede_atacar := true

@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var cuerpo: MeshInstance3D = $Cuerpo


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	agente.path_desired_distance = 0.5
	agente.target_desired_distance = distancia_ataque * 0.9
	await get_tree().physics_frame


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO or jugador == null:
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


func _destello() -> void:
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(1.0, 0.3, 0.2)
	cuerpo.material_override = rojo

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(cuerpo) and estado != Estado.MUERTO:
		cuerpo.material_override = null


func _morir() -> void:
	estado = Estado.MUERTO
	velocity = Vector3.ZERO
	$CollisionShape3D.set_deferred("disabled", true)

	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.25, 0.22, 0.2)
	cuerpo.material_override = gris

	var tween := create_tween()
	tween.tween_property(self, "rotation:x", deg_to_rad(-90), 0.35)
	tween.tween_interval(3.0)
	tween.tween_property(self, "scale", Vector3(1.0, 0.02, 1.0), 0.4)
	tween.tween_callback(queue_free)
