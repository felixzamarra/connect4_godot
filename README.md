# Connect 4 - Juego de 4 en Raya

Juego clasico de 4 en raya desarrollado en Godot 4 para dos jugadores.

## Caracteristicas

- Tablero 7x7 con animaciones de caida y efecto rebote
- Indicadores visuales de turno con parpadeo
- Resaltado de linea ganadora
- Sistema de puntuacion persistente
- Interfaz responsiva

## Estructura del Proyecto

```
connect-4/
├── assets/               # Recursos graficos (fichas, tablero, fondos)
├── main_scene.gd         # Logica principal del juego
├── MainScene.tscn        # Escena del tablero
├── menu.gd               # Logica del menu
├── Menu.tscn             # Escena del menu
├── ScoreManager.gd       # GestorPuntuacion (Autoload)
└── project.godot
```

**Nota:** El archivo se llama `ScoreManager.gd` pero internamente usa nombres en español con camelCase.

## Arquitectura del Proyecto

### Escenas Principales

#### 1. Menu.tscn
Pantalla inicial del juego que muestra:
- Titulo del juego con tipografia grande y visible
- Puntuacion actual de ambos jugadores
- Boton para iniciar una nueva partida
- Todos los textos tienen contorno negro para mejor legibilidad

**Componentes:**
- `Control` (nodo raiz) - Contenedor principal del menu
- `TextureRect` (Background) - Fondo de pantalla escalable
- `VBoxContainer` - Organizador vertical de elementos
  - `Label` (TitleLabel) - Titulo "4 EN RAYA" (64px, contorno 8px)
  - `Label` (ScoreLabel) - Muestra puntuaciones (32px, contorno 6px)
  - `Button` (PlayButton) - Boton "JUGAR" (32px, contorno 5px)

#### 2. MainScene.tscn
Escena principal del juego con tablero interactivo:
- Tablero visual centrado y escalado al 80% de la pantalla
- Sistema de deteccion de clicks por coordenadas
- Indicadores laterales animados que muestran el turno
- Panel de fin de juego con opciones de reinicio

**Componentes:**
- `Node2D` (nodo raiz) - Contenedor principal del juego
- `Sprite2D` (Background) - Fondo escalado a pantalla completa
- `Node2D` (PiecesContainer) - Contenedor dinamico para fichas jugadas
- `Sprite2D` (Board) - Imagen del tablero con z-index 10
- `CanvasLayer` (UI) - Capa de interfaz sobre el juego
  - `Label` (ScoreLabel) - Marcador en tiempo real (32px, contorno 6px)
  - `Panel` (GameOverPanel) - Panel semi-transparente de fin de juego
    - `Label` (ResultLabel) - Mensaje de victoria/empate (48px, contorno 7px)
    - `Button` (RestartButton) - Reiniciar partida (24px, contorno 4px)
    - `Button` (MenuButton) - Volver al menu (24px, contorno 4px)

#### 3. GestorPuntuacion (ScoreManager.gd - Autoload)
Singleton global que mantiene el estado entre escenas:
- Contador de victorias rojas
- Contador de victorias azules/amarillas
- Funcion para reiniciar puntuaciones
- Persiste durante toda la ejecucion del juego

---

## Logica del Juego (main_scene.gd)

### Constantes
```gdscript
const FILAS = 7      # Numero de filas del tablero
const COLUMNAS = 7   # Numero de columnas del tablero
```

### Variables Exportadas (Configurables desde el Editor)
```gdscript
@export var texturaFichaRoja: Texture2D      # Textura de la ficha roja
@export var texturaFichaAmarilla: Texture2D  # Textura de la ficha amarilla
@export var margenIzquierdo: float = 82.0    # Margen izquierdo del area jugable
@export var margenDerecho: float = 95.0      # Margen derecho del area jugable
@export var margenSuperior: float = 80.0     # Margen superior del area jugable
@export var margenInferior: float = 84.0     # Margen inferior del area jugable
@export var desplazamientoFichaX: float = 0.0  # Ajuste fino horizontal
@export var desplazamientoFichaY: float = 0.0  # Ajuste fino vertical
```

