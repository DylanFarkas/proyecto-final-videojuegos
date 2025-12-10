extends CharacterBody2D
class_name Enemy2

signal died

@export var speed := 60
@export var damage: int = 1                 # medio corazón
@export var attack_cooldown: float = 0.6    # tiempo entre golpes

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox       # OJO: mismo nombre que el nodo en la escena
@onready var attack_sound: AudioStreamPlayer = $Attacksound

@export var max_hp: int = 3
var hp: int

var player: Node2D = null
var last_player_pos: Vector2 = Vector2.ZERO
var can_damage: bool = true   

@export var damage_number_scene: PackedScene 
var flashing: bool = false

@export var coin_scene: PackedScene  
@export var min_coins: int = 1
@export var max_coins: int = 3

func _ready():
	hp = max_hp
	add_to_group("enemy")
	animated_sprite.play("attack")
	call_deferred("_find_player")

	# Conectar hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_HitBox_body_entered)
	else:
		print("⚠ Enemy sin HitBox asignado")


func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		last_player_pos = player.global_position
	else:
		await get_tree().create_timer(0.2).timeout
		_find_player()   # reintentar hasta encontrar


func _physics_process(delta):
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < 25:
		velocity = Vector2.ZERO
		animated_sprite.play("attack")
	else:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		
	var player_move := Vector2.ZERO
	if "velocity" in player:
		player_move = player.velocity
	else:
		player_move = player.global_position - last_player_pos

	var threshold := 0.1

	if player_move.x < -threshold:
		animated_sprite.play("attack-left")
	elif player_move.x > threshold:
		animated_sprite.play("attack-right")
	elif player_move.y < -threshold:
		animated_sprite.play("attack-up")
	elif player_move.y > threshold:
		animated_sprite.play("attack-down")

	last_player_pos = player.global_position


# ------------ DAÑO AL PLAYER ------------

func _on_HitBox_body_entered(body: Node2D) -> void:
	print("HitBox tocó a:", body.name)   # DEBUG, debe salir en la consola

	if not can_damage:
		return
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)   # 1 = medio corazón
	if attack_sound:
		attack_sound.play()
		can_damage = false
		_start_attack_cooldown()


func _start_attack_cooldown() -> void:
	await get_tree().create_timer(attack_cooldown).timeout
	can_damage = true


# ------------ VIDA DEL ENEMIGO ------------

func take_damage(amount: int = 1) -> void:
	hp -= amount
	
	_spawn_damage_number(amount)
	_hit_flash()
	
	if hp <= 0:
		die()

func die() -> void:
	# Soltar monedas
	_drop_coins()
	died.emit()
	queue_free()

# --- Número flotante ---

func _spawn_damage_number(amount: int) -> void:
	if damage_number_scene == null:
		return

	var dmg := damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg)

	dmg.global_position = global_position
	if dmg.has_method("show_value"):
		dmg.show_value(amount)

# --- Flash de daño ---

func _hit_flash() -> void:
	if flashing or animated_sprite == null:
		return

	flashing = true
	var original_modulate := animated_sprite.modulate

	# rojizo para indicar golpe
	animated_sprite.modulate = Color(1, 0.4, 0.4)

	await get_tree().create_timer(0.08).timeout

	animated_sprite.modulate = original_modulate
	flashing = false

func _drop_coins() -> void:
	if coin_scene == null:
		return

	var count := randi_range(min_coins, max_coins)

	for i in range(count):
		var coin := coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)

		# pequeña dispersión aleatoria alrededor del enemigo
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)

		coin.global_position = global_position + offset
