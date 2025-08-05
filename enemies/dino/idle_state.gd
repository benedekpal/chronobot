extends NodeState

@export var character_body_2d : CharacterBody2D
@export var animated_sprite_2d : AnimatedSprite2D

# Movement parameters
# todo move to the dino enemy class somewhere else
@export var speed = 200.0
@export var acceleration = 10.0
@export var friction = 8.0

var MovementHelper = preload("res://scripts/utility/movement_helper.gd").new()

func on_process(delta: float):
	pass


func on_physics_process(delta: float):
	var velocity = character_body_2d.velocity
	var move_direction = 0
	# Apply movement using predefined direction
	velocity = MovementHelper.handle_acceleration(velocity, move_direction, delta, speed, acceleration)
	velocity = MovementHelper.apply_friction(velocity, move_direction, delta, friction)

	character_body_2d.velocity = velocity
	character_body_2d.move_and_slide()

	animated_sprite_2d.play("idle")


func enter():
	pass


func exit():
	pass
