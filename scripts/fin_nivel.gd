extends CanvasLayer

@onready var enemigos: Label = $Fondo/Centro/Enemigos
@onready var secretos: Label = $Fondo/Centro/Secretos
@onready var tiempo: Label = $Fondo/Centro/Tiempo


func _ready() -> void:
	visible = false
	Partida.nivel_terminado.connect(_mostrar)


func _mostrar(datos: Dictionary) -> void:
	enemigos.text = "ENEMIGOS   %d / %d   %d%%" % [
		datos["enemigos"], datos["enemigos_totales"],
		_porcentaje(datos["enemigos"], datos["enemigos_totales"])
	]

	secretos.text = "SECRETOS   %d / %d   %d%%" % [
		datos["secretos"], datos["secretos_totales"],
		_porcentaje(datos["secretos"], datos["secretos_totales"])
	]

	tiempo.text = "TIEMPO   %s   (par %s)" % [
		_reloj(datos["tiempo"]), _reloj(datos["par"])
	]

	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed("ui_accept"):
		get_tree().paused = false
		Partida.reiniciar()
		get_tree().reload_current_scene()


func _porcentaje(parte: int, total: int) -> int:
	return 0 if total == 0 else roundi(float(parte) / total * 100.0)


func _reloj(segundos: float) -> String:
	return "%d:%02d" % [int(segundos) / 60, int(segundos) % 60]
