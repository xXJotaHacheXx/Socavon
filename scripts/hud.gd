extends CanvasLayer

@onready var jugador: CharacterBody3D = get_parent()
@onready var arma: RayCast3D = jugador.get_node("Camera3D/RayoDisparo")

@onready var salud: Label = $Placa/Stats/Salud/Valor
@onready var armadura: Label = $Placa/Stats/Armadura/Valor
@onready var municion: Label = $Placa/Stats/Municion/Valor


func _ready() -> void:
	jugador.salud_cambiada.connect(_al_cambiar_salud)
	jugador.armadura_cambiada.connect(_al_cambiar_armadura)
	arma.municion_cambiada.connect(_al_cambiar_municion)

	_al_cambiar_salud(jugador.vida_maxima, jugador.vida_maxima)
	_al_cambiar_armadura(jugador.armadura_inicial)
	_al_cambiar_municion(arma.municion_maxima, arma.municion_maxima)


func _al_cambiar_salud(actual: float, maxima: float) -> void:
	salud.text = "%d%%" % actual
	if actual <= maxima * 0.25:
		salud.modulate = Color(1.0, 0.25, 0.2)
	else:
		salud.modulate = Color(0.5, 0.66, 0.29)


func _al_cambiar_armadura(actual: float) -> void:
	armadura.text = "%d%%" % actual
	armadura.modulate = Color(0.31, 0.53, 0.66)


func _al_cambiar_municion(actual: int, maxima: int) -> void:
	municion.text = str(actual)
	if actual < 10:
		municion.modulate = Color(1.0, 0.25, 0.2)
	else:
		municion.modulate = Color(0.88, 0.63, 0.23)
