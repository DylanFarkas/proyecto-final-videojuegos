extends Area2D

@export var damage: int = 1
@export var cooldown_time: float = 1.0

@onready var anims := [
	$SpikeTL,
	$SpikeTR,
	$SpikeBL,
	$SpikeBR
]

var player_inside: Node = null
var on_cooldown := false

func _ready():
	monitoring = true
	monitorable = true
	_play("idle")

func _process(_delta):
	if player_inside and not on_cooldown:
		_activate_spikes()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = body

func _on_body_exited(body):
	if body == player_inside:
		player_inside = null

func _activate_spikes():
	on_cooldown = true
	_play("up")

	if player_inside and player_inside.has_method("take_damage"):
		player_inside.take_damage(damage)

	await get_tree().create_timer(0.3).timeout
	_play("idle")

	await get_tree().create_timer(cooldown_time).timeout
	on_cooldown = false

func _play(animation_name: String):
	for anim in anims:
		anim.play(animation_name)
