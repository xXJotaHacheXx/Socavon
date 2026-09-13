extends Control

const ETIQUETAS := ["NUEVA PARTIDA", "CONTROLES", "SALIR"]

@onready var botones: Array[Button] = [$Centro/Nueva, $Centro/Controles, $Centro/Salir]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Partida.reiniciar()

	for b in botones:
		b.focus_entered.connect(_marcar)
		b.mouse_entered.connect(b.grab_focus)   # que el mouse mueva el cursor también

	# que el foco dé la vuelta: de SALIR bajas a NUEVA y al revés
	botones[0].focus_neighbor_top = botones[-1].get_path()
	botones[-1].focus_neighbor_bottom = botones[0].get_path()

	botones[0].grab_focus()


func _marcar() -> void:
	for i in botones.size():
		botones[i].text = ("▶  " if botones[i].has_focus() else "     ") + ETIQUETAS[i]


func _on_nueva_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/nivel1.tscn")


func _on_controles_pressed() -> void:
	$PanelControles.visible = not $PanelControles.visible


func _on_salir_pressed() -> void:
	get_tree().quit()
