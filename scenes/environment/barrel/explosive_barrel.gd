extends StaticBody2D

@export var explosion_radius: float = 64.0
@export var explosion_damage: int = 4

@export var idle_texture: Texture2D
@export var damaged_texture: Texture2D
@export var explosion_texture: Texture2D
@export var explosion_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound   # <--- AUDIO

@export var explosion_scale := Vector2(0.09, 0.09)
var idle_scale := Vector2.ONE

var is_damaged := false
var exploding := false

func _ready() -> void:
	if idle_texture:
		sprite.texture = idle_texture
	idle_scale = sprite.scale
	add_to_group("barrel")


func take_damage(amount: int = 1) -> void:
	if exploding:
		return

	if not is_damaged:
		is_damaged = true
		# Primer golpe → textura dañada
		if damaged_texture:
			sprite.texture = damaged_texture
		return

	# Segundo golpe → explota
	_explode()


func _explode() -> void:
	exploding = true

	# Reproducir sonido de explosión
	if explosion_sound:
		explosion_sound.play()

	# Cambiar sprite a explosión
	if explosion_texture:
		sprite.texture = explosion_texture
		sprite.scale = explosion_scale

	_do_explosion_damage()

	await get_tree().create_timer(0.15).timeout
	queue_free()


func _do_explosion_damage() -> void:
	var space = get_world_2d().direct_space_state

	var shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, explosion_radius)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape_rid
	params.collide_with_bodies = true
	params.collision_mask = 0xFFFF
	params.transform = Transform2D(0.0, global_position)

	var results = space.intersect_shape(params)

	for hit in results:
		var body = hit.collider
		if body == self:
			continue

		if body.has_method("take_damage"):
			body.take_damage(explosion_damage)
