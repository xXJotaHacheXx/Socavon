extends Node

const RUTA := "user://progreso.cfg"
const TOTAL := 4

var desbloqueados := 1     # hasta qué nivel puede entrar
var ultimo := 1            # en cuál se quedó


func _ready() -> void:
	cargar()


func ruta(n: int) -> String:
	return "res://escenas/nivel%d.tscn" % n


func existe(n: int) -> bool:
	return ResourceLoader.exists(ruta(n))


func completar(n: int) -> void:
	ultimo = n + 1                                        # puede quedar en 5 = "ya acabaste"
	desbloqueados = clampi(maxi(desbloqueados, ultimo), 1, TOTAL)
	guardar()


func empezar_de_cero() -> void:
	ultimo = 1               # ojo: NO borra lo desbloqueado
	guardar()


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("avance", "desbloqueados", desbloqueados)
	cfg.set_value("avance", "ultimo", ultimo)
	cfg.save(RUTA)


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	desbloqueados = cfg.get_value("avance", "desbloqueados", 1)
	ultimo = cfg.get_value("avance", "ultimo", 1)
