extends Node2D
class_name Bullet   

const SPEED := 300
var has_collided := false
var player: Node = null       

var damage: int = 1          

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	var shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, 6)
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape_rid = shape_rid
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFF
	query.transform = global_transform
	
	if player != null:
		query.exclude = [player]
	
	var result = get_world_2d().direct_space_state.intersect_shape(query)
	
	if result.size() > 0 and not has_collided:
		has_collided = true
		var collider = result[0].collider
		print("Impacto con: ", collider.name)

		if collider.has_method("take_damage"):
			collider.take_damage(damage)
		elif collider.is_in_group("enemy"):
			collider.queue_free()

		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
