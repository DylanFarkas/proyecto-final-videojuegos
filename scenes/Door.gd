extends Area2D

@export var direction: Vector2i = Vector2i.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body or body.name != "Player":
		return

	# Room es el abuelo: Room -> Doors -> Door_X
	var room := get_parent().get_parent() as Node2D

	var game := get_tree().current_scene
	if game and game.has_method("on_player_use_door"):
		game.on_player_use_door(room, direction, body)
