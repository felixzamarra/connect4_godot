extends Node2D

const ROWS = 6
const COLS = 7
const BOARD_WIDTH = 700
const BOARD_HEIGHT = 600
const CELL_WIDTH = BOARD_WIDTH / COLS
const CELL_HEIGHT = BOARD_HEIGHT / ROWS
const HOLE_RADIUS = CELL_WIDTH * 0.35
const PIECE_RADIUS = HOLE_RADIUS * 0.85

var board = []
var current_player = 1
var game_over = false
var board_position = Vector2.ZERO

func _ready():
	# Calcular posición centrada
	calculate_board_position()
	
	# Inicializar tablero
	board = []
	for y in range(ROWS):
		board.append([])
		for x in range(COLS):
			board[y].append(0)
	
	# Redibujar
	queue_redraw()

func calculate_board_position():
	var screen_size = get_viewport().get_visible_rect().size
	board_position = Vector2(
		(screen_size.x - BOARD_WIDTH) / 2,
		(screen_size.y - BOARD_HEIGHT) / 2
	)

func _draw():
	# Fondo sólido
	var screen_size = get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.2, 0.2, 0.3))
	
	# Dibujar tablero
	draw_board()
	
	# Dibujar fichas
	draw_pieces()

func draw_board():
	# Fondo del tablero
	var board_rect = Rect2(board_position, Vector2(BOARD_WIDTH, BOARD_HEIGHT))
	draw_rect(board_rect, Color(0.1, 0.3, 0.8))
	
	# Borde
	draw_rect(board_rect, Color(0.05, 0.2, 0.6), false, 3.0)
	
	# Agujeros
	for row in range(ROWS):
		for col in range(COLS):
			var center = Vector2(
				board_position.x + col * CELL_WIDTH + CELL_WIDTH / 2,
				board_position.y + row * CELL_HEIGHT + CELL_HEIGHT / 2
			)
			draw_circle(center, HOLE_RADIUS, Color.BLACK)

func draw_pieces():
	for row in range(ROWS):
		for col in range(COLS):
			if board[row][col] != 0:
				var center = Vector2(
					board_position.x + col * CELL_WIDTH + CELL_WIDTH / 2,
					board_position.y + row * CELL_HEIGHT + CELL_HEIGHT / 2
				)
				
				var color = Color.RED if board[row][col] == 1 else Color.YELLOW
				draw_circle(center, PIECE_RADIUS, color)

func _input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			
			if (mouse_pos.x >= board_position.x and 
				mouse_pos.x <= board_position.x + BOARD_WIDTH and
				mouse_pos.y >= board_position.y and 
				mouse_pos.y <= board_position.y + BOARD_HEIGHT):
				
				var relative_x = mouse_pos.x - board_position.x
				var col = int(relative_x / CELL_WIDTH)
				col = clamp(col, 0, COLS - 1)
				
				drop_piece(col)

func drop_piece(col: int):
	for row in range(ROWS - 1, -1, -1):
		if board[row][col] == 0:
			board[row][col] = current_player
			queue_redraw()
			
			if check_win(row, col):
				game_over = true
				show_message("¡GANADOR!\nJugador " + ("ROJO" if current_player == 1 else "AMARILLO"))
				return
			
			if is_board_full():
				game_over = true
				show_message("¡EMPATE!")
				return
			
			current_player = 2 if current_player == 1 else 1
			return

func check_win(row: int, col: int) -> bool:
	var directions = [
		Vector2(1, 0), Vector2(0, 1), 
		Vector2(1, 1), Vector2(1, -1)
	]
	
	for dir in directions:
		var count = 1
		
		for i in range(1, 4):
			var new_row = row + int(dir.y * i)
			var new_col = col + int(dir.x * i)
			
			if (new_row >= 0 and new_row < ROWS and 
				new_col >= 0 and new_col < COLS and 
				board[new_row][new_col] == current_player):
				count += 1
			else:
				break
		
		for i in range(1, 4):
			var new_row = row - int(dir.y * i)
			var new_col = col - int(dir.x * i)
			
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

func show_message(text: String):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var screen_size = get_viewport().get_visible_rect().size
	label.position = screen_size / 2 - Vector2(100, 25)
	label.z_index = 100
	
	add_child(label)
	
	var button = Button.new()
	button.text = "REINICIAR"
	button.position = screen_size / 2 + Vector2(-50, 50)
	button.pressed.connect(func(): get_tree().reload_current_scene())
	button.z_index = 100
	
	add_child(button)

func _on_viewport_size_changed():
	calculate_board_position()
	queue_redraw()