### Variables de Estado del Juego
```gdscript
var datosTablero = []              # Matriz 7x7 (0=vacio, 1=rojo, 2=amarillo)
var jugadorActual = 1              # Jugador en turno (1=rojo, 2=amarillo)
var juegoTerminado = false         # Flag para bloquear clicks post-victoria
var tamanoCelda = Vector2(100, 100) # Dimensiones de cada celda (calculado dinamicamente)
var posicionInicioTablero = Vector2.ZERO    # Posicion top-left del tablero
var posicionInicioRejilla = Vector2.ZERO    # Posicion top-left del area jugable
var indicadorRojo: Sprite2D        # Ficha lateral izquierda
var indicadorAmarillo: Sprite2D    # Ficha lateral derecha
var animacionIndicador: Tween      # Animacion de parpadeo
```

---

## Funciones Principales

### iniciarJuego()
Inicializa o reinicia el juego:
- Limpia la matriz `datosTablero` (llena de ceros)
- Elimina todas las fichas visuales del contenedor
- Resetea `jugadorActual` a 1 (rojo)
- Oculta el panel de fin de juego
- Actualiza el marcador de puntuacion
- Activa la animacion del indicador de turno

### _input(evento)
Maneja los clicks del mouse:
1. Verifica que el juego no haya terminado
2. Detecta clicks del boton izquierdo del mouse
3. Obtiene las coordenadas globales del mouse
4. Verifica si el click esta dentro de los limites de la rejilla
5. Calcula la columna clickeada dividiendo la posicion relativa por el ancho de celda
6. Llama a `soltarFicha(columna)` si la columna es valida

### soltarFicha(col)
Logica principal de colocacion de fichas:
1. Busca la fila mas baja disponible en la columna (de abajo hacia arriba)
2. Marca la celda en `datosTablero` con el jugador actual
3. Llama a `agregarFichaVisualAnimada()` con animacion
4. Espera a que termine la animacion (`await`)
5. Verifica si hay victoria con `verificarVictoria()`
6. Si hay victoria:
   - Detiene la animacion del indicador
   - Marca `juegoTerminado = true`
   - Resalta las fichas ganadoras
   - Espera 1.5 segundos
   - Muestra el panel de victoria
7. Si no hay victoria, verifica empate
8. Si tampoco hay empate, cambia de jugador (1 ↔ 2)

### verificarVictoria(fila, col)
Algoritmo de deteccion de 4 en linea:
1. Define 4 direcciones vectoriales:
   - (1, 0) → Horizontal
   - (0, 1) → Vertical  
   - (1, 1) → Diagonal descendente \
   - (1, -1) → Diagonal ascendente /
2. Para cada direccion:
   - Inicia con la ficha recien colocada
   - Cuenta fichas consecutivas hacia adelante (positivo)
   - Cuenta fichas consecutivas hacia atras (negativo)
   - Si encuentra 4+ fichas del mismo color, retorna las posiciones
3. Si ninguna direccion tiene 4+ fichas, retorna array vacio

### agregarFichaVisualAnimada(fila, col, jugador)
Crea y anima la caida de una ficha:
1. Crea un nuevo `Sprite2D`
2. Asigna la textura segun el jugador
3. Calcula la escala para que ocupe el 82% de la celda
4. Posiciona la ficha horizontalmente en el centro de la columna
5. Posiciona la ficha verticalmente 100px arriba del tablero
6. Añade la ficha al contenedor
7. Crea un `Tween` con transicion BOUNCE y ease OUT
8. Anima la caida hasta la posicion final en 0.3 segundos
9. Espera a que termine la animacion

