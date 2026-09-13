extends CanvasLayer

const ETIQUETAS := ["REANUDAR", "REINICIAR NIVEL", "SALIR AL MENÚ"]

@onready var fondo: ColorRect = $Fondo
@onready var botones: Array[Button] = [
	$Fondo/Marco/Margen/Columnas/Opciones/Reanudar,
	$Fondo/Marco/Margen/Columnas/Opciones/Reiniciar,
	$Fondo/Marco/Margen/Columnas/Opciones/Salir,
]


func _ready() -> void:
	botones[0].pressed.connect(_on_reanudar_pressed)
	botones[1].pressed.connect(_on_reiniciar_pressed)
	botones[2].pressed.connect(_on_salir_pressed)

	var sin_foco := StyleBoxEmpty.new()

	for b in botones:
		b.add_theme_stylebox_override("focus", sin_foco)
		b.focus_entered.connect(_marcar)
		b.mouse_entered.connect(b.grab_focus)

	botones[0].focus_neighbor_top = botones[-1].get_path()
	botones[-1].focus_neighbor_bottom = botones[0].get_path()

	_marcar()
	fondo.visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("pausa"):
		return
	if not Partida.nivel_activo:      # en el menú no hay nada que pausar
		return
	get_viewport().set_input_as_handled()
	if fondo.visible:
		_reanudar()
	else:
		_abrir()


func _abrir() -> void:
	_llenar_datos()
	fondo.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	botones[0].grab_focus()
	_marcar()


func _reanudar() -> void:
	fondo.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _llenar_datos() -> void:
	%Enemigos.text = "ENEMIGOS  %d / %d" % [Partida.enemigos_eliminados, Partida.enemigos_totales]
	%Secretos.text = "SECRETOS  %d / %d" % [Partida.secretos_encontrados, Partida.secretos_totales]
	%Fichas.text = "FICHAS    %d" % Partida.fichas.size()
	%Tiempo.text = "TIEMPO    %02d:%02d" % [int(Partida.tiempo) / 60, int(Partida.tiempo) % 60]


func _marcar() -> void:
	for i in botones.size():
		botones[i].text = ("▶  " if botones[i].has_focus() else "     ") + ETIQUETAS[i]


func _on_reanudar_pressed() -> void:
	_reanudar()


func _on_reiniciar_pressed() -> void:
	_reanudar()
	Partida.reiniciar()
	get_tree().reload_current_scene()


func _on_salir_pressed() -> void:
	fondo.visible = false
	get_tree().paused = false
	Partida.reiniciar()
	get_tree().change_scene_to_file("res://escenas/menu.tscn")
