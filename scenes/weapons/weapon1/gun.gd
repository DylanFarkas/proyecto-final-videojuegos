extends Node2D

const BULLET = preload("res://scenes/weapons/weapon1/node_2d.tscn")
@onready var muzzle: Marker2D = $Marker2D
@onready var player = get_parent()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound

@export var bullet_damage: int = 1   # 🔹 daño del arma

var shoot_cooldown := 0.2
var shoot_timer := 0.0
var active: bool = true

func set_active(value: bool) -> void:
	active = value
	visible = value

func _process(delta: float) -> void:
	if not active:
		return

	look_at(get_global_mouse_position())
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	scale.y = -1 if rotation_degrees > 90 and rotation_degrees < 270 else 1

	shoot_timer -= delta

	if Input.is_action_just_pressed("shoot"):
		shoot_bullet()
		shoot_timer = shoot_cooldown
	elif Input.is_action_pressed("shoot"):
		if shoot_timer <= 0.0:
			shoot_bullet()
			shoot_timer = shoot_cooldown

		if animated_sprite.animation != "Amar":
			animated_sprite.play("Amar")
	else:
		if animated_sprite.animation != "Idle_arma":
			animated_sprite.play("Idle_arma")
		shoot_timer = 0.0


func shoot_bullet():
	var bullet_instance = BULLET.instantiate()

	# Posición / rotación
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = rotation
	bullet_instance.player = player

	# 🔹 Pasar daño del arma a la bala
	bullet_instance.damage = bullet_damage


	get_tree().root.add_child(bullet_instance)
	shoot_sound.play()
