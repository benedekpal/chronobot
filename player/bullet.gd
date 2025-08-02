extends AnimatedSprite2D

var speed : int = 600
var dir : Vector2
var up : int

func _physics_process(delta: float) -> void:
	move_local_x(dir[0] * speed * delta)
	move_local_y(dir[1] * speed * delta)

func _on_timer_timeout() -> void:
	queue_free()
