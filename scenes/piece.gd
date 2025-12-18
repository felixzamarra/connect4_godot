extends Node2D

@export var tex_player1: Texture2D
@export var tex_player2: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

# Asigna la textura según el jugador (1 o 2)
func set_player(p: int) -> void:
	if p == 1:
		sprite.texture = tex_player1
	elif p == 2:
		sprite.texture = tex_player2

# Ajusta escala del sprite para que quepa en una celda (CELL_SIZE)
func fit_to_cell(cell_size: float) -> void:
	if not sprite.texture:
		return
	var tex_w = sprite.texture.get_size().x
	if tex_w <= 0:
		return
	var desired = (cell_size * 0.9) / tex_w
	sprite.scale = Vector2.ONE * desired

# Pequeño efecto visual opcional
func play_pop_effect() -> void:
	sprite.scale = Vector2(0.8, 0.8)
	var t = create_tween()
	t.tween_property(sprite, "scale", Vector2.ONE * sprite.scale.x, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
