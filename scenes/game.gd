extends Node2D

# --- ESCENAS A CONFIGURAR DESDE EL INSPECTOR ---

@export var start_room_scene: PackedScene          # Room_Start.tscn
@export var vertical_corridor_scene: PackedScene   # pasillo_vertical.tscn
@export var room_scenes: Array[PackedScene] = []   # Room_1, Room_2, pasillos, etc.
@export var player_scene: PackedScene              # player.tscn

@export var max_rooms: int = 8                     # salas totales (contando start y pasillo)
@export var room_size: Vector2 = Vector2(512, 512) # tamaño de cada "casilla" en píxeles

# --- ESTADO INTERNO ---

var rng := RandomNumberGenerator.new()
var grid: Dictionary = {}    # Vector2i -> Node2D (instancia de sala)
var player: Node2D = null

func _ready() -> void:
	rng.randomize()
	generate_dungeon()
	spawn_player()


# ========================
#   GENERACIÓN DEL MAPA
# ========================

func generate_dungeon() -> void:
	grid.clear()

	# 1) Sala de inicio en (0, 0)
	var start_pos := Vector2i(0, 0)
	var start_room := _instance_room(start_room_scene, start_pos)
	grid[start_pos] = start_room

	# 2) Pasillo vertical arriba de la sala de inicio → (0, -1)
	var corridor_pos := start_pos + Vector2i(0, -1)
	var corridor := _instance_room(vertical_corridor_scene, corridor_pos)
	grid[corridor_pos] = corridor

	# 3) Primera sala "real" arriba del pasillo → (0, -2)
	var first_room_pos := corridor_pos + Vector2i(0, -1)
	var first_room_scene := _random_room_scene()
	var first_room := _instance_room(first_room_scene, first_room_pos)
	grid[first_room_pos] = first_room

	# A partir de aquí seguimos generando a partir de esa primera sala
	var current_pos := first_room_pos

	# Ya hemos colocado 3 piezas (start, pasillo, first_room)
	var remaining := max_rooms - 3
	for i in range(remaining):
		var dir := _random_direction()
		var next_pos := current_pos + dir

		# si ya hay algo en esa casilla, saltamos
		if grid.has(next_pos):
			continue

		var scene := _random_room_scene()
		var room := _instance_room(scene, next_pos)
		grid[next_pos] = room
		current_pos = next_pos

	# 4) Configurar qué puertas se abren según vecinos
	_configure_all_exits()
	print("Salas generadas: ", grid.size())


func _instance_room(scene: PackedScene, grid_pos: Vector2i) -> Node2D:
	if scene == null:
		push_error("Scene es NULL en grid_pos %s. Revisa las export variables." % grid_pos)
		return null

	var room := scene.instantiate()
	add_child(room)

	# posición en el mundo
	room.position = Vector2(grid_pos) * room_size

	# OJO: por ahora NO tocamos grid_position
	# room.grid_position = grid_pos  # <-- QUÍTALO / COMÉNTALO

	return room




func _random_room_scene() -> PackedScene:
	if room_scenes.is_empty():
		push_warning("room_scenes está vacío, revisa el inspector.")
		return start_room_scene
	var idx := rng.randi_range(0, room_scenes.size() - 1)
	return room_scenes[idx]


func _random_direction() -> Vector2i:
	var dirs := [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	return dirs[rng.randi_range(0, dirs.size() - 1)]


func _configure_all_exits() -> void:
	for pos in grid.keys():
		var room = grid[pos]

		var up    := grid.has(pos + Vector2i(0, -1))
		var down  := grid.has(pos + Vector2i(0,  1))
		var left  := grid.has(pos + Vector2i(-1, 0))
		var right := grid.has(pos + Vector2i(1,  0))

		if room.has_method("configure_exits"):
			room.configure_exits(up, down, left, right)


# ========================
#   PLAYER
# ========================

func spawn_player() -> void:
	if player_scene == null:
		push_error("player_scene no está asignado.")
		return

	player = player_scene.instantiate()
	add_child(player)

	# Buscar la sala de inicio en (0,0)
	var start_room: Node2D = grid.get(Vector2i(0, 0), null)
	if start_room == null:
		push_error("No se encontró la sala de inicio en la grid.")
		return

	var spawn := start_room.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.position = start_room.position
