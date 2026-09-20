extends Area3D

@export var cantidad := 12

var altura_base := 0.0
var tiempo := 0.0

@onready var malla: MeshInstance3D = $MeshInstance3D
@onready var sonido: AudioStreamPlayer3D = $Sonido


func _ready() -> void:
	altura_base = malla.position.y
	body_entered.connect(_al_entrar)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.63, 0.23)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.5
	malla.material_override = mat


func _process(delta: float) -> void:
	tiempo += delta
	malla.rotate_y(1.4 * delta)
	malla.position.y = altura_base + sin(tiempo * 2.0) * 0.08


func _al_entrar(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return

	var arma := get_tree().get_first_node_in_group("arma")
	if arma == null or not arma.has_method("recargar"):
		return

	if not arma.recargar(cantidad):
		Partida.avisar("MUNICIÓN LLENA")
		return

	Partida.avisar("+%d CARTUCHOS" % cantidad)
	sonido.play()
	malla.visible = false
	set_deferred("monitoring", false)

	await sonido.finished
	queue_free()
