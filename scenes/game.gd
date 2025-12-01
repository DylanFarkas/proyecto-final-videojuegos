extends Node2D

@export var start_room_scene: PackedScene            # Room_Start.tscn
@export var vertical_corridor_scene: PackedScene     # pasillo_vertical.tscn
@export var horizontal_corridor_scene: PackedScene   # pasillo_horizontal.tscn
@export var room_scenes: Array[PackedScene] = []     # SOLO rooms: Room_1, Room_2, ...

@export var player_scene: PackedScene
@export var enemy_scene : PackedScene

@export var enemies_per_room: int = 4
@export var enemy_spawn_delay: float = 3.0   # segundos de retraso antes de spawnear

@export var max_rooms: int = 5
@export var room_size: Vector2 = Vector2(272, 272)   # 17 tiles * 16px

var rooms_with_enemies_spawned: Dictionary = {}  # Vector2i -> bool
var enemies_by_room: Dictionary = {}             # Vector2i -> Array[Node2D]

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

	var start_pos := Vector2i(0, 0)
	var start_room := _instance_room(start_room_scene, start_pos)
	grid[start_pos] = start_room

	var corridor_pos := start_pos + Vector2i(0, -1)
	var first_corridor := _instance_room(vertical_corridor_scene, corridor_pos)
	if first_corridor != null:
		grid[corridor_pos] = first_corridor

	var first_room_pos := corridor_pos + Vector2i(0, -1)
	var first_room_scene := _random_room_scene()
	var first_room := _instance_room(first_room_scene, first_room_pos)
	if first_room != null:
		grid[first_room_pos] = first_room
	else:
		return

	var frontier: Array[Vector2i] = [first_room_pos]
	var rooms_created := 2
	var safety := 0

	while rooms_created < max_rooms and safety < 300:
		safety += 1

		if frontier.is_empty():
			break

		var base_index := rng.randi_range(0, frontier.size() - 1)
		var base_pos: Vector2i = frontier[base_index]

		var dir := _random_direction()

		var corridor_candidate := base_pos + dir
		var room_candidate := base_pos + dir * 2
		if room_candidate.y > 0:
			continue

		if grid.has(corridor_candidate) or grid.has(room_candidate):
			continue

		var corridor_scene: PackedScene = vertical_corridor_scene
		if dir.x != 0:
			corridor_scene = horizontal_corridor_scene

		var corridor_inst := _instance_room(corridor_scene, corridor_candidate)
		if corridor_inst == null:
			continue
		grid[corridor_candidate] = corridor_inst

		var room_scene := _random_room_scene()
		var room_inst := _instance_room(room_scene, room_candidate)
		if room_inst == null:
			grid.erase(corridor_candidate)
			corridor_inst.queue_free()
			continue

		grid[room_candidate] = room_inst
		rooms_created += 1
		frontier.append(room_candidate)

	_configure_all_exits()

	print("Celdas en la grid (salas + pasillos): ", grid.size())


func _get_room_grid_pos(room: Node2D) -> Vector2i:
	for pos in grid.keys():
		if grid[pos] == room:
			return pos
	push_warning("Room no encontrada en grid, devolviendo (0, 0)")
	return Vector2i(0, 0)


func _should_spawn_enemies_here(room: Node2D, pos: Vector2i) -> bool:
	# No spawnear en pasillos (marcados con el grupo "corridor")
	if room.is_in_group("corridor"):
		return false

	# No spawnear en la sala inicial
	if pos == Vector2i(0, 0):
		return false

	# No repetir en salas visitadas
	if rooms_with_enemies_spawned.get(pos, false):
		return false

	return true


# ========================
#    ENTRAR POR PUERTAS
# ========================

func on_player_use_door(current_room: Node2D, direction: Vector2i, body: Node) -> void:
	if body != player:
		return

	var current_pos := _get_room_grid_pos(current_room)
	var target_pos := current_pos + direction

	if not grid.has(target_pos):
		print("No hay sala en dirección ", direction, " desde ", current_pos)
		return

	var target_room: Node2D = grid[target_pos]

	# Solo salas válidas y que aún no hayan sido usadas
	if _should_spawn_enemies_here(target_room, target_pos):
		# Marcamos de una vez que esta sala ya fue "procesada"
		rooms_with_enemies_spawned[target_pos] = true

		# Lanzamos la corrutina que espera a que el jugador cruce
		_lock_and_spawn_room(target_room, target_pos)

