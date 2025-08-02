extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_up: Marker2D = $MuzzleUp
@onready var muzzle_duck: Marker2D = $MuzzleDuck

const GRAVITY = 1000

@export var speed: int = 300
@export var jump: int = 300
@export var jump_horizontal: int = 300
@export var shoot_cooldown_time: float = 0.2  # seconds between shots

enum State { Idle, Run, Jump, Stand, Up, Duck }

var current_state: State = State.Idle
var previous_state: State = State.Idle
var was_on_floor = true

var bullet = preload("res://player/bullet.tscn")
var active_muzzle: Marker2D
var facing_left = false

var shoot_cooldown = 0.0
var is_shooting = false

# Coyote time and jump buffer variables
var coyote_time = 0.1
var coyote_timer = 0.0

var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

func _ready():
	active_muzzle = muzzle
	change_state(State.Idle)

func _physics_process(delta: float):
	shoot_cooldown = max(shoot_cooldown - delta, 0)
	
	var direction = input_movement()
	var on_floor = is_on_floor()
	
	is_shooting = Input.is_action_pressed("shoot")
	
	# Update coyote timer
	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Update jump buffer timer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0)

	# Jump logic using coyote time and jump buffer
	if jump_buffer_timer > 0 and coyote_timer > 0:
		change_state(State.Jump)
		jump_buffer_timer = 0
		coyote_timer = 0
	elif !on_floor:
		change_state(State.Jump)
	elif Input.is_action_pressed("look_up"):
		change_state(State.Up)
	elif Input.is_action_pressed("duck"):
		change_state(State.Duck)
	elif direction != 0:
		change_state(State.Run)
	else:
		change_state(State.Idle)

	# Shooting overrides state only if idle
	if is_shooting and current_state == State.Idle:
		change_state(State.Stand)

	# Per-state movement behavior
	match current_state:
		State.Run:
			player_run(direction, delta)
		State.Idle:
			player_idle()
		State.Jump:
			player_jump(direction, delta)
		State.Up:
			player_up(direction)  # pass direction for flipping
		State.Duck:
			player_duck(direction)  # pass direction for flipping
		State.Stand:
			player_idle()  # no movement while shooting standing still

	player_falling(delta)
	move_and_slide()
	player_animations()
	
	was_on_floor = on_floor
	
	if is_shooting and shoot_cooldown == 0:
		shoot()
	
	# Exit Stand when shooting stops
	if current_state == State.Stand and !is_shooting:
		change_state(State.Idle)

	print("State: ", State.keys()[current_state])

func change_state(new_state: State):
	if new_state == current_state:
		return
	exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	enter_state(current_state)

func enter_state(state: State):
	if state == State.Jump and is_on_floor():
		velocity.y = -jump

func exit_state(state: State):
	pass

func player_falling(delta: float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

func player_jump(direction: int, delta: float):
	if !is_on_floor() and current_state == State.Jump:
		velocity.x = direction * jump_horizontal

func player_idle():
	velocity.x = 0

func player_run(direction: int, delta: float):
	velocity.x = direction * speed
	if direction != 0:
		facing_left = direction < 0
	animated_sprite_2d.flip_h = facing_left

func player_up(direction: int):
	velocity.x = 0
	if direction != 0:
		facing_left = direction < 0
	animated_sprite_2d.flip_h = facing_left

func player_duck(direction: int):
	velocity.x = 0
	if direction != 0:
		facing_left = direction < 0
	animated_sprite_2d.flip_h = facing_left

func player_animations():
	if is_shooting:
		if current_state == State.Run:
			animated_sprite_2d.play("run_shoot")   # shooting while running animation
		elif current_state == State.Stand:
			animated_sprite_2d.play("stand")   # shooting while standing still animation
		elif current_state == State.Up:
			animated_sprite_2d.play("look_up")
		elif current_state == State.Duck:
			animated_sprite_2d.play("duck")
	else:
		match current_state:
			State.Idle:
				animated_sprite_2d.play("idle")
			State.Run:
				animated_sprite_2d.play("run")
			State.Jump:
				animated_sprite_2d.play("jump")
			State.Stand:
				animated_sprite_2d.play("stand")
			State.Up:
				animated_sprite_2d.play("look_up")
			State.Duck:
				animated_sprite_2d.play("duck")

func input_movement():
	return Input.get_axis("move_left", "move_right")

func shoot():
	# Select muzzle based on current state
	return
	match current_state:
		State.Jump:
			active_muzzle = muzzle
		State.Up:
			active_muzzle = muzzle_up
		State.Duck:
			active_muzzle = muzzle_duck
		_:
			active_muzzle = muzzle

	# Spawn bullet instance
	var bullet_instance = bullet.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = active_muzzle.global_position
	
	# Set bullet direction — assuming your bullet script has a 'direction' variable
	if facing_left:
		bullet_instance.direction = -1
	else:
		bullet_instance.direction = 1

	# Reset shoot cooldown
	shoot_cooldown = shoot_cooldown_time
