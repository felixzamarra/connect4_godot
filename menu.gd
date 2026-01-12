extends Control

func _ready():
	# Actualizar etiquetas de puntuacion
	$VBoxContainer/ScoreLabel.text = "PUNTUACIÓN ACTUAL\n\nROJO: %d   -   AZUL: %d" % [GestorPuntuacion.victoriasRojas, GestorPuntuacion.victoriasAzules]
	
	# Conectar boton
	$VBoxContainer/PlayButton.pressed.connect(_al_presionar_jugar)

func _al_presionar_jugar():
	get_tree().change_scene_to_file("res://MainScene.tscn")
