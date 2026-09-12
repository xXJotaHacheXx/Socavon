extends RayCast3D

@export var dano := 20.0
@export var cadencia := 0.45
@export var retroceso := 0.08

var listo := true

@onready var camara: Camera3D = get_parent()
@onready var jugador: CharacterBody3D = camara.get_parent()
@onready var fogonazo: OmniLight3D = $Fogonazo


func _ready() -> void:
	add_exception(jugador)
	fogonazo.visible = false


func _physics_process(_delta: float) -> void:
	if listo and Input.is_action_pressed("disparar"):
		_disparar()


func _disparar() -> void:
	listo = false

	camara.position.z = retroceso
	create_tween().tween_property(camara, "position:z", 0.0, 0.12)

	fogonazo.visible = true

	force_raycast_update()
	if is_colliding():
		var objetivo := get_collider()
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano)

	await get_tree().create_timer(0.05).timeout
	fogonazo.visible = false

	await get_tree().create_timer(cadencia - 0.05).timeout
	listo = true
