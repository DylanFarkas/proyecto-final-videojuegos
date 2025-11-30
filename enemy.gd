extends CharacterBody2D
class_name Enemy

@export var speed := 60
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var last_player_pos: Vector2 = Vector2.ZERO

func _ready():
	animated_sprite.play("attack")             # animación por defecto
	call_deferred("_find_player")              # busco player luego

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

	# (--- comportamiento de persecución ---)
	var dist = global_position.distance_to(player.global_position)
	if dist < 25:
		velocity = Vector2.ZERO
		animated_sprite.play("attack")
	else:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		
	var player_move := Vector2.ZERO
	if "velocity" in player:   # si el player expone velocity (CharacterBody2D)
		player_move = player.velocity
	else:
		# fallback: usar diferencia de posición (no divide por delta porque basta comparar signo)
		player_move = player.global_position - last_player_pos

	# Umbral para evitar jitter cuando está prácticamente quieto
	var threshold := 0.1

	# Si el player se mueve hacia la izquierda, cambiamos animación a la versión izquierda.
	if player_move.x < -threshold:
		# nombres de animación esperados: "attack-left", "attack-right", "attack-up", "attack-down"
		animated_sprite.play("attack-left")
	elif player_move.x > threshold:
		animated_sprite.play("attack-right")
	elif player_move.y < -threshold:
		animated_sprite.play("attack-up")
	elif player_move.y > threshold:
		animated_sprite.play("attack-down")

	last_player_pos = player.global_position
