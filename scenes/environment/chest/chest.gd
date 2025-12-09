extends Area2D

@export var weapon_name: String = "Pistola básica"
@export var weapon_scene: PackedScene
@export var closed_texture: Texture2D
@export var open_texture: Texture2D

var is_open := false
var player_in_range: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

signal weapon_taken(weapon_name: String)

func _ready() -> void:
	# Asegurar que el área detecte cuerpos
	monitoring = true
	monitorable = true

	if closed_texture:
		sprite.texture = closed_texture

	label.visible = false

	# Nos conectamos a las señales por código (por si en el editor se olvidó)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

	print("Chest listo: ", name)


func _process(_delta: float) -> void:
	if player_in_range and not is_open and Input.is_action_just_pressed("interact"):
		print("Tecla E detectada cerca del cofre")
		_open_chest()


func _on_body_entered(body: Node) -> void:
	print("body_entered: ", body.name)
	if body.is_in_group("player") and not is_open:
		player_in_range = body
		label.text = "[E] Tomar: " + weapon_name
		label.visible = true


func _on_body_exited(body: Node) -> void:
	print("body_exited: ", body.name)
	if body == player_in_range:
		player_in_range = null
		label.visible = false


func _open_chest() -> void:
	is_open = true
	label.visible = false

	if open_texture:
		sprite.texture = open_texture

	if player_in_range and weapon_scene and player_in_range.has_method("pickup_weapon"):
		player_in_range.pickup_weapon(weapon_scene, weapon_name)

	emit_signal("weapon_taken", weapon_name)
