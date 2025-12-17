extends Node2D

const ROWS = 6
const COLS = 7
const CELL_SIZE = 80

var board = []
var current_player = 1
var game_over = false
var board_position = Vector2.ZERO

# Referencias a las texturas cargadas
var background_texture = null
var board_texture = null
var piece_red_texture = null
var piece_yellow_texture = null

func _ready():
	# Cargar todas las texturas
	load_textures()
	
	# Verificar que tenemos las texturas esenciales
	if not board_texture:
		print("ERROR: No se encontró la textura del tablero (tablero.png)")
		print("Por favor, añade una imagen llamada 'tablero.png' en la carpeta del proyecto")
		return
	
	if not piece_red_texture or not piece_yellow_texture:
		print("ERROR: Faltan texturas de fichas")
		print("Añade 'ficha_roja.png' y 'ficha_amarilla.png' en la carpeta del proyecto")
		return
	
	# Crear el fondo si existe
	if background_texture:
		create_background()
	else:
		print("INFO: No se encontró fondo, el juego funcionará sin fondo")
	
	# Crear el tablero visual
	create_board_visual()
	
	# Inicializar tablero lógico
	initialize_board()
	
	# Calcular posición centrada
	calculate_board_position()
	
	# Posicionar el tablero
	position_board()
	
	# Conectar para redimensionamiento
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func load_textures():
	# Intentar cargar las texturas desde diferentes ubicaciones comunes
	background_texture = load("res://fondo.png")
	if not background_texture:
		background_texture = load("res://background.png")
	
	board_texture = load("res://tablero.png")
	if not board_texture:
		board_texture = load("res://board.png")
	
	piece_red_texture = load("res://ficha_roja.png")
	if not piece_red_texture:
		piece_red_texture = load("res://piece_red.png")
	
	piece_yellow_texture = load("res://ficha_amarilla.png")
	if not piece_yellow_texture:
		piece_yellow_texture = load("res://piece_yellow.png")

func create_background():
	var background = Sprite2D.new()
	background.texture = background_texture
	background.name = "Background"
	
	# Escalar para cubrir toda la pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	var texture_size = background_texture.get_size()
	
	if texture_size.x > 0 and texture_size.y > 0:
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		var scale = max(scale_x, scale_y) * 1.1
		
		background.scale = Vector2(scale, scale)
		background.position = viewport_size / 2
	
	background.z_index = -100
	add_child(background)

func create_board_visual():
	var board_sprite = Sprite2D.new()
	board_sprite.texture = board_texture
	board_sprite.name = "GameBoard"
	board_sprite.z_index = 0
	board_sprite.set_meta("is_board", true)
	add_child(board_sprite)

func initialize_board():
	board = []
	for y in range(ROWS):
		board.append([])
		for x in range(COLS):
			board[y].append(0)

func calculate_board_position():
	var screen_size = get_viewport().get_visible_rect().size
	var board_width = COLS * CELL_SIZE
	var board_height = ROWS * CELL_SIZE
	
	board_position = Vector2(
		(screen_size.x - board_width) / 2,
		(screen_size.y - board_height) / 2
	)

func position_board():
	for child in get_children():
		if child.has_meta("is_board"):
			child.position = board_position + Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE) / 2

func create_piece_visual(col: int, row: int):
	var piece = Sprite2D.new()
	
	# Asignar textura según jugador
	if current_player == 1:
		piece.texture = piece_red_texture
	else:
		piece.texture = piece_yellow_texture
	
	# Posicionar la ficha
	piece.position = Vector2(
		board_position.x + col * CELL_SIZE + CELL_SIZE/2,
		board_position.y + row * CELL_SIZE + CELL_SIZE/2
	)
	
	piece.z_index = 1
	piece.name = "piece_%d_%d" % [col, row]
	
	# Animación de aparición
	piece.scale = Vector2(0.1, 0.1)
	piece.modulate = Color(1, 1, 1, 0)
	
	add_child(piece)
	
	# Animación
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(piece, "scale", Vector2(1, 1), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "modulate", Color(1, 1, 1, 1), 0.2)