### resaltarFichasGanadoras(posicionesGanadoras)
Anima las fichas ganadoras:
1. Recorre todos los hijos del contenedor de fichas
2. Calcula la fila y columna de cada ficha segun su posicion
3. Compara con las posiciones ganadoras
4. Para cada ficha ganadora:
   - Crea un `Tween` con 3 loops
   - Anima el `modulate` entre brillante (1.5, 1.5, 1.5) y normal (1.0, 1.0, 1.0)
   - Duracion de 0.25 segundos por ciclo

### crearIndicadoresDeTurno(tamanoPantalla, tamanoTablero)
Crea los indicadores laterales:
1. Calcula posiciones en los laterales (1/4 desde cada borde)
2. Crea `Sprite2D` con textura roja a la izquierda
3. Crea `Sprite2D` con textura amarilla a la derecha
4. Escala ambos al 20% del ancho del tablero
5. Posiciona verticalmente al centro de la pantalla
6. Añade ambos como hijos del nodo principal
7. Inicia la animacion de parpadeo

### actualizarIndicadorDeTurno()
Anima el indicador del jugador activo:
1. Detiene cualquier animacion anterior
2. Pone ambos indicadores semi-transparentes (opacidad 0.3)
3. Selecciona el indicador del jugador actual
4. Crea un `Tween` infinito (set_loops)
5. Anima entre brillante y normal cada 0.5 segundos

---

## Como Jugar

1. **Iniciar el Juego:** Click en el boton "JUGAR" en el menu principal
2. **Colocar Fichas:** Click en cualquier parte de una columna para soltar una ficha
3. **Objetivo:** Conectar 4 fichas del mismo color en linea (horizontal, vertical o diagonal)
4. **Indicadores de Turno:** Los indicadores laterales muestran de quien es el turno actual
   - Indicador rojo a la izquierda
   - Indicador amarillo a la derecha
   - El indicador activo parpadea con brillo
5. **Victoria:** Las 4 fichas ganadoras parpadean antes de mostrar el mensaje de victoria
6. **Siguiente Partida:** 
   - Click en "Jugar de nuevo" para otra partida
   - Click en "Menu Principal" para volver al menu
7. **Puntuacion:** El contador de victorias se mantiene entre partidas

---

## Detalles Tecnicos

### Sistema de Coordenadas
El juego usa un sistema de coordenadas adaptativo:
- El tablero se escala al 80% de la pantalla (manteniendo aspecto)
- Los margenes se escalan proporcionalmente
- Las celdas se calculan dividiendo el area util entre 7x7
- Los clicks se convierten de coordenadas globales a indices de columna/fila

### Animaciones
El juego usa el sistema `Tween` de Godot:
- **Caida de fichas:** `TRANS_BOUNCE` con `EASE_OUT` (0.3s)
- **Indicadores de turno:** Loop infinito alternando brillo (0.5s por ciclo)
- **Fichas ganadoras:** 3 loops de parpadeo brillante (0.25s por ciclo)

### Sistema de Puntuacion
- Se usa un Autoload (Singleton) llamado `GestorPuntuacion`
- Las variables persisten entre cambios de escena
- Se actualiza al ganar y se muestra en ambas escenas
- No se reinicia automaticamente (persistencia entre sesiones de juego)

### Responsividad
El juego se adapta a cualquier resolucion:
```gdscript
# Configuracion en project.godot
window/size/mode=2                  # Modo redimensionable
window/stretch/mode="canvas_items"  # Escalar todo el contenido
window/stretch/aspect="expand"      # Expandir sin distorsion
```

---

## Configuracion del Proyecto

### Display Settings (project.godot)
```ini
[display]
window/size/viewport_width=1152     # Ancho base de ventana
window/size/viewport_height=648     # Alto base de ventana
window/size/mode=2                  # Modo redimensionable
window/stretch/mode="canvas_items"  # Escalar contenido
window/stretch/aspect="expand"      # Expandir proporcionalmente
```

