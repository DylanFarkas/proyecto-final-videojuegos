extends Node2D

const BULLET = preload("res://scenes/bullet/node_2d.tscn")
@onready var muzzle: Marker2D = $Marker2D
@onready var player = get_parent()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var shoot_cooldown := 0.2  # tiempo mínimo entre disparos continuos
var shoot_timer := 0.0

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	# Rotación y volteo
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	scale.y = -1 if rotation_degrees > 90 and rotation_degrees < 270 else 1

	# Disparo inmediato al primer clic
	if Input.is_action_just_pressed("shoot"):
		shoot_bullet()
	
	# Disparo continuo mientras se mantiene presionado
	if Input.is_action_pressed("shoot"):
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_bullet()
			shoot_timer = shoot_cooldown
		# Reproducir animación de disparo
		if animated_sprite.animation != "Amar":
			animated_sprite.play("Amar")
	else:
		# Volver a idle cuando no se presiona
		if animated_sprite.animation != "Idle_arma":
			animated_sprite.play("Idle_arma")
		shoot_timer = 0.0  # resetear timer

# Función para instanciar la bala
func shoot_bullet():
	var bullet_instance = BULLET.instantiate()
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = rotation
	bullet_instance.player = player
	get_tree().root.add_child(bullet_instance)
