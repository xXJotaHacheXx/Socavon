extends RayCast3D

signal municion_cambiada(actual: int, maxima: int)
signal arma_cambiada(indice: int, nombre: String)
signal disparo_hecho(escopeta: bool)

enum Arma { REVOLVER, ESCOPETA }

@export var dano := 20.0
@export var cadencia := 0.45
@export var retroceso := 0.08
@export var municion_maxima := 48

@export var tiene_escopeta := false
@export var dano_perdigon := 9.0
@export var perdigones := 7
@export var dispersion := 0.09
@export var cadencia_escopeta := 0.95
@export var retroceso_escopeta := 0.22
@export var cartuchos_maximos := 24

const ALCANCE := 50.0
const NOMBRES := ["REVOLVER", "ESCOPETA"]

var arma := Arma.REVOLVER
var listo := true
var municion := 48
var cartuchos := 0

@onready var camara: Camera3D = get_parent()
@onready var jugador: CharacterBody3D = camara.get_parent()
@onready var sonido: AudioStreamPlayer3D = $Sonido
@onready var sonido_escopeta: AudioStreamPlayer3D = $SonidoEscopeta
@onready var fogonazo: OmniLight3D = $Fogonazo


func _ready() -> void:
	add_exception(jugador)
	fogonazo.visible = false
	target_position = Vector3(0.0, 0.0, -ALCANCE)

	if Partida.arsenal_guardado:
		tiene_escopeta = Partida.arsenal_escopeta
		municion = Partida.arsenal_balas
		cartuchos = Partida.arsenal_postas
	else:
		municion = municion_maxima
		cartuchos = cartuchos_maximos / 2 if tiene_escopeta else 0



func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("arma1"):
		_cambiar(Arma.REVOLVER)
	elif evento.is_action_pressed("arma2") and tiene_escopeta:
		_cambiar(Arma.ESCOPETA)


func _physics_process(_delta: float) -> void:
	if not listo:
		return

	if arma == Arma.ESCOPETA:
		if cartuchos > 0 and Input.is_action_just_pressed("disparar"):
			_disparar_escopeta()
	elif municion > 0 and Input.is_action_pressed("disparar"):
		_disparar()


func _cambiar(cual: int) -> void:
	if cual == arma or not listo:
		return
	arma = cual
	arma_cambiada.emit(arma, NOMBRES[arma])
	_avisar_municion()


func _avisar_municion() -> void:
	if arma == Arma.ESCOPETA:
		municion_cambiada.emit(cartuchos, cartuchos_maximos)
	else:
		municion_cambiada.emit(municion, municion_maxima)


func _golpear(direccion: Vector3, cuanto: float) -> void:
	target_position = direccion
	force_raycast_update()
	if is_colliding():
		var objetivo := get_collider()
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(cuanto)


func _disparar() -> void:
	listo = false
	municion -= 1
	municion_cambiada.emit(municion, municion_maxima)
	disparo_hecho.emit(false)

	camara.position.z = retroceso
	create_tween().tween_property(camara, "position:z", 0.0, 0.12)

	fogonazo.light_energy = 4.0
	fogonazo.visible = true
	sonido.pitch_scale = randf_range(0.96, 1.04)
	sonido.play()

	_golpear(Vector3(0.0, 0.0, -ALCANCE), dano)

	await get_tree().create_timer(0.05).timeout
	fogonazo.visible = false
	await get_tree().create_timer(cadencia - 0.05).timeout
	listo = true


func _disparar_escopeta() -> void:
	listo = false
	cartuchos -= 1
	municion_cambiada.emit(cartuchos, cartuchos_maximos)
	disparo_hecho.emit(true)

	camara.position.z = retroceso_escopeta
	create_tween().tween_property(camara, "position:z", 0.0, 0.22)

	fogonazo.light_energy = 9.0
	fogonazo.visible = true
	sonido_escopeta.pitch_scale = randf_range(0.95, 1.05)
	sonido_escopeta.play()

	for i in perdigones:
		var angulo := randf() * TAU
		var radio := sqrt(randf()) * dispersion      # raiz = reparto parejo en el cono
		var d := Vector3(cos(angulo) * radio, sin(angulo) * radio, -1.0)
		_golpear(d.normalized() * ALCANCE, dano_perdigon)

	target_position = Vector3(0.0, 0.0, -ALCANCE)

	await get_tree().create_timer(0.07).timeout
	fogonazo.visible = false
	fogonazo.light_energy = 4.0
	await get_tree().create_timer(cadencia_escopeta - 0.07).timeout
	listo = true


func recargar(cantidad: int) -> bool:
	if municion >= municion_maxima:
		return false
	municion = min(municion + cantidad, municion_maxima)
	if arma == Arma.REVOLVER:
		municion_cambiada.emit(municion, municion_maxima)
	return true


func recargar_escopeta(cantidad: int) -> bool:
	if cartuchos >= cartuchos_maximos:
		return false
	cartuchos = min(cartuchos + cantidad, cartuchos_maximos)
	if arma == Arma.ESCOPETA:
		municion_cambiada.emit(cartuchos, cartuchos_maximos)
	return true


func recoger_escopeta() -> void:
	tiene_escopeta = true
	cartuchos = maxi(cartuchos, 8)
	_cambiar(Arma.ESCOPETA)


func anunciar() -> void:
	arma_cambiada.emit(arma, NOMBRES[arma])
	_avisar_municion()
