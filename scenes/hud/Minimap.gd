# Minimap.gd
extends Control
class_name Minimap


@export var cell_size: int = 8
@export var padding: int = 2
@export var visited_color: Color = Color(0.8, 0.8, 0.8, 0.9)
@export var current_color: Color = Color(1, 1, 0.3, 1.0)
@export var frontier_color: Color = Color(0.4, 0.4, 0.4, 0.7)
@export var background_color: Color = Color(0, 0, 0, 0.5)
@export var border_color: Color = Color(1, 1, 1, 0.3)

var grid: Dictionary = {}      # Vector2i -> bool (existe sala/pasillo)
var visited: Dictionary = {}   # Vector2i -> bool
var current_room: Vector2i = Vector2i.ZERO

var min_pos: Vector2i = Vector2i.ZERO
var max_pos: Vector2i = Vector2i.ZERO

func build_from_grid(game_grid: Dictionary, start_pos: Vector2i) -> void:
	grid.clear()
	visited.clear()

	# Copiamos SOLO salas (puedes filtrar pasillos si quieres)
	for pos in game_grid.keys():
		var room: Node2D = game_grid[pos]
		# Ejemplo: saltar pasillos si los marcas con grupo "corridor"
		# if room.is_in_group("corridor"):
		#     continue
		grid[pos] = true

	current_room = start_pos
	_compute_bounds()
	_mark_visited(start_pos)
	queue_redraw()


func _compute_bounds() -> void:
	if grid.is_empty():
		min_pos = Vector2i.ZERO
		max_pos = Vector2i.ZERO
		return

	var keys: Array = grid.keys()
	min_pos = keys[0]
	max_pos = keys[0]

	for pos in keys:
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var w := (max_pos.x - min_pos.x + 1) * cell_size + padding * 2
	var h := (max_pos.y - min_pos.y + 1) * cell_size + padding * 2 

	custom_minimum_size = Vector2(w, h)
	size = custom_minimum_size
	
func _mark_visited(pos: Vector2i) -> void:
	visited[pos] = true


func set_current_room(pos: Vector2i) -> void:
	current_room = pos
	_mark_visited(pos)
	queue_redraw()


func _room_to_minimap(pos: Vector2i) -> Vector2:
	var x := padding + (pos.x - min_pos.x) * cell_size
	var y := padding + (pos.y - min_pos.y) * cell_size
	return Vector2(x, y)



func _is_adjacent_to_visited(pos: Vector2i) -> bool:
	var dirs := [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	for d in dirs:
		if visited.get(pos + d, false):
			return true
	return false


func _draw() -> void:
	if grid.is_empty():
		return

	# Fondo
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, background_color, true)
	# Borde fino
	draw_rect(bg_rect, border_color, false, 1.0)

	# Luego las salas
	for pos in grid.keys():
		var rect := Rect2(_room_to_minimap(pos), Vector2(cell_size, cell_size))

		if pos == current_room:
			draw_rect(rect, current_color, true)
		elif visited.get(pos, false):
			draw_rect(rect, visited_color, true)
		elif _is_adjacent_to_visited(pos):
			draw_rect(rect, frontier_color, false)
