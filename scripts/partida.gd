extends Node

signal ficha_obtenida(cual: String)
signal aviso(texto: String)

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
