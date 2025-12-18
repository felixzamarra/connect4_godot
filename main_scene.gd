extends Node2D

# Instancia el tablero al arrancar (MainScene)
@onready var board_scene := preload("res://scenes/Board.tscn")

func _ready() -> void:
	if ResourceLoader.exists("res://scenes/Board.tscn"):
		var b = board_scene.instantiate()
		add_child(b)
	else:
		push_error("No se encontró res://scenes/Board.tscn. Crea la escena Board.tscn en res://scenes/")
