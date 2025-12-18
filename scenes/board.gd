extends Node2D

const COLUMNS := 7
const ROWS := 6
const CONNECT := 4

@export var CELL_SIZE: float = 64.0
@export var board_origin: Vector2 = Vector2.ZERO
@export var piece_scene_path: String = "res://scenes/Piece.tscn"
@export var grid_rect: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)

@onready var piece_scene = load(piece_scene_path)
@onready var pieces_root: Node = get_node_or_null("Grid")
@onready var marker: Node = get_node_or_null("Marker")
@onready var turn_label: Label = get_node_or_null("CanvasLayer/UI/TurnLabel")
@onready var game_counter_label: Label = get_node_or_null("CanvasLayer/UI/GameCounter")
@onready var message_label: Label = get_node_or_null("CanvasLayer/UI/MessageLabel")
@onready var new_game_btn: Button = get_node_or_null("CanvasLayer/UI/Buttons/NewGameButton")
@onready var reset_btn: Button = get_node_or_null("CanvasLayer/UI/Buttons/ResetButton")

var grid: Array = []
var current_player: int = 1
var input_locked: bool = false
var games_played: int = 0

func _ready() -> void:
	if grid_rect.size != Vector2.ZERO:
		_compute_grid_from_rect()
	_init_grid()
	_update_ui()
	if marker:
		marker.visible = false
	if new_game_btn:
		new_game_btn.pressed.connect(Callable(self,"_on_new_game_pressed"))
	if reset_btn:
		reset_btn.pressed.connect(Callable(self,"_on_reset_pressed"))

func _compute_grid_from_rect() -> void:
	var w := grid_rect.size.x
	var h := grid_rect.size.y
	if w <= 0 or h <= 0:
		push_warning("grid_rect inválido. Mide el área de huecos y pon la Rect2 en el Inspector.")
		return
	var cell_w := w / float(COLUMNS)
	var cell_h := h / float(ROWS)
	CELL_SIZE = min(cell_w, cell_h)
	board_origin = grid_rect.position
	print("Grid calculada: origin=", board_origin, " CELL_SIZE=", CELL_SIZE)

func _init_grid() -> void:
	grid.clear()
	for c in range(COLUMNS):
		var col := []
		for r in range(ROWS):
			col.append(0)
		grid.append(col)
	if pieces_root:
		for child in pieces_root.get_children():
			child.queue_free()
	current_player = 1
	input_locked = false
	if message_label:
		message_label.visible = false

func _update_ui() -> void:
	if turn_label:
		turn_label.text = "Turno: Jugador %d" % current_player
	if game_counter_label:
		game_counter_label.text = "Partidas: %d" % games_played

func _process(delta: float) -> void:
	if input_locked:
		if marker and marker.visible:
			marker.visible = false
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var local = to_local(mouse_pos)
	var col = int((local.x - board_origin.x) / CELL_SIZE)
	if col >= 0 and col < COLUMNS:
		if marker:
			marker.visible = true
			var mx = board_origin.x + col * CELL_SIZE + CELL_SIZE * 0.5
			var my = board_origin.y + CELL_SIZE * 0.5
			marker.position = Vector2(mx, my)
	else:
		if marker:
			marker.visible = false

func _input(event) -> void:
	if input_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = to_local(event.position)
		var col = int((local_pos.x - board_origin.x) / CELL_SIZE)
		if col >= 0 and col < COLUMNS:
			_drop_piece_in_column(col)

func _drop_piece_in_column(col: int) -> void:
	var row_to_place := -1
	for r in range(ROWS):
		if grid[col][r] == 0:
			row_to_place = r
	if row_to_place == -1:
		_flash_marker()
		return
	input_locked = true
	if not piece_scene:
		push_error("No se pudo cargar res://scenes/Piece.tscn. Revisa piece_scene_path.")
		input_locked = false
		return
	var piece = piece_scene.instantiate()
	if piece == null:
		push_error("No se pudo instanciar Piece.tscn - revisa la ruta: %s" % piece_scene_path)
		input_locked = false
		return
	# asigna jugador y escala para que quepa
	if piece.has_method("set_player"):
		piece.call_deferred("set_player", current_player)
	# añadimos a la escena antes de ajustar transformaciones que dependen del parent
	if pieces_root:
		pieces_root.add_child(piece)
	else:
		add_child(piece)
	# ajustar escala para que quepa en la celda
	if piece.has_method("fit_to_cell"):
		piece.call_deferred("fit_to_cell", CELL_SIZE)
	var start_local = board_origin + Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, -CELL_SIZE * 1.2)
	piece.position = start_local
	var dest_local = board_origin + Vector2(col * CELL_SIZE + CELL_SIZE * 0.5,
		(ROWS - 1 - row_to_place) * CELL_SIZE + CELL_SIZE * 0.5)
	var duration = 0.22 + 0.04 * row_to_place
	var tween = create_tween()
	tween.tween_property(piece, "position", dest_local, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "scale", Vector2(0.95,1.05), duration * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_drop_finished").bind(col, row_to_place, piece))

func _flash_marker() -> void:
	if not marker or not marker.visible:
		return
	var t = create_tween()
	t.tween_property(marker, "modulate:a", 0.2, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(marker, "modulate:a", 0.8, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_drop_finished(col: int, row: int, piece: Node) -> void:
	if piece:
		piece.scale = Vector2.ONE
	grid[col][row] = current_player
	if _check_win(col, row, current_player):
		if message_label:
			message_label.text = "¡Jugador %d gana!" % current_player
			message_label.visible = true
		input_locked = true
		games_played += 1
		_update_ui()
	else:
		current_player = 3 - current_player
		_update_ui()
		input_locked = false

func _check_win(col: int, row: int, player: int) -> bool:
	var dirs = [Vector2(1,0), Vector2(0,1), Vector2(1,1), Vector2(1,-1)]
	for d in dirs:
		var count = 1
		count += _count_dir(col, row, int(d.x), int(d.y), player)
		count += _count_dir(col, row, -int(d.x), -int(d.y), player)
		if count >= CONNECT:
			return true
	return false

func _count_dir(col: int, row: int, dc: int, dr: int, player: int) -> int:
	var c := col + dc
	var r := row + dr
	var cnt := 0
	while c >= 0 and c < COLUMNS and r >= 0 and r < ROWS and grid[c][r] == player:
		cnt += 1
		c += dc
		r += dr
	return cnt

func _on_new_game_pressed() -> void:
	_init_grid()
	_update_ui()

func _on_reset_pressed() -> void:
	games_played = 0
	_update_ui()
