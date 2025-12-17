extends Node2D

# Constantes para el tablero
const ROWS = 6
const COLS = 7
const CELL_SIZE = 64

var board = []  # Tablero 2D: 0=vacío, 1=jugador1, 2=jugador2
var current_player = 1
var game_over = false

func _ready():
	# Inicializar tablero
	initialize_board()
	
	# Crear tablero visualmente
	create_board()
	
	# Centrar tablero en pantalla
	center_board()

func initialize_board():
	board = []
	for y in range(ROWS):
		board.append([])
		for x in range(COLS):
			board[y].append(0)

func create_board():
	# Fondo del tablero (rectángulo azul)
	var background = ColorRect.new()
	background.color = Color.BLUE
	background.size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	background.name = "Background"
	add_child(background)
	
	# Crear celdas (huecos para fichas)
	for y in range(ROWS):
		for x in range(COLS):
			var cell = Sprite2D.new()
			
			# Crear textura simple para el hueco
			var image = Image.create(CELL_SIZE - 8, CELL_SIZE - 8, false, Image.FORMAT_RGBA8)
			image.fill(Color.BLACK)
			
			var texture = ImageTexture.create_from_image(image)
			cell.texture = texture
			cell.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
			cell.name = "cell_%d_%d" % [x, y]
			add_child(cell)

func center_board():
	# Calcular tamaño total del tablero
	var board_width = COLS * CELL_SIZE
	var board_height = ROWS * CELL_SIZE
	
	# Obtener tamaño de pantalla
	var screen_size = get_viewport().get_visible_rect().size
	
	# Calcular posición para centrar
	var board_x = (screen_size.x - board_width) / 2
	var board_y = (screen_size.y - board_height) / 2
	
	# Mover todos los hijos (el tablero) a la posición centrada
	for child in get_children():
		child.position += Vector2(board_x, board_y)

func _input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Convertir posición del mouse a columna
			var mouse_pos = get_global_mouse_position()
			var col = int((mouse_pos.x - ((get_viewport().size.x - COLS * CELL_SIZE) / 2)) / CELL_SIZE)
			
			# Validar columna
			if col >= 0 and col < COLS:
				drop_piece(col)

func drop_piece(col):
	# Encontrar la fila más baja disponible en la columna
	for row in range(ROWS-1, -1, -1):
		if board[row][col] == 0:
			# Colocar ficha
			board[row][col] = current_player
			
			# Crear ficha visual
			create_piece(col, row)
			
			# Verificar si hay ganador
			if check_win(row, col):
				game_over = true
				print("¡Jugador ", current_player, " gana!")
				return
			
			# Cambiar jugador
			current_player = 2 if current_player == 1 else 1
			return
	
	print("Columna llena!")

func create_piece(col, row):
	var piece = Sprite2D.new()
	
	# Crear textura para la ficha
	var image = Image.create(CELL_SIZE - 16, CELL_SIZE - 16, false, Image.FORMAT_RGBA8)
	
	# Asignar color según jugador
	if current_player == 1:
		image.fill(Color.RED)  # Ficha roja
	else:
		image.fill(Color.YELLOW)  # Ficha amarilla
	
	var texture = ImageTexture.create_from_image(image)
	piece.texture = texture
	
	# Posicionar ficha
	var board_x = (get_viewport().size.x - COLS * CELL_SIZE) / 2
	var board_y = (get_viewport().size.y - ROWS * CELL_SIZE) / 2
	
	piece.position = Vector2(
		board_x + col * CELL_SIZE + CELL_SIZE/2,
		board_y + row * CELL_SIZE + CELL_SIZE/2
	)
	
	add_child(piece)

func check_win(row, col):
	var directions = [
		Vector2(1, 0),   # Horizontal
		Vector2(0, 1),   # Vertical
		Vector2(1, 1),   # Diagonal \
		Vector2(1, -1)   # Diagonal /
	]
	
	for dir in directions:
		var count = 1  # La ficha recién colocada
		
		# Contar en una dirección
		for i in range(1, 4):
			var new_row = row + dir.y * i
			var new_col = col + dir.x * i
			
			if (new_row >= 0 and new_row < ROWS and 
				new_col >= 0 and new_col < COLS and 
				board[new_row][new_col] == current_player):
				count += 1
			else:
				break
		
		# Contar en la dirección opuesta
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
