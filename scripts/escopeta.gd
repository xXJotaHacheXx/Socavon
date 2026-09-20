extends Area3D

@export var vuelo := 0.09

var altura_base := 0.0
var tiempo := 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var sonido: AudioStreamPlayer3D = $Sonido


func _ready() -> void:
	altura_base = sprite.position.y
	body_entered.connect(_al_entrar)


func _process(delta: float) -> void:
	tiempo += delta
	sprite.position.y = altura_base + sin(tiempo * 2.0) * vuelo


func _al_entrar(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return

	var arma := get_tree().get_first_node_in_group("arma")
	if arma == null or not arma.has_method("recoger_escopeta"):
		return

	arma.recoger_escopeta()
	Partida.avisar("ESCOPETA")
	sonido.play()
	sprite.visible = false
	set_deferred("monitoring", false)

	await sonido.finished
	queue_free()
