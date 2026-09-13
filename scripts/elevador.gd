extends Area3D


func _ready() -> void:
	body_entered.connect(_al_entrar)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.63, 0.23)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.5
	$MeshInstance3D.material_override = mat


func _al_entrar(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("jugador"):
		Partida.terminar_nivel()