### Autoload Configuration
```ini
[autoload]
GestorPuntuacion="*res://ScoreManager.gd"
```

**Nota:** El asterisco (*) indica que el script se carga inmediatamente al iniciar el juego.

---

## Estructura de Datos

### Matriz del Tablero (datosTablero)
```gdscript
# Ejemplo de tablero con algunas fichas colocadas:
[
  [0, 0, 0, 0, 0, 0, 0],  # Fila 0 (superior)
  [0, 0, 0, 0, 0, 0, 0],  # Fila 1
  [0, 0, 0, 1, 0, 0, 0],  # Fila 2
  [0, 0, 2, 1, 0, 0, 0],  # Fila 3
  [0, 1, 2, 1, 0, 0, 0],  # Fila 4
  [2, 1, 2, 2, 0, 0, 0],  # Fila 5
  [1, 2, 1, 2, 0, 0, 0]   # Fila 6 (inferior)
]

# Donde:
# 0 = celda vacia
# 1 = ficha roja
# 2 = ficha amarilla
```

---

## Personalizacion

### Ajustar Margenes del Tablero
En la escena `MainScene.tscn`, selecciona el nodo raiz y modifica:
- `margenIzquierdo`: Ajusta desde la izquierda
- `margenDerecho`: Ajusta desde la derecha
- `margenSuperior`: Ajusta desde arriba
- `margenInferior`: Ajusta desde abajo

### Ajustar Posicion de Fichas
- `desplazamientoFichaX`: Mover fichas horizontalmente
- `desplazamientoFichaY`: Mover fichas verticalmente

### Cambiar Colores de Contorno
En los archivos `.tscn`, busca:
```gdscript
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
```
Modifica los valores RGB (0-1) para cambiar el color del contorno.

### Cambiar Grosor de Contorno
```gdscript
theme_override_constants/outline_size = 6
```
Aumenta o disminuye el numero para contornos mas gruesos o delgados.

---

## Instalacion y Ejecucion

1. **Descargar el proyecto** desde el repositorio
2. **Abrir Godot 4.5+**
3. **Importar el proyecto:**
   - Click en "Importar"
   - Navegar a la carpeta del proyecto
   - Seleccionar el archivo `project.godot`
4. **Ejecutar el juego:**
   - Presionar **F5** o click en el boton "Play"
   - Para ejecutar la escena actual: **F6**

---

## Requisitos del Sistema

- **Motor:** Godot 4.5 o superior
- **Sistema Operativo:** Windows, Linux, macOS
- **Memoria RAM:** 512 MB minimo
- **Espacio en Disco:** ~10 MB

---

## Creditos

- **Motor:** Godot Engine 4.5
- **Lenguaje:** GDScript
- **Genero:** Juego de Mesa / Puzzle
- **Tipo:** Juego Local Multijugador (2 jugadores)

---

## Licencia

Este proyecto es de codigo abierto y puede ser usado libremente con fines educativos.

---

## Notas de Desarrollo

### Convenciones de Codigo
- **Nombres de variables:** camelCase en español
- **Nombres de funciones:** camelCase en español
- **Constantes:** MAYUSCULAS
- **Comentarios:** En español
- **Indentacion:** Tabulaciones

### Archivos Importantes
- `main_scene.gd` - Logica principal del juego (311 lineas)
- `ScoreManager.gd` - Gestor de puntuacion global (9 lineas)
- `menu.gd` - Logica del menu (12 lineas)

### Proximas Mejoras Sugeridas
- [ ] Sonidos para colocacion de fichas
- [ ] Musica de fondo
- [ ] Animacion de entrada al menu
- [ ] Modo de juego contra IA
- [ ] Guardar puntuaciones en archivo
- [ ] Diferentes tamanos de tablero (6x6, 8x8)
- [ ] Temas visuales alternativos
- [ ] Efectos de particulas en victoria