func _lock_and_spawn_room(target_room: Node2D, target_pos: Vector2i) -> void:
	# Pequeño delay para que el jugador termine de cruzar la puerta
	await get_tree().create_timer(1).timeout  # ajusta 0.25f si quieres más/menos tiempo

	if not is_instance_valid(target_room):
		return

	# Ahora sí, cerramos las puertas de esa sala
	if target_room.has_method("lock_doors"):
		target_room.lock_doors()

	# Y programamos el spawn de enemigos con el delay normal
	_spawn_enemies_after_delay(target_room, target_pos)


func _spawn_enemies_after_delay(room: Node2D, pos: Vector2i) -> void:
	# Esperar X segundos
	await get_tree().create_timer(enemy_spawn_delay).timeout

	# Por si la sala fue borrada o algo raro
	if not is_instance_valid(room):
		return

	# Spawnear enemigos en esa sala
	var spawned := spawn_enemies_in_room(room, pos, enemies_per_room)
	if spawned > 0:
		print("Spawneados ", spawned, " enemigos en sala ", pos)


# ========================
#          ENEMIGOS
# ========================

func _spawn_enemies_all_rooms():
	if enemy_scene == null:
		return

	var total_spawned := 0

	for pos in grid.keys():
		var cell = grid[pos]
		if cell == null:
			continue

		if "corridor" in cell.name.to_lower():
			continue

		if pos == Vector2i(0,0):  # sala inicial no
			continue

		var spawned = spawn_enemies_in_room(cell, pos, enemies_per_room)
		total_spawned += spawned


func spawn_enemies_in_room(room: Node2D, room_pos: Vector2i, amount: int) -> int:
	if enemy_scene == null:
		return 0

	var spawned := 0

	var margin := 16
	var min_x := margin
	var min_y := margin
	var max_x := room_size.x - margin
	var max_y := room_size.y - margin

	for i in range(amount):
		var enemy = enemy_scene.instantiate()
		if enemy == null:
			continue

		# MUY IMPORTANTE: agregarlo directamente al Game
		add_child(enemy)

		# posición local dentro de room convertida a global
		var lx = rng.randf_range(min_x, max_x)
		var ly = rng.randf_range(min_y, max_y)
		var global_pos := room.global_position + Vector2(lx, ly)

		enemy.global_position = global_pos

		# asegurar visibilidad
		if enemy is CanvasItem:
			enemy.z_index = 50

		_register_enemy(room_pos, enemy)
		spawned += 1

	return spawned


func _register_enemy(room_pos: Vector2i, enemy: Node2D) -> void:
	if not enemies_by_room.has(room_pos):
		enemies_by_room[room_pos] = []
	enemies_by_room[room_pos].append(enemy)

	# Conectar señal de muerte si existe
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died").bind(room_pos, enemy))


func _on_enemy_died(room_pos: Vector2i, enemy: Node2D) -> void:
	if not enemies_by_room.has(room_pos):
		return

	enemies_by_room[room_pos].erase(enemy)

	if enemies_by_room[room_pos].is_empty():
		var room: Node2D = grid.get(room_pos, null)
		if room and room.has_method("unlock_doors"):
			room.unlock_doors()
		print("Sala ", room_pos, " limpia. Puertas abiertas.")


func debug_list_enemies_after_spawn():
	print("---- DEBUG ENEMIES ----")
	var count := 0
	for c in get_children():
		if c == null:
			continue
		var n := c.name.to_lower()
		if "enemy" in n or c is CharacterBody2D:
			print("Enemy:", c, " pos:", c.global_position)
			count += 1
	print("Total enemigos detectados:", count)


# ========================
# CONFIGURACIÓN DE SALAS
# ========================

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
#         PLAYER
# ========================

func spawn_player() -> void:
	if player_scene == null:
		push_error("player_scene no está asignado.")
		return

	player = player_scene.instantiate()
	add_child(player)

	var start_room: Node2D = grid.get(Vector2i(0, 0), null)
	if start_room == null:
		push_error("No se encontró la sala de inicio en la grid.")
		return

	var spawn := start_room.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.global_position = start_room.global_position + room_size * 0.5
