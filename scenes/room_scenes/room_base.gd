extends Node2D

var grid_position: Vector2i = Vector2i.ZERO

func configure_exits(has_up: bool, has_down: bool, has_left: bool, has_right: bool) -> void:
	_set_door("Door_N", has_up)
	_set_door("Door_S", has_down)
	_set_door("Door_W", has_left)
	_set_door("Door_E", has_right)

func _set_door(door_name: String, enabled: bool) -> void:
	var door := $Doors.get_node_or_null(door_name)
	if door == null:
		return

	door.visible = enabled

	var col := door.get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = !enabled
