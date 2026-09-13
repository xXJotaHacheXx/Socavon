extends Area3D

const NOMBRES := {"estano": "ESTAÑO", "cobre": "COBRE"}

@export_enum("estano", "cobre") var tipo: String = "estano"

var altura_base := 0.0
var tiempo := 0.0

@onready var malla: MeshInstance3D = $MeshInstance3D
@onready var sonido: AudioStreamPlayer3D = $Sonido

func _ready() -> void:
	altura_base = malla.position.y
	body_entered.connect(_al_entrar)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.55) if tipo == "estano" else Color(0.77, 0.27, 0.12)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	malla.material_override = mat


func _process(delta: float) -> void:
	tiempo += delta
	malla.rotate_y(2.0 * delta)
	malla.position.y = altura_base + sin(tiempo * 2.5) * 0.12


func _al_entrar(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return

	Partida.agregar_ficha(tipo)
	Partida.avisar("FICHA DE " + NOMBRES[tipo])

	sonido.play()
	malla.visible = false
	set_deferred("monitoring", false)

	await sonido.finished
	queue_free()
