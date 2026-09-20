extends Area3D


func _ready() -> void:
	body_entered.connect(_entra)
	body_exited.connect(_sale)


func _entra(cuerpo: Node3D) -> void:
	if cuerpo.has_method("entrar_agua"):
		cuerpo.entrar_agua()


func _sale(cuerpo: Node3D) -> void:
	if cuerpo.has_method("salir_agua"):
		cuerpo.salir_agua()
