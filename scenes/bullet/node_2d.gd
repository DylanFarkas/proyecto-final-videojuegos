extends Node2D

const SPEED := 300
var has_collided := false
var player : Node = null  # se asigna desde el arma

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	var shape_rid = PhysicsServer2D.circle_shape_create()
	var radius = 6
	PhysicsServer2D.shape_set_data(shape_rid, radius)
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape_rid = shape_rid
	query.collide_with_bodies = true
	query.collision_mask = 1
	query.transform = global_transform
	
	if player != null:
		query.exclude = [player]  # Ignora al Player
	
	var result = get_world_2d().direct_space_state.intersect_shape(query)
	
	if result.size() > 0 and not has_collided:
		has_collided = true
		var collider = result[0].collider
		print("Impacto con: ", collider.name)
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