func _input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var col = int((mouse_pos.x - board_position.x) / CELL_SIZE)
			
			# Validar que el clic sea dentro del tablero
			if col >= 0 and col < COLS:
				if mouse_pos.y >= board_position.y and mouse_pos.y <= board_position.y + ROWS * CELL_SIZE:
					drop_piece(col)

func drop_piece(col: int):
	# Buscar la fila más baja disponible
	for row in range(ROWS - 1, -1, -1):
		if board[row][col] == 0:
			# Colocar en tablero lógico
			board[row][col] = current_player
			
			# Crear visual de la ficha
			create_piece_visual(col, row)
			
			# Verificar victoria
			if check_win(row, col):
				game_over = true
				show_winner()
				return
			
			# Verificar empate
			if is_board_full():
				game_over = true
				show_draw()
				return
			
			# Cambiar jugador
			current_player = 2 if current_player == 1 else 1
			return
	
	print("Columna llena!")

func check_win(row: int, col: int) -> bool:
	var directions = [
		Vector2(1, 0),   # Horizontal
		Vector2(0, 1),   # Vertical
		Vector2(1, 1),   # Diagonal \
		Vector2(1, -1)   # Diagonal /
	]
	
	for dir in directions:
		var count = 1
		
		# Contar en dirección positiva
		for i in range(1, 4):
			var new_row = row + dir.y * i
			var new_col = col + dir.x * i
			
			if (new_row >= 0 and new_row < ROWS and 
				new_col >= 0 and new_col < COLS and 
				board[new_row][new_col] == current_player):
				count += 1
			else:
				break
		
		# Contar en dirección negativa
		for i in range(1, 4):
			var new_row = row - dir.y * i
			var new_col = col - dir.x * i
			
			if (new_row >= 0 and new_row < ROWS and 
				new_col >= 0 and new_col < COLS and 
				board[new_row][new_col] == current_player):
				count += 1
			else:
				break
		
		if count >= 4:
			return true
	
	return false

func is_board_full() -> bool:
	for y in range(ROWS):
		for x in range(COLS):
			if board[y][x] == 0:
				return false
	return true

func show_winner():
	var winner_color = "ROJO" if current_player == 1 else "AMARILLO"
	print("¡GANADOR! Jugador ", winner_color)
	
	# Mostrar mensaje en pantalla
	var label = Label.new()
	label.text = "¡GANADOR!\nJugador " + winner_color + "!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.position = get_viewport().get_visible_rect().size / 2 - Vector2(150, 50)
	label.z_index = 100
	add_child(label)
	
	# Botón para reiniciar
	var button = Button.new()
	button.text = "JUGAR DE NUEVO"
	button.position = get_viewport().get_visible_rect().size / 2 - Vector2(75, -50)
	button.pressed.connect(_on_restart_pressed)
	button.z_index = 100
	add_child(button)

func show_draw():
	print("¡EMPATE!")
	
	var label = Label.new()
	label.text = "¡EMPATE!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.SILVER)
	label.position = get_viewport().get_visible_rect().size / 2 - Vector2(100, 50)
	label.z_index = 100
	add_child(label)
	
	var button = Button.new()
	button.text = "REINICIAR"
	button.position = get_viewport().get_visible_rect().size / 2 - Vector2(50, -50)
	button.pressed.connect(_on_restart_pressed)
	button.z_index = 100
	add_child(button)

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_viewport_size_changed():
	calculate_board_position()
	position_board()
	
	# Reposicionar fondo si existe
	for child in get_children():
		if child.name == "Background" and child.texture:
			var viewport_size = get_viewport().get_visible_rect().size
			var texture_size = child.texture.get_size()
			
			if texture_size.x > 0 and texture_size.y > 0:
				var scale_x = viewport_size.x / texture_size.x
				var scale_y = viewport_size.y / texture_size.y
				var scale = max(scale_x, scale_y) * 1.1
				
				child.scale = Vector2(scale, scale)
				child.position = viewport_size / 2
