extends CharacterBody3D

signal salud_cambiada(actual: float, maxima: float)
signal armadura_cambiada(actual: float)

@export var armadura_inicial := 50.0
@export var velocidad_caminar := 6.0
@export var velocidad_correr := 9.5
@export var sensibilidad := 0.0025
@export var vida_maxima := 100.0
@export var aceleracion := 45.0
@export var friccion := 60.0
@export var balanceo_fuerza := 0.06
@export var balanceo_ritmo := 12.0
@export var factor_agua := 0.55

var vida := 100.0
var estamina := 100.0
var armadura := 0.0
var tiempo_balanceo := 0.0
var camara_y := 0.0

const PASOS := [
	preload("res://assets/audio/paso1.wav"),
	preload("res://assets/audio/paso2.wav"),
	preload("res://assets/audio/paso3.wav"),
	preload("res://assets/audio/paso4.wav"),
]
var _dist_paso := 0.0

const PASOS_AGUA := [
	preload("res://assets/audio/agua_paso1.wav"),
	preload("res://assets/audio/agua_paso2.wav"),
	preload("res://assets/audio/agua_paso3.wav"),
]
var _aguas := 0          # en cuántas zonas de agua está metido

@onready var sonido_pasos: AudioStreamPlayer3D = $SonidoPasos
@onready var sonido_voz: AudioStreamPlayer3D = $SonidoVoz
@onready var camara: Camera3D = $Camera3D
@onready var destello: ColorRect = $HUD/Dano

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camara_y = camara.position.y
	vida = vida_maxima
	armadura = armadura_inicial


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		rotate_y(-evento.relative.x * sensibilidad)
		camara.rotate_x(-evento.relative.y * sensibilidad)
		camara.rotation.x = clamp(camara.rotation.x, deg_to_rad(-75), deg_to_rad(75))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var direccion := (transform.basis * Vector3(entrada.x, 0.0, entrada.y)).normalized()

	var corriendo := Input.is_action_pressed("correr") and estamina > 0.0 and direccion != Vector3.ZERO

	if corriendo:
		estamina = max(estamina - 25.0 * delta, 0.0)
	else:
		estamina = min(estamina + 33.0 * delta, 100.0)


	var vel := velocidad_correr if corriendo else velocidad_caminar
	if _aguas > 0:
		vel *= factor_agua

	if direccion != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direccion.x * vel, aceleracion * delta)
		velocity.z = move_toward(velocity.z, direccion.z * vel, aceleracion * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)
		velocity.z = move_toward(velocity.z, 0.0, friccion * delta)

	move_and_slide()
	
	var fov_objetivo := 82.0 if corriendo else 75.0
	camara.fov = lerp(camara.fov, fov_objetivo, delta * 8.0)
		
	_balanceo(delta)
	_sonar_pasos(delta)


func _balanceo(delta: float) -> void:
	var rapidez := Vector2(velocity.x, velocity.z).length()

	if rapidez > 0.5 and is_on_floor():
		tiempo_balanceo += delta * balanceo_ritmo * (rapidez / velocidad_caminar)
		camara.position.y = camara_y + sin(tiempo_balanceo) * balanceo_fuerza
		camara.position.x = cos(tiempo_balanceo * 0.5) * balanceo_fuerza * 0.6
	else:
		tiempo_balanceo = 0.0
		camara.position.y = lerp(camara.position.y, camara_y, delta * 10.0)
		camara.position.x = lerp(camara.position.x, 0.0, delta * 10.0)


func recibir_dano(cantidad: float) -> void:
	if armadura > 0.0:
		var absorbido: float = min(cantidad, armadura)
		armadura -= absorbido
		cantidad -= absorbido
		armadura_cambiada.emit(armadura)

	if cantidad > 0.0:
		vida -= cantidad
		salud_cambiada.emit(vida, vida_maxima)
		sonido_voz.play()

	destello.color = Color(0.2, 0.5, 1.0) if armadura > 0.0 else Color(1.0, 0.0, 0.13)
	destello.color.a = 0.45
	create_tween().tween_property(destello, "color:a", 0.0, 0.25)

	if vida <= 0.0:
		Partida.reiniciar()
		get_tree().reload_current_scene()


func _sonar_pasos(delta: float) -> void:
	var rapidez := Vector2(velocity.x, velocity.z).length()

	if rapidez < 0.5 or not is_on_floor():
		return

	_dist_paso += rapidez * delta

	if _dist_paso >= 2.2:
		_dist_paso = 0.0
		sonido_pasos.stream = (PASOS_AGUA if _aguas > 0 else PASOS).pick_random()
		sonido_pasos.pitch_scale = randf_range(0.9, 1.1)
		sonido_pasos.play()


func entrar_agua() -> void:
	_aguas += 1


func salir_agua() -> void:
	_aguas = maxi(_aguas - 1, 0)
