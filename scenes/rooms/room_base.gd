extends Node2D

var grid_position: Vector2i = Vector2i.ZERO

@onready var gates_tilemap: TileMapLayer = $TilemapLayers/Gates
@onready var open_sound: AudioStreamPlayer = $OpenSound
@onready var close_sound: AudioStreamPlayer = $CloseSound

# IDs de los tiles en el TileSet de Gates
@export var gate_open_source_id: int = 1        # valla.png  (abajo / abierta)
@export var gate_closed_source_id: int = 2      # valla-completa.png (arriba / cerrada)

# Qué lados TIENEN realmente salida (se llena en configure_exits)
var exit_up: bool = false
var exit_down: bool = false
var exit_left: bool = false
var exit_right: bool = false

# Listas de celdas de vallas por lado
var gate_cells_n: Array[Vector2i] = []
var gate_cells_s: Array[Vector2i] = []
var gate_cells_w: Array[Vector2i] = []
var gate_cells_e: Array[Vector2i] = []
var gates_initialized: bool = false


func configure_exits(has_up: bool, has_down: bool, has_left: bool, has_right: bool) -> void:
	# Guardamos qué lados tienen salida
	exit_up = has_up
	exit_down = has_down
	exit_left = has_left
	exit_right = has_right

	_set_door("Door_N", has_up)
	_set_door("Door_S", has_down)
	_set_door("Door_W", has_left)
	_set_door("Door_E", has_right)

	# Clasificar celdas de las vallas la primera vez
	_init_gate_cells()

	# Estado inicial: salidas abiertas, muros sin salida cerrados
	_update_gates_initial()


func _set_door(door_name: String, enabled: bool) -> void:
	var door := $Doors.get_node_or_null(door_name)
	if door == null:
		return

	door.visible = enabled

	var col := door.get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = !enabled


# ========================
#   VALLAS / GATES
# ========================

func _init_gate_cells() -> void:
	if gates_initialized or gates_tilemap == null:
		return

	var cells := gates_tilemap.get_used_cells()
	if cells.is_empty():
		gates_initialized = true
		return

	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_y = cells[0].y
	var max_y = cells[0].y

	# Primero obtenemos el rectángulo exterior de las vallas
	for c in cells:
		if c.x < min_x: min_x = c.x
		if c.x > max_x: max_x = c.x
		if c.y < min_y: min_y = c.y
		if c.y > max_y: max_y = c.y

	# Ahora clasificamos cada celda en N / S / E / W según su borde
	for c in cells:
		if c.y == min_y:
			gate_cells_n.append(c)
		elif c.y == max_y:
			gate_cells_s.append(c)
		elif c.x == min_x:
			gate_cells_w.append(c)
		elif c.x == max_x:
			gate_cells_e.append(c)

	gates_initialized = true


func _set_gate_state(cells: Array[Vector2i], closed: bool) -> void:
	if gates_tilemap == null:
		return

	var source_id = gate_closed_source_id if closed else gate_open_source_id

	for cell in cells:
		gates_tilemap.set_cell(cell, source_id, Vector2i(0, 0))



func _update_gates_initial() -> void:
	# Salidas verdaderas → abiertas
	# Lados sin salida → cerrados para siempre
	_set_gate_state(gate_cells_n, !exit_up)
	_set_gate_state(gate_cells_s, !exit_down)
	_set_gate_state(gate_cells_w, !exit_left)
	_set_gate_state(gate_cells_e, !exit_right)


func lock_doors() -> void:
	_init_gate_cells()

	# SOLO cerramos las vallas de lados que tienen salida
	if exit_up:
		_set_gate_state(gate_cells_n, true)
	if exit_down:
		_set_gate_state(gate_cells_s, true)
	if exit_left:
		_set_gate_state(gate_cells_w, true)
	if exit_right:
		_set_gate_state(gate_cells_e, true)
	
	if close_sound:
		close_sound.play()


func unlock_doors() -> void:
	_init_gate_cells()

	# SOLO abrimos las vallas de lados que tienen salida
	if exit_up:
		_set_gate_state(gate_cells_n, false)
	if exit_down:
		_set_gate_state(gate_cells_s, false)
	if exit_left:
		_set_gate_state(gate_cells_w, false)
	if exit_right:
		_set_gate_state(gate_cells_e, false)
		
	if open_sound:
		open_sound.play()
