extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_up: Marker2D = $MuzzleUp
@onready var muzzle_duck: Marker2D = $MuzzleDuck

const GRAVITY = 1000

@export var speed: int = 300
@export var jump: int = 300
@export var jump_horizontal: int = 300
@export var shoot_cooldown_time: float = 0.2

enum State { Idle, Run, Jump, Stand, Up, Duck }

var current_state: State = State.Idle
var previous_state: State = State.Idle
var was_on_floor = true

var bullet = preload("res://player/bullet.tscn")
var active_muzzle: Marker2D
var facing_left = false

var shoot_cooldown = 0.0
var is_shooting = false

var coyote_time = 0.1
var coyote_timer = 0.0

var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

func _ready():
	active_muzzle = muzzle
	change_state(State.Idle)

func _physics_process(delta: float):
	var direction = input_movement()
	var on_floor = is_on_floor()

	update_facing_input()

	# Cooldowns
	shoot_cooldown = max(shoot_cooldown - delta, 0)
	is_shooting = Input.is_action_pressed("shoot")

	# Timers
	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0)

	process_state_transitions(direction, on_floor)

	# State behavior
	match current_state:
		State.Run:
			player_run(direction, delta)
		State.Idle:
			player_idle()
		State.Jump:
			player_jump(direction, delta)
		State.Up:
			player_up()
		State.Duck:
			player_duck()
		State.Stand:
			player_idle()

	# Universal movement & animation
	player_falling(delta)
	move_and_slide()
	player_animations()

	# Shooting
	if is_shooting and shoot_cooldown == 0:
		shoot()

	if current_state == State.Stand and !is_shooting:
		change_state(State.Idle)

	was_on_floor = on_floor

	# Debug
	print("State: ", State.keys()[current_state])

# --------------------------------------------------
# STATE MACHINE
# --------------------------------------------------

func process_state_transitions(direction: int, on_floor: bool):
	# Jump buffer + coyote time
	if jump_buffer_timer > 0 and coyote_timer > 0:
		jump_buffer_timer = 0
		coyote_timer = 0
		change_state(State.Jump)
		return

	# Falling
	if !on_floor and current_state != State.Jump:
		change_state(State.Jump)
		return

	# Maintain look_up or duck states
	if current_state == State.Up and Input.is_action_pressed("look_up"):
		return
	if current_state == State.Duck and Input.is_action_pressed("duck"):
		return

	# Idle shooting becomes stand
	if is_shooting and current_state == State.Idle:
		change_state(State.Stand)
		return

	# Duck or Look Up if on floor
	if on_floor and direction == 0:
		if Input.is_action_pressed("duck"):
			change_state(State.Duck)
			return
		elif Input.is_action_pressed("look_up"):
			change_state(State.Up)
			return

	# Run
	if direction != 0 and on_floor:
		change_state(State.Run)
		return

	# Default Idle
	if on_floor:
		change_state(State.Idle)
		

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

# --------------------------------------------------
# PLAYER LOGIC
# --------------------------------------------------

func input_movement() -> int:
	return Input.get_axis("move_left", "move_right")

func update_facing_input():
	if Input.is_action_pressed("move_left"):
		facing_left = true
	elif Input.is_action_pressed("move_right"):
		facing_left = false

	animated_sprite_2d.flip_h = facing_left
	flip_muzzle_markers(facing_left)

func flip_muzzle_markers(flip_left: bool):
	var flip_scale = -1 if flip_left else 1
	muzzle.scale.x = flip_scale
	muzzle_up.scale.x = flip_scale
	muzzle_duck.scale.x = flip_scale

func player_falling(delta: float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

func player_jump(direction: int, delta: float):
	if !is_on_floor():
		velocity.x = direction * jump_horizontal

func player_idle():
	velocity.x = 0

func player_run(direction: int, delta: float):
	velocity.x = direction * speed

func player_up():
	velocity.x = 0

func player_duck():
	velocity.x = 0

# --------------------------------------------------
# ANIMATIONS
# --------------------------------------------------

func player_animations():
	if is_shooting:
		match current_state:
			State.Run:
				animated_sprite_2d.play("run_shoot")
			State.Idle, State.Stand:
				animated_sprite_2d.play("stand")
			State.Up:
				animated_sprite_2d.play("look_up")
			State.Duck:
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

# --------------------------------------------------
# SHOOTING
# --------------------------------------------------

func shoot():
	return
	match current_state:
		State.Up:
			active_muzzle = muzzle_up
		State.Duck:
			active_muzzle = muzzle_duck
		_:
			active_muzzle = muzzle

	var bullet_instance = bullet.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = active_muzzle.global_position
	bullet_instance.direction = -1 if facing_left else 1

	shoot_cooldown = shoot_cooldown_time
