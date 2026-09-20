extends Sprite2D

const HOJAS := [
	preload("res://assets/armas/revolver.png"),
	preload("res://assets/armas/escopeta.png"),
]
const CUADROS := [2, 3]

@export var fuerza_bamboleo := 5.0

var base := Vector2.ZERO
var _bamboleo := Vector2.ZERO
var _empuje := Vector2.ZERO
var _sacudida: Tween

@onready var jugador: CharacterBody3D = get_parent().get_parent()
@onready var arma: RayCast3D = jugador.get_node("Camera3D/RayoDisparo")


func _ready() -> void:
	base = position
	arma.arma_cambiada.connect(_al_cambiar_arma)
	arma.disparo_hecho.connect(_al_disparar)
	_al_cambiar_arma(0, "")


func _process(delta: float) -> void:
	var rapidez := Vector2(jugador.velocity.x, jugador.velocity.z).length()
	var objetivo := Vector2.ZERO

	if rapidez > 0.5 and jugador.is_on_floor():
		var b: float = jugador.tiempo_balanceo
		objetivo = Vector2(sin(b) * fuerza_bamboleo,
				absf(cos(b)) * fuerza_bamboleo * 0.8)

	_bamboleo = _bamboleo.lerp(objetivo, delta * 10.0)
	position = base + _bamboleo + _empuje


func _al_cambiar_arma(indice: int, _nombre: String) -> void:
	texture = HOJAS[indice]
	hframes = CUADROS[indice]
	frame = 0


func _al_disparar(escopeta: bool) -> void:
	_sacudir(30.0 if escopeta else 14.0, 0.26 if escopeta else 0.14)
	frame = 1

	if not escopeta:
		await get_tree().create_timer(0.07).timeout
		frame = 0
		return

	await get_tree().create_timer(0.12).timeout
	frame = 0
	await get_tree().create_timer(0.24).timeout
	frame = 2                          # el bombeo, junto con el cha-chunk
	await get_tree().create_timer(0.30).timeout
	frame = 0


func _sacudir(fuerza: float, duracion: float) -> void:
	if _sacudida:
		_sacudida.kill()
	_empuje = Vector2(0.0, fuerza)     # el arma cae y regresa
	_sacudida = create_tween()
	_sacudida.tween_property(self, "_empuje", Vector2.ZERO, duracion) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
