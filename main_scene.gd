extends Node2D

@export var texturaFichaRoja: Texture2D
@export var texturaFichaAmarilla: Texture2D

# Margenes para alinear con el tablero
@export var margenIzquierdo: float = 82.0
@export var margenDerecho: float = 95.0
@export var margenSuperior: float = 80.0
@export var margenInferior: float = 84.0

# Ajuste de posicion de fichas (negativo = izquierda, positivo = derecha)
@export var desplazamientoFichaX: float = 0.0
@export var desplazamientoFichaY: float = 0.0

const FILAS = 7
const COLUMNAS = 7

var posicionInicioTablero = Vector2.ZERO
var tamanoCelda = Vector2(100, 100)
var posicionInicioRejilla = Vector2.ZERO

var datosTablero = [] # 0: Vacio, 1: Rojo, 2: Amarillo
var jugadorActual = 1 # 1: Rojo, 2: Amarillo
var juegoTerminado = false

# Indicadores de turno
var indicadorRojo: Sprite2D
var indicadorAmarillo: Sprite2D
var animacionIndicador: Tween

@onready var spriteTablero = $Board
@onready var contenedorFichas = $PiecesContainer
@onready var etiquetaPuntuacion = $UI/ScoreLabel
@onready var panelFinJuego = $UI/GameOverPanel
@onready var etiquetaResultado = $UI/GameOverPanel/ResultLabel
@onready var botonReiniciar = $UI/GameOverPanel/RestartButton
@onready var botonMenu = $UI/GameOverPanel/MenuButton

func _ready():
	botonReiniciar.pressed.connect(reiniciarJuego)
	botonMenu.pressed.connect(volverAlMenu)
	
	# Escalar fondo para ajustar a la pantalla
	var tamanoPantalla = get_viewport_rect().size
	$Background.scale = tamanoPantalla / $Background.texture.get_size()
	
	# Escalar tablero para ajustar al 80% de la pantalla
	var tamanoTexturaTablero = spriteTablero.texture.get_size()
	
	var anchoObjetivo = tamanoPantalla.x * 0.8
	var altoObjetivo = tamanoPantalla.y * 0.8
	
	var escalaX = anchoObjetivo / tamanoTexturaTablero.x
	var escalaY = altoObjetivo / tamanoTexturaTablero.y
	
	var escalaFinal = min(escalaX, escalaY)
	
	spriteTablero.scale = Vector2(escalaFinal, escalaFinal)
	
	# Centrar tablero
	var tamanoTableroFinal = tamanoTexturaTablero * escalaFinal
	spriteTablero.position = (tamanoPantalla - tamanoTableroFinal) / 2
	posicionInicioTablero = spriteTablero.position
	
	# Calcular logica de cuadricula (escalada)
	var margenIzqEscalado = margenIzquierdo * escalaFinal
	var margenDerEscalado = margenDerecho * escalaFinal
	var margenSupEscalado = margenSuperior * escalaFinal
	var margenInfEscalado = margenInferior * escalaFinal
	
	# Ancho util es el ancho total menos margenes izquierdo y derecho
	var anchoUtil = tamanoTableroFinal.x - margenIzqEscalado - margenDerEscalado
	var altoUtil = tamanoTableroFinal.y - margenSupEscalado - margenInfEscalado
	
	tamanoCelda.x = anchoUtil / COLUMNAS
	tamanoCelda.y = altoUtil / FILAS
	
	# Definir donde empieza la cuadricula (esquina superior izquierda)
	posicionInicioRejilla = posicionInicioTablero + Vector2(margenIzqEscalado, margenSupEscalado)
	
	# Crear indicadores de turno
	crearIndicadoresDeTurno(tamanoPantalla, tamanoTableroFinal)
	
	iniciarJuego()

