extends Node2D

var grid_position: Vector2i = Vector2i.ZERO

@onready var gates_tilemap: TileMapLayer = $TilemapLayers/Gates

# IDs de los tiles en el TileSet de Gates
# AJUSTA ESTOS EN EL INSPECTOR
@export var gate_open_source_id: int = 1        # valla.png  (abajo / abierta)
@export var gate_closed_source_id: int = 2      # valla-completa.png (arriba / cerrada)


func configure_exits(has_up: bool, has_down: bool, has_left: bool, has_right: bool) -> void:
	_set_door("Door_N", has_up)
	_set_door("Door_S", has_down)
	_set_door("Door_W", has_left)
	_set_door("Door_E", has_right)
	# Las vallas ya están pintadas abiertas en el TileMap.
	# Aquí NO tocamos Gates, solo puertas.


func _set_door(door_name: String, enabled: bool) -> void:
	var door := $Doors.get_node_or_null(door_name)
	if door == null:
		return

	door.visible = enabled

	var col := door.get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = !enabled


# ===== API para Game.gd =====

func lock_doors() -> void:
	if gates_tilemap == null:
		return

	for cell in gates_tilemap.get_used_cells():
		# Cambiar todas las vallas a "cerradas"
		gates_tilemap.set_cell(cell, gate_closed_source_id, Vector2i(0, 0))


func unlock_doors() -> void:
	if gates_tilemap == null:
		return

	for cell in gates_tilemap.get_used_cells():
		# Volver todas las vallas a "abiertas"
		gates_tilemap.set_cell(cell, gate_open_source_id, Vector2i(0, 0))
