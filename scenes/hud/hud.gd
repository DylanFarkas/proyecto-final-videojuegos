extends CanvasLayer

@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D

var hearts_count: int = 0

@onready var hearts_container := $MarginContainer/HBoxRoot/HeartsContainer
@onready var minimap: Minimap = $Minimap

# Nuevos paths (ojo con la ruta)
@onready var frame0: TextureRect = $WeaponHUD/WeaponContainer/Frame0
@onready var frame1: TextureRect = $WeaponHUD/WeaponContainer/Frame1
@onready var slot0: TextureRect = $WeaponHUD/WeaponContainer/Frame0/WeaponSlot0
@onready var slot1: TextureRect = $WeaponHUD/WeaponContainer/Frame1/WeaponSlot1

# -----------------------------------
#   MINIMAPA + CORAZONES (igual)
# -----------------------------------
func init_minimap(grid: Dictionary, start_pos: Vector2i) -> void:
	if minimap:
		minimap.build_from_grid(grid, start_pos)

func update_current_room(room_pos: Vector2i) -> void:
	if minimap:
		minimap.set_current_room(room_pos)

func setup(max_hp: int) -> void:
	hearts_count = int(ceil(max_hp / 2.0))
	_create_hearts()
	update_health(max_hp, max_hp)

var hearts: Array[TextureRect] = []

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
		heart.texture = heart_full
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(20, 20)
		hearts_container.add_child(heart)
		hearts.append(heart)

# -----------------------------------wwwww
#          HUD DE ARMAS
# -----------------------------------

@export var weapon_icons := {
	"Gun": preload("res://assets/sprites/level/Guns/Armas.png"),
	"Gun2": preload("res://assets/sprites/level/Guns/arma lacer.png"),
	
}

func update_weapon_slots(weapons: Array, active_slot: int) -> void:
	# slot 0
	if weapons[0] != null:
		slot0.texture = weapon_icons.get(weapons[0].name, null)
	else:
		slot0.texture = null

	# slot 1
	if weapons[1] != null:
		slot1.texture = weapon_icons.get(weapons[1].name, null)
	else:
		slot1.texture = null

	# Resaltar marco activo
	frame0.modulate = Color.WHITE if active_slot == 0 else Color(0.6, 0.6, 0.6)
	frame1.modulate = Color.WHITE if active_slot == 1 else Color(0.6, 0.6, 0.6)
