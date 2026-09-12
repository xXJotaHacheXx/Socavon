extends StaticBody3D

@export var vida := 60.0

@onready var malla: MeshInstance3D = $MeshInstance3D


func recibir_dano(cantidad: float) -> void:
	vida -= cantidad
	print("Impacto. Vida restante: ", vida)
	_destello()

	if vida <= 0.0:
		queue_free()


func _destello() -> void:
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(1.0, 0.2, 0.1)
	malla.material_override = rojo

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(malla):
		malla.material_override = null