func crearIndicadoresDeTurno(tamanoPantalla: Vector2, tamanoTablero: Vector2):
	# Calcular posiciones a los lados del tablero
	var yIndicador = tamanoPantalla.y / 2
	var xIzquierda = (tamanoPantalla.x - tamanoTablero.x) / 4
	var xDerecha = tamanoPantalla.x - xIzquierda
	
	# Indicador rojo (izquierda)
	indicadorRojo = Sprite2D.new()
	indicadorRojo.texture = texturaFichaRoja
	indicadorRojo.position = Vector2(xIzquierda, yIndicador)
	var escalaFicha = (tamanoTablero.x * 0.20) / texturaFichaRoja.get_size().x
	indicadorRojo.scale = Vector2(escalaFicha, escalaFicha)
	add_child(indicadorRojo)
	
	# Indicador amarillo (derecha)
	indicadorAmarillo = Sprite2D.new()
	indicadorAmarillo.texture = texturaFichaAmarilla
	indicadorAmarillo.position = Vector2(xDerecha, yIndicador)
	indicadorAmarillo.scale = Vector2(escalaFicha, escalaFicha)
	add_child(indicadorAmarillo)
	
	# Iniciar parpadeo del jugador actual
	actualizarIndicadorDeTurno()

func actualizarIndicadorDeTurno():
	# Detener animacion anterior
	if animacionIndicador:
		animacionIndicador.kill()
	
	# Resetear opacidad
	indicadorRojo.modulate = Color(1, 1, 1, 0.3)
	indicadorAmarillo.modulate = Color(1, 1, 1, 0.3)
	
	# Animar el indicador del jugador actual
	var indicadorActivo = indicadorRojo if jugadorActual == 1 else indicadorAmarillo
	animacionIndicador = create_tween()
	animacionIndicador.set_loops()
	animacionIndicador.tween_property(indicadorActivo, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.5)
	animacionIndicador.tween_property(indicadorActivo, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func iniciarJuego():
	juegoTerminado = false
	panelFinJuego.hide()
	jugadorActual = 1
	
	# Limpiar tablero logico
	datosTablero = []
	for f in range(FILAS):
		var fila = []
		for c in range(COLUMNAS):
			fila.append(0)
		datosTablero.append(fila)
	
	# Limpiar fichas visuales
	for hijo in contenedorFichas.get_children():
		hijo.queue_free()
		
	actualizarMostrarPuntuacion()
	actualizarIndicadorDeTurno()

func actualizarMostrarPuntuacion():
	etiquetaPuntuacion.text = "ROJO: %d   -   AMARILLO: %d" % [GestorPuntuacion.victoriasRojas, GestorPuntuacion.victoriasAzules]

func _input(evento):
	# No permitir clicks si el juego termino
	if juegoTerminado:
		return
		
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var posicionMouse = get_global_mouse_position()
		
		# Verificar si el click esta dentro de la cuadricula horizontalmente
		if posicionMouse.x >= posicionInicioRejilla.x and posicionMouse.x < posicionInicioRejilla.x + (COLUMNAS * tamanoCelda.x):
			# Verificar si el click esta dentro de la cuadricula verticalmente
			if posicionMouse.y >= posicionInicioRejilla.y and posicionMouse.y < posicionInicioRejilla.y + (FILAS * tamanoCelda.y):
				var xRelativa = posicionMouse.x - posicionInicioRejilla.x
				var columna = int(xRelativa / tamanoCelda.x)
				
				# Soltar ficha en esa columna si es valida
				if columna >= 0 and columna < COLUMNAS:
					soltarFicha(columna)

func soltarFicha(col):
	for fila in range(FILAS - 1, -1, -1):
		if datosTablero[fila][col] == 0:
			# Encontro espacio vacio
			datosTablero[fila][col] = jugadorActual
			await agregarFichaVisualAnimada(fila, col, jugadorActual)
			
			var fichasGanadoras = verificarVictoria(fila, col)
			if fichasGanadoras.size() > 0:
				# Detener parpadeo de indicador
				if animacionIndicador:
					animacionIndicador.kill()
				
				# Marcar el juego como terminado ANTES de resaltar
				juegoTerminado = true
				
				# Resaltar piezas ganadoras
				resaltarFichasGanadoras(fichasGanadoras)
				await get_tree().create_timer(1.5).timeout
				manejarVictoria()
			elif verificarEmpate():
				juegoTerminado = true
				manejarEmpate()
			else:
				# Cambiar jugador (1 <-> 2)
				jugadorActual = 3 - jugadorActual
				actualizarIndicadorDeTurno()
			
			return

func agregarFichaVisualAnimada(fila, col, jugador):
	var ficha = Sprite2D.new()
	if jugador == 1:
		ficha.texture = texturaFichaRoja
	else:
		ficha.texture = texturaFichaAmarilla
	
	# Redimensionar ficha para ajustar a celda (con padding) manteniendo aspecto 1:1
	var tamanoFicha = ficha.texture.get_size()
	
	# Usar la dimension mas pequena de la celda para asegurar que encaje
	var dimMinimaCelda = min(tamanoCelda.x, tamanoCelda.y)
	
	# Tamano objetivo es 82% de la dimension mas pequena (menos espacio entre fichas)
	var dimObjetivo = dimMinimaCelda * 0.82 
	
	# Calcular factor de escala uniforme
	var factorEscala = dimObjetivo / max(tamanoFicha.x, tamanoFicha.y)
	
	ficha.scale = Vector2(factorEscala, factorEscala)
	
	var posX = posicionInicioRejilla.x + (col * tamanoCelda.x) + (tamanoCelda.x / 2) + desplazamientoFichaX
	var posYFinal = posicionInicioRejilla.y + (fila * tamanoCelda.y) + (tamanoCelda.y / 2) + desplazamientoFichaY
	
	# Empezar desde arriba del tablero
	var yInicio = posicionInicioRejilla.y - 100
	ficha.position = Vector2(posX, yInicio)
	
	contenedorFichas.add_child(ficha)
	
	# Animar caida
	var animacion = create_tween()
	animacion.tween_property(ficha, "position:y", posYFinal, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await animacion.finished

func verificarVictoria(fila, col):
	var jugador = datosTablero[fila][col]
	var direcciones = [
		Vector2(1, 0), # Horizontal
		Vector2(0, 1), # Vertical
		Vector2(1, 1), # Diagonal \
		Vector2(1, -1) # Diagonal /
	]
	
	for dir in direcciones:
		var posicionesGanadoras = [Vector2(col, fila)] # Empezar con ficha actual
		
		# Verificar direccion positiva
		for i in range(1, 4):
			var f = fila + (dir.y * i)
			var c = col + (dir.x * i)
			if f >= 0 and f < FILAS and c >= 0 and c < COLUMNAS and datosTablero[f][c] == jugador:
				posicionesGanadoras.append(Vector2(c, f))
			else:
				break
				
		# Verificar direccion negativa
		for i in range(1, 4):
			var f = fila - (dir.y * i)
			var c = col - (dir.x * i)
			if f >= 0 and f < FILAS and c >= 0 and c < COLUMNAS and datosTablero[f][c] == jugador:
				posicionesGanadoras.append(Vector2(c, f))
			else:
				break
				
		if posicionesGanadoras.size() >= 4:
			return posicionesGanadoras
	
	return [] # No hay victoria

func resaltarFichasGanadoras(posicionesGanadoras: Array):
	# Encontrar y resaltar las fichas ganadoras
	for hijo in contenedorFichas.get_children():
		var colFicha = int((hijo.position.x - posicionInicioRejilla.x) / tamanoCelda.x)
		var filaFicha = int((hijo.position.y - posicionInicioRejilla.y) / tamanoCelda.y)
		
		for pos in posicionesGanadoras:
			if colFicha == int(pos.x) and filaFicha == int(pos.y):
				# Resaltar la ficha ganadora (hacerla mas brillante)
				var animacion = create_tween()
				animacion.set_loops(3)
				animacion.tween_property(hijo, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.25)
				animacion.tween_property(hijo, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
				break

func verificarEmpate():
	for fila in datosTablero:
		if 0 in fila:
			return false
	return true

func manejarVictoria():
	var nombreGanador = "ROJO" if jugadorActual == 1 else "AMARILLO"
	etiquetaResultado.text = "GANO %s!" % nombreGanador
	
	if jugadorActual == 1:
		GestorPuntuacion.victoriasRojas += 1
	else:
		GestorPuntuacion.victoriasAzules += 1
		
	actualizarMostrarPuntuacion()
	panelFinJuego.show()

func manejarEmpate():
	etiquetaResultado.text = "EMPATE!"
	panelFinJuego.show()

func reiniciarJuego():
	iniciarJuego()

func volverAlMenu():
	get_tree().change_scene_to_file("res://Menu.tscn")
