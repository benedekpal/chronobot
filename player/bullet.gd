extends AnimatedSprite2D

var bullet_impact_effect = preload("res://player/bullet_impact_effect.tscn")

var speed : int = 600
var dir : Vector2
var damage_amount : int = 1


func _physics_process(delta: float) -> void:
	move_local_x(dir[0] * speed * delta)
	move_local_y(dir[1] * speed * delta)

func _on_timer_timeout() -> void:
	queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	bullet_impact()
	


func _on_hitbox_area_entered(area: Area2D) -> void:
	bullet_impact()


func get_damage_amount() -> int:
	return damage_amount


func bullet_impact():
	var bullet_impact_effect_instance = bullet_impact_effect.instantiate() as Node2D
	bullet_impact_effect_instance.global_position = global_position
	get_parent().add_child(bullet_impact_effect_instance)
	queue_free()
