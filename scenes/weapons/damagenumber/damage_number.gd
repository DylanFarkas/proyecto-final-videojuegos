extends Node2D

@export var float_speed: float = 30.0
@export var duration: float = 0.6

@onready var label: Label = $Label

var elapsed: float = 0.0

func _ready():
	scale = Vector2(0.7, 0.7)

func show_value(amount: int) -> void:
	label.text = str(amount)

func _process(delta: float) -> void:
	position.y -= float_speed * delta

	elapsed += delta
	var t := elapsed / duration
	modulate.a = lerp(1.0, 0.0, t)

	if elapsed >= duration:
		queue_free()
