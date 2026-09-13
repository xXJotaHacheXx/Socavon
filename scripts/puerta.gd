extends StaticBody3D

const NOMBRES := {"estano": "ESTAÑO", "cobre": "COBRE"}

@export_enum("estano", "cobre") var ficha_requerida: String = "estano"
@export var altura_apertura := 3.4

var abierta := false

@onready var malla: MeshInstance3D = $MeshInstance3D
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var zona: Area3D = $Zona


func _ready() -> void:
	zona.body_entered.connect(_al_acercarse)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.55) if ficha_requerida == "estano" else Color(0.77, 0.27, 0.12)
	malla.material_override = mat


func _al_acercarse(cuerpo: Node3D) -> void:
	if abierta or not cuerpo.is_in_group("jugador"):
		return

	if Partida.tiene_ficha(ficha_requerida):
		_abrir()
	else:
		Partida.avisar("NECESITAS LA FICHA DE " + NOMBRES[ficha_requerida])
		_rechazar()


func _abrir() -> void:
	abierta = true
	colision.set_deferred("disabled", true)
	create_tween().tween_property(self, "position:y", position.y + altura_apertura, 0.9)


func _rechazar() -> void:
	var t := create_tween()
	t.tween_property(malla, "position:z", 0.12, 0.06)
	t.tween_property(malla, "position:z", -0.12, 0.06)
	t.tween_property(malla, "position:z", 0.0, 0.06)
