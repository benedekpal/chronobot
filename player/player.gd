extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const GRAVITY = 1000

@export var speed : int = 300
@export var jump : int = 300
@export var jump_horizontal : int = 300

enum State { Idle, Run, Jump }

var current_state : State
var was_on_floor = true

func _ready():
	current_state = State.Idle
	
	
func _process(delta):
	pass


func _physics_process(delta : float):
	player_falling(delta)
	player_jump(delta)
	
	# Detect landing
	if is_on_floor() and !was_on_floor:
		# Just landed
		velocity.x = 0  # stop horizontal sliding
		current_state = State.Idle  # reset state on landing

	was_on_floor = is_on_floor()

	if current_state != State.Jump:
		player_idle(delta)
		player_run(delta)

	print("State: ", State.keys()[current_state])

	move_and_slide()
	player_animations()
	
	
func player_falling(delta : float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func player_idle(delta : float):
	if is_on_floor() and current_state != State.Jump:
		current_state = State.Idle
		
		
func player_run(delta : float):
	var direction = input_movement()

	if direction:
		velocity.x = direction * speed
		# Flip the sprite if moving left
		animated_sprite_2d.flip_h = direction < 0
		current_state = State.Run
	else:
		velocity.x = 0  # stop sliding
		current_state = State.Idle
		
func player_jump(delta : float):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump
		current_state = State.Jump

	if !is_on_floor() and current_state == State.Jump:
		var direction = input_movement()
		velocity.x = direction * jump_horizontal


func player_animations():
	if current_state == State.Idle:
		animated_sprite_2d.play("idle")
	elif current_state == State.Run:
		animated_sprite_2d.play("run")
	elif current_state == State.Jump:
		animated_sprite_2d.play("jump")
		
		
func input_movement():
	var direction : float = Input.get_axis("move_left", "move_right")
	return direction
