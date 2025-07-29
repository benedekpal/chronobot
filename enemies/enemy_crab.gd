extends CharacterBody2D

@export var patrol_points : Node

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const GRAVITY = 1000
@export var speed : int = 25

enum State { Idle, Walk, Falling }

var current_state : State
var was_on_floor = true
var direction : Vector2 = Vector2.LEFT
var number_of_points : int
var point_positions : Array[Vector2]
var current_point : Vector2
var current_point_position : int #set to 0 by default


func _ready():
	if patrol_points == null:
		push_error("patrol_points is null! Make sure it is assigned before running.")
		# Optionally, you can stop further execution or set a default:
		return
		
	number_of_points = patrol_points.get_children().size()	
		
	if number_of_points != 2:
		push_error("2 patrol_point is required! Make sure it is assigned before running.")
		# Optionally, you can stop further execution or set a default:
		return
	
	for point in patrol_points.get_children():
		point_positions.append(point.global_position)
	current_point = point_positions[current_point_position]
	
	current_state = State.Idle

func _physics_process(delta: float):
	crab_falling(delta)
	crab_state_handler()
	move_and_slide()
	crab_animations()


func crab_state_handler():
	if !is_on_floor():
		current_state = State.Falling
	elif is_on_floor() and !was_on_floor:
		# Just landed
		current_state = State.Walk

	if current_state == State.Walk and is_on_floor():
		crab_walk()

	was_on_floor = is_on_floor()


func crab_falling(delta : float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func crab_walk():
	# Move left continuously
	if abs(position.x - current_point.x) > 0.5:
		velocity.x = direction.x * speed
	else:
		current_point_position = current_point_position ^ 1
		
	current_point = point_positions[current_point_position]
	
	if current_point.x > position.x:
		direction = Vector2.RIGHT
	else:
		direction = Vector2.LEFT
	
	animated_sprite_2d.flip_h = (direction == Vector2.RIGHT)


func crab_animations():
	match current_state:
		State.Idle:
			animated_sprite_2d.play("idle")
		State.Walk:
			animated_sprite_2d.play("walk")
		State.Falling:
			animated_sprite_2d.play("fall")  # You need a "fall" animation in your sprite
