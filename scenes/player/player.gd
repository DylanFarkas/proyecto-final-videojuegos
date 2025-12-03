extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var speed: float = 100.0
var last_direction: String = "down"

# -------- VIDA DEL PLAYER --------
var max_hp: int = 10        # 3 corazones → 6 HP (2 por corazón)
var current_hp: int = max_hp

var hud: Node = null


func _ready() -> void:
	add_to_group("player")


# La HUD la asigna Game.gd
func set_hud(h: Node) -> void:
	hud = h
	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()


func get_input() -> void:
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	
	if abs(input_direction.x) > abs(input_direction.y):
		if input_direction.x > 0:
			last_direction = "right"
		else:
			last_direction = "left"
	else:
		if input_direction.y > 0:
			last_direction = "down"
		else:
			last_direction = "up"
	
	update_animation("run")
	velocity = input_direction * speed


func update_animation(state: String) -> void:
	animated_sprite.play(state + "_" + last_direction)


# -------- DAÑO / VIDA --------

func take_damage(amount: int = 1) -> void:
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0

	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)

	if current_hp <= 0:
		die()


func heal(amount: int = 1) -> void:
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp

	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)


func die() -> void:
	print("Player murió")
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		take_damage(1)   
