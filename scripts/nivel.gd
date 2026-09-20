extends Node3D

@export var numero := 1
@export var tiempo_par := 300.0


func _ready() -> void:
	Partida.preparar_nivel(tiempo_par)
	Partida.nivel_terminado.connect(_al_terminar)


func _al_terminar(_datos: Dictionary) -> void:
	Progreso.completar(numero)
