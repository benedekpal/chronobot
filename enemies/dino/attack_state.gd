extends NodeState

@export var character_body_2d : CharacterBody2D
@export var animated_sprite_2d : AnimatedSprite2D

@export var speed : int = 800
@export var max_speed : int
@export var acceleration = 10.0
@export var friction = 8.0

var MovementHelper = preload("res://scripts/utility/movement_helper.gd").new()

var player : CharacterBody2D

func on_process(delta: float):
	pass

func on_physics_process(delta: float):
	var direction : int
	
	if character_body_2d.global_position > player.global_position:
		animated_sprite_2d.flip_h = false
		direction = -1
	elif character_body_2d.global_position < player.global_position:
		animated_sprite_2d.flip_h = true
		direction = 1
	
	animated_sprite_2d.play("attack")
	
	#character_body_2d.velocity.x += direction * speed * delta
	#character_body_2d.velocity.x = clamp(character_body_2d.velocity.x, -speed, speed)
	
	character_body_2d.velocity = MovementHelper.handle_acceleration(character_body_2d.velocity, direction, delta, max_speed, acceleration)
	character_body_2d.velocity = MovementHelper.apply_friction(character_body_2d.velocity, direction, delta, friction)

	character_body_2d.move_and_slide()

func enter():
	player = get_tree().get_nodes_in_group("Player")[0] as CharacterBody2D
	max_speed = speed + 100
	pass

func exit():
	pass
