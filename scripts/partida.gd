extends Node

signal ficha_obtenida(cual: String)
signal aviso(texto: String)
signal nivel_terminado(datos: Dictionary)

var enemigos_totales := 0
var enemigos_eliminados := 0
var secretos_totales := 0
var secretos_encontrados := 0
var tiempo := 0.0
var tiempo_par := 300.0
var nivel_activo := false
var fichas: Array[String] = []


func agregar_ficha(cual: String) -> void:
	if cual in fichas:
		return
	fichas.append(cual)
	ficha_obtenida.emit(cual)


func tiene_ficha(cual: String) -> bool:
	return cual in fichas


func avisar(texto: String) -> void:
	aviso.emit(texto)


func reiniciar() -> void:
	fichas.clear()
	nivel_activo = false


func _process(delta: float) -> void:
	if nivel_activo:
		tiempo += delta


func preparar_nivel(par: float) -> void:
	enemigos_totales = get_tree().get_nodes_in_group("enemigos").size()
	secretos_totales = get_tree().get_nodes_in_group("secretos").size()
	enemigos_eliminados = 0
	secretos_encontrados = 0
	tiempo = 0.0
	tiempo_par = par
	nivel_activo = true


func enemigo_eliminado() -> void:
	enemigos_eliminados += 1


func secreto_encontrado() -> void:
	secretos_encontrados += 1
	avisar("SECRETO ENCONTRADO")


func terminar_nivel() -> void:
	if not nivel_activo:
		return

	nivel_activo = false
	nivel_terminado.emit({
		"enemigos": enemigos_eliminados,
		"enemigos_totales": enemigos_totales,
		"secretos": secretos_encontrados,
		"secretos_totales": secretos_totales,
		"tiempo": tiempo,
		"par": tiempo_par,
	})
