extends CanvasLayer

@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D

var hearts_count: int = 0

@onready var hearts_container := $MarginContainer/HBoxContainer
@onready var hearts: Array[TextureRect] = []


func setup(max_hp: int) -> void:
	# Cada corazón = 2 HP
	hearts_count = int(ceil(max_hp / 2.0))
	_create_hearts()
	update_health(max_hp, max_hp)


func update_health(current_hp: int, max_hp: int) -> void:
	if hearts_count == 0:
		setup(max_hp)

	current_hp = clamp(current_hp, 0, max_hp)

	for i in range(hearts_count):
		var heart_hp_start: int = i * 2
		var heart_value: int = clamp(current_hp - heart_hp_start, 0, 2)

		if heart_value >= 2:
			hearts[i].texture = heart_full
		elif heart_value == 1:
			hearts[i].texture = heart_half
		else:
			hearts[i].texture = heart_empty


func _create_hearts() -> void:
	hearts.clear()

	for c in hearts_container.get_children():
		c.queue_free()

	for i in range(hearts_count):
		var heart := TextureRect.new()

		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture = heart_full
		heart.custom_minimum_size = Vector2(20, 20) 

		hearts_container.add_child(heart)
		hearts.append(heart)
