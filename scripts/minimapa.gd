extends Control

@export var metros_por_pixel := 0.7
@export var margen_visita := 1.5

var salas: Array[Dictionary] = []
var jugador: Node3D


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	await get_tree().process_frame     # deja que el nivel termine de cargar
	_recolectar()


func _recolectar() -> void:
	var mina := get_tree().get_first_node_in_group("mina")
	if mina == null:
		return

	for hijo in mina.get_children():
		if hijo is CSGBox3D and hijo.operation == CSGShape3D.OPERATION_SUBTRACTION:
			salas.append({
				"centro": Vector2(hijo.global_position.x, hijo.global_position.z),
				"tam": Vector2(hijo.size.x, hijo.size.z),
				"visto": false,
			})


func _process(_delta: float) -> void:
	if jugador == null:
		return

	var p := Vector2(jugador.global_position.x, jugador.global_position.z)

	for s in salas:
		if s["visto"]:
			continue
		var mitad: Vector2 = s["tam"] / 2.0 + Vector2(margen_visita, margen_visita)
		var d: Vector2 = (p - s["centro"]).abs()
		if d.x <= mitad.x and d.y <= mitad.y:
			s["visto"] = true

	queue_redraw()


func _draw() -> void:
	if jugador == null:
		return

	var centro := size / 2.0
	var jp := Vector2(jugador.global_position.x, jugador.global_position.z)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.03, 0.02, 0.75))

	for s in salas:
		if not s["visto"]:
			continue
		var t: Vector2 = s["tam"] / metros_por_pixel
		var esq: Vector2 = (s["centro"] - jp) / metros_por_pixel + centro - t / 2.0
		draw_rect(Rect2(esq, t), Color(0.36, 0.30, 0.23), true)
		draw_rect(Rect2(esq, t), Color(0.55, 0.45, 0.33), false, 1.0)

	# flecha del jugador, apuntando a donde mira
	var frente := -jugador.global_transform.basis.z
	var dir := Vector2(frente.x, frente.z).normalized()
	var lado := dir.rotated(PI / 2.0)
	draw_colored_polygon(PackedVector2Array([
		centro + dir * 6.0,
		centro - dir * 4.0 + lado * 3.5,
		centro - dir * 4.0 - lado * 3.5,
	]), Color(0.88, 0.63, 0.23))

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.36, 0.29), false, 1.0)
