extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var speed: float = 100.0
var last_direction: String = "down"

# -------- VIDA DEL PLAYER --------
var max_hp: int = 10        # 3 corazones → 6 HP (2 por corazón)
var current_hp: int = max_hp

var hud: Node = null

# -------- ARMAS (2 SLOTS) --------
var weapons: Array[Node] = [null, null]   # slot 0 y 1
var active_weapon_slot: int = 0          # índice del arma activa
var current_weapon: Node = null          # alias al arma activa

@export var damage_number_scene: PackedScene
var coins: int = 0

func _ready() -> void:
	add_to_group("player")

	# Buscar arma inicial en la escena (por ejemplo el nodo "Gun")
	for child in get_children():
		if child.name.begins_with("Gun"):
			weapons[0] = child
			current_weapon = child
			active_weapon_slot = 0
			break

	_set_weapons_active()
	_update_hud_weapons()


# La HUD la asigna Game.gd
func set_hud(h: Node) -> void:
	hud = h
	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)
	_update_hud_weapons()


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
	if current_hp <= 0:
		return

	current_hp -= amount
	if current_hp < 0:
		current_hp = 0

	if hud and hud.has_method("update_health"):
		hud.update_health(current_hp, max_hp)

	_flash_damage()
	_spawn_damage_number(amount)


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


# -------- INPUT GLOBAL (teclas especiales) --------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		take_damage(1)   # lo que ya tenías para probar daño

	# Cambiar de arma con Q (acción swap_weapon)
	if event.is_action_pressed("swap_weapon"):
		_swap_weapon()


# -------- LÓGICA DE ARMAS / INVENTARIO --------

func _swap_weapon() -> void:
	var other_slot := 1 - active_weapon_slot
	var other_weapon := weapons[other_slot]

	# Si no hay arma en el otro slot, no hace nada
	if other_weapon == null or not is_instance_valid(other_weapon):
		return

	active_weapon_slot = other_slot
	current_weapon = other_weapon
	_set_weapons_active()
	_update_hud_weapons()
	print("Cambiaste al arma del slot ", active_weapon_slot)


func _set_weapons_active() -> void:
	for i in range(2):
		var w = weapons[i]
		if w and is_instance_valid(w):
			var is_active := (i == active_weapon_slot)
			if w.has_method("set_active"):
				w.set_active(is_active)
			else:
				w.visible = is_active   # por si el arma no tiene set_active()


func pickup_weapon(weapon_scene: PackedScene, weapon_name: String) -> void:
	if weapon_scene == null:
		return

	var new_weapon: Node = weapon_scene.instantiate()
	add_child(new_weapon)

	# 1) Buscar un slot vacío primero
	for i in range(2):
		if weapons[i] == null or not is_instance_valid(weapons[i]):
			weapons[i] = new_weapon
			active_weapon_slot = i
			current_weapon = new_weapon
			_set_weapons_active()
			_update_hud_weapons()  # ← ESTA LÍNEA FALTABA
			print("Has obtenido el arma: %s (slot %d)" % [weapon_name, i])
			return

	# 2) Si los 2 slots están llenos → reemplazar la que está activa
	if weapons[active_weapon_slot] and is_instance_valid(weapons[active_weapon_slot]):
		weapons[active_weapon_slot].queue_free()

	weapons[active_weapon_slot] = new_weapon
	current_weapon = new_weapon
	_set_weapons_active()
	_update_hud_weapons()

	print("Inventario lleno: se reemplazó el arma del slot activo por ", weapon_name)
	
func _update_hud_weapons():
	if hud and hud.has_method("update_weapon_slots"):
		hud.update_weapon_slots(weapons, active_weapon_slot)
		
func _flash_damage() -> void:
	# hace un parpadeo blanco rápido
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.1)

func _spawn_damage_number(amount: int) -> void:
	if damage_number_scene == null:
		return

	var dmg := damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg)

	dmg.global_position = global_position + Vector2(0, -10)

	if dmg.has_method("show_value"):
		dmg.show_value(amount)

	dmg.scale = Vector2(0.6, 0.6)

func add_coins(amount: int) -> void:
	coins += amount
	print("Coins:", coins)

	# cuando el HUD tenga contador de monedas
	if hud and hud.has_method("update_coins"):
		hud.update_coins(coins)
