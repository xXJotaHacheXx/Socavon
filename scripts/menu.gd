extends Control

const ETIQUETAS := ["NUEVA PARTIDA", "CONTINUAR", "SELECCIÓN DE NIVEL", "CONTROLES", "SALIR"]

@onready var botones: Array[Button] = [
	$Centro/Nueva, $Centro/Continuar, $Centro/Niveles, $Centro/Controles, $Centro/Salir,
]
@onready var niveles: Array[Button] = [%Nivel1, %Nivel2, %Nivel3, %Nivel4]

var _abridor: Button = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Partida.reiniciar()

	var sin_foco := StyleBoxEmpty.new()

	for b in botones:
		b.add_theme_stylebox_override("focus", sin_foco)
		b.focus_entered.connect(_marcar)
		b.mouse_entered.connect(b.grab_focus)

	botones[0].pressed.connect(_nueva)
	botones[1].pressed.connect(_continuar)
	botones[2].pressed.connect(_abrir_niveles)
	botones[3].pressed.connect(_abrir_controles)
	botones[4].pressed.connect(func(): get_tree().quit())

	# CONTINUAR solo sirve si ya avanzaste algo
	botones[1].disabled = Progreso.ultimo <= 1

	for i in niveles.size():
		var n := i + 1
		var b := niveles[i]
		b.add_theme_stylebox_override("focus", sin_foco)
		b.disabled = n > Progreso.desbloqueados or not Progreso.existe(n)
		b.text = "NIVEL %d  ·  BLOQUEADO" % n if b.disabled else "NIVEL %d" % n
		b.pressed.connect(func(): _jugar(n))

	%Cerrar.add_theme_stylebox_override("focus", sin_foco)
	%Cerrar.pressed.connect(_cerrar)

	botones[0].focus_neighbor_top = botones[-1].get_path()
	botones[-1].focus_neighbor_bottom = botones[0].get_path()

	_marcar()
	botones[0].grab_focus()


func _marcar() -> void:
	for i in botones.size():
		botones[i].text = ("▶  " if botones[i].has_focus() else "     ") + ETIQUETAS[i]


func _jugar(n: int) -> void:
	if not Progreso.existe(n):
		return
	Partida.reiniciar()
	Progreso.ultimo = n
	Progreso.guardar()
	get_tree().change_scene_to_file(Progreso.ruta(n))


func _nueva() -> void:
	Progreso.empezar_de_cero()
	Partida.limpiar_arsenal()
	_jugar(1)


func _continuar() -> void:
	var n := Progreso.ultimo
	if not Progreso.existe(n):        # ya terminaste el último: déjalo rejugarlo
		n = Progreso.desbloqueados
	_jugar(n)


func _abrir(panel: Control) -> void:
	if panel.visible:
		_cerrar()
		return

	_abridor = botones[2] if panel == $PanelNiveles else botones[3]

	$PanelNiveles.visible = false
	$PanelControles.visible = false
	panel.visible = true
	%Velo.visible = true

	# el menú de atrás deja de existir para el teclado
	for b in botones:
		b.focus_mode = Control.FOCUS_NONE

	if panel == $PanelNiveles:
		for b in niveles:
			if not b.disabled:
				b.grab_focus()
				return
		%Cerrar.grab_focus()


func _cerrar() -> void:
	$PanelNiveles.visible = false
	$PanelControles.visible = false
	%Velo.visible = false

	for b in botones:
		b.focus_mode = Control.FOCUS_ALL

	if _abridor != null:
		_abridor.grab_focus()
	_marcar()


func _abrir_niveles() -> void:
	_abrir($PanelNiveles)


func _abrir_controles() -> void:
	_abrir($PanelControles)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and %Velo.visible:
		_cerrar()
		get_viewport().set_input_as_handled()
