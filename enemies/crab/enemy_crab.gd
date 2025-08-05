extends CharacterBody2D

var enemy_death_effect = preload("res://enemies/enemy_death_effect.tscn")

@export var patrol_points : Node

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

const GRAVITY = 1000
@export var speed : int = 25
@export var wait_time : int = 3

enum State { Idle, Walk, Falling }

var current_state : State
var was_on_floor = true
var direction : Vector2 = Vector2.LEFT
var number_of_points : int
var point_positions : Array[Vector2]
var current_point : Vector2
var current_point_position : int #set to 0 by default
var can_walk : bool

@export var healt_amount : int = 3


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
	
	timer.wait_time = wait_time
	current_state = State.Idle
	
	can_walk = true

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
		if can_walk:
			crab_walk()
		else:
			crab_idle()  # Call idle when waiting

	was_on_floor = is_on_floor()


func crab_falling(delta : float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func crab_walk():
	current_point = point_positions[current_point_position]  # Update point first

	if abs(position.x - current_point.x) > 0.5:
		velocity.x = direction.x * speed
	else:
		current_point_position = current_point_position ^ 1
		can_walk = false
		velocity.x = 0  # Immediately stop horizontal movement
		timer.start()

	if current_point.x > position.x:
		direction = Vector2.RIGHT
	else:
		direction = Vector2.LEFT
	
	animated_sprite_2d.flip_h = (direction == Vector2.RIGHT)

func crab_idle():
	velocity.x = move_toward(velocity.x, 0, speed * get_physics_process_delta_time())
	current_state = State.Idle
	
func crab_animations():
	match current_state:
		State.Idle:
			animated_sprite_2d.play("idle")
		State.Walk:
			animated_sprite_2d.play("walk")
		State.Falling:
			animated_sprite_2d.play("fall")  # You need a "fall" animation in your sprite

func _on_timer_timeout() -> void:
	can_walk = true
	current_state = State.Walk


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.get_parent().has_method("get_damage_amount"):
		var node = area.get_parent() as Node
		healt_amount -= node.damage_amount
		# when healt is 0 add the death effect to enemy scene as child for playing animetion then remove the enemy scene instance
		if healt_amount <= 0:
			var enemy_death_effect_instance = enemy_death_effect.instantiate() as Node2D
			enemy_death_effect_instance.global_position = global_position
			get_parent().add_child(enemy_death_effect_instance)
			queue_free()
