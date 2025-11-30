extends Node2D

@export var start_room_scene: PackedScene            # Room_Start.tscn
@export var vertical_corridor_scene: PackedScene     # pasillo_vertical.tscn
@export var horizontal_corridor_scene: PackedScene   # pasillo_horizontal.tscn
@export var room_scenes: Array[PackedScene] = []     # SOLO rooms: Room_1, Room_2, ...

@export var player_scene: PackedScene

@export var max_rooms: int = 8
@export var room_size: Vector2 = Vector2(272, 272)   # 17 tiles * 16px


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

	# 2) Pasillo fijo arriba de la sala de inicio → (0, -1)
	var corridor_pos := start_pos + Vector2i(0, -1)
	var first_corridor := _instance_room(vertical_corridor_scene, corridor_pos)
	if first_corridor != null:
		grid[corridor_pos] = first_corridor

	# 3) Primera sala "real" arriba del pasillo → (0, -2)
	var first_room_pos := corridor_pos + Vector2i(0, -1)
	var first_room_scene := _random_room_scene()
	var first_room := _instance_room(first_room_scene, first_room_pos)
	if first_room != null:
		grid[first_room_pos] = first_room
	else:
		return  # sin primera sala no hay nada más que hacer

	# Lista de salas desde las que podemos seguir ramificando
	var frontier: Array[Vector2i] = [first_room_pos]
	var rooms_created := 2  # start + first_room
	var safety := 0

	# 4) Generar más salas, siempre sala - pasillo - sala
	while rooms_created < max_rooms and safety < 300:
		safety += 1

		if frontier.is_empty():
			break

		# Elegimos una sala aleatoria de la frontera
		var base_index := rng.randi_range(0, frontier.size() - 1)
		var base_pos: Vector2i = frontier[base_index]

		var dir := _random_direction()

		# No generamos por debajo de la sala inicial (y > 0)
		var corridor_candidate := base_pos + dir
		var room_candidate := base_pos + dir * 2
		if room_candidate.y > 0:
			continue

		# Si hay algo en medio o en el destino, no usamos esa dirección
		if grid.has(corridor_candidate) or grid.has(room_candidate):
			continue

		# Elegir pasillo vertical u horizontal
		var corridor_scene: PackedScene = vertical_corridor_scene
		if dir.x != 0:
			corridor_scene = horizontal_corridor_scene

		# Instanciar pasillo
		var corridor_inst := _instance_room(corridor_scene, corridor_candidate)
		if corridor_inst == null:
			continue
		grid[corridor_candidate] = corridor_inst

		# Instanciar nueva sala
		var room_scene := _random_room_scene()
		var room_inst := _instance_room(room_scene, room_candidate)
		if room_inst == null:
			# limpiamos el pasillo que no lleva a ningún lado
			grid.erase(corridor_candidate)
			corridor_inst.queue_free()
			continue

		grid[room_candidate] = room_inst

		# Actualizamos contador y frontera
		rooms_created += 1
		frontier.append(room_candidate)

	_configure_all_exits()
	print("Celdas en la grid (salas + pasillos): ", grid.size())


func _instance_room(scene: PackedScene, grid_pos: Vector2i) -> Node2D:
	if scene == null:
		push_error("Scene es NULL en grid_pos %s. Revisa las export variables." % grid_pos)
		return null

	var room := scene.instantiate()
	add_child(room)

	room.position = Vector2(grid_pos) * room_size
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
		if room == null:
			continue

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
