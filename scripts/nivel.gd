extends Node3D

@export var tiempo_par := 300.0


func _ready() -> void:
	Partida.preparar_nivel(tiempo_par)
