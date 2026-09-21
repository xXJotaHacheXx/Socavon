extends Area3D

@export var dano := 7.0
@export var intervalo := 0.55

var _dentro: Array[Node3D] = []
var _t := 0.0


func _ready() -> void:
	body_entered.connect(_entra)
	body_exited.connect(_sale)


func _entra(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	if cuerpo in _dentro:
		return

	_dentro.append(cuerpo)
	_t = intervalo               # el primer ardor es inmediato


func _sale(cuerpo: Node3D) -> void:
	_dentro.erase(cuerpo)


func _process(delta: float) -> void:
	if _dentro.is_empty():
		return

	_t += delta
	if _t < intervalo:
		return

	_t = 0.0
	for c in _dentro:
		if is_instance_valid(c) and c.has_method("recibir_dano"):
			c.recibir_dano(dano)
