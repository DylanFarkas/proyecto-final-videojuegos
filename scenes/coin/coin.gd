extends Area2D

@export var value: int = 1

@onready var coin_sound: AudioStreamPlayer = $CoinSound

func _ready() -> void:
	monitoring = true
	monitorable = true

	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("add_coins"):
			body.add_coins(value)

		if coin_sound:
			coin_sound.play()
			# dejar que el sonido termine si quieres
			await get_tree().create_timer(0.1).timeout

		queue_free()
