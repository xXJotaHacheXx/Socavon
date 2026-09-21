extends Area3D

@export var velocidad := 13.0
@export var dano := 18.0
@export var duracion := 5.0
@export var fps := 14.0

var direccion := Vector3.FORWARD
var _vivo := true
var _t := 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var luz: OmniLight3D = $Luz
@onready var sonido: AudioStreamPlayer3D = $Sonido


func _ready() -> void:
	body_entered.connect(_al_chocar)


func lanzar(desde: Vector3, hacia: Vector3) -> void:
	global_position = desde
	direccion = hacia.normalized()


func _physics_process(delta: float) -> void:
	_t += delta
	if not _vivo:
		return

	global_position += direccion * velocidad * delta
	sprite.frame = int(_t * fps) % 4

	if _t > duracion:          # por si se va por un hueco y nunca choca
		_apagar()


func _al_chocar(cuerpo: Node3D) -> void:
	if not _vivo:
		return

	if cuerpo.is_in_group("enemigos"):    # no se matan entre ellos
		return

	if cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dano)

	_apagar()


func _apagar() -> void:
	_vivo = false
	sprite.visible = false
	luz.visible = false
	set_deferred("monitoring", false)
	sonido.play()

	await sonido.finished
	queue_free()
