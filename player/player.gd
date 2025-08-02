extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle

const GRAVITY = 1000

@export var speed: int = 300
@export var jump: int = 300
@export var jump_horizontal: int = 300

enum State { Idle, Run, Jump, Shoot, Stand }

var current_state: State = State.Idle
var previous_state: State = State.Idle
var was_on_floor = true

var bullet = preload("res://player/bullet.tscn")
var muzzle_position
var facing_left = false

func _ready():
	muzzle_position = muzzle.position
	change_state(State.Idle)


func _physics_process(delta: float):
	player_falling(delta)
	player_jump(delta)

	var direction = input_movement()
	var is_jumping = !is_on_floor()
	var is_shooting = Input.is_action_pressed("shoot")

	# === State Transitions ===
	match current_state:
		State.Jump:
			if is_on_floor():
				if is_shooting:
					change_state(State.Shoot if direction != 0 else State.Stand)
				else:
					change_state(State.Run if direction != 0 else State.Idle)

		State.Shoot:
			if !is_shooting:
				change_state(State.Run if direction != 0 else State.Idle)
			elif direction == 0:
				change_state(State.Stand)

		State.Stand:
			if !is_shooting:
				change_state(State.Idle)
			elif direction != 0:
				change_state(State.Shoot)

		State.Run:
			if is_jumping:
				change_state(State.Jump)
			elif is_shooting:
				change_state(State.Shoot if direction != 0 else State.Stand)
			elif direction == 0:
				change_state(State.Idle)

		State.Idle:
			if is_jumping:
				change_state(State.Jump)
			elif direction != 0:
				change_state(State.Run)
			elif is_shooting:
				change_state(State.Shoot if direction != 0 else State.Stand)

	# === Per-State Behavior ===
	match current_state:
		State.Run:
			player_run(delta)
		State.Idle:
			player_idle(delta)
		State.Shoot, State.Stand:
			player_shooting(delta)
		State.Jump:
			pass  # Jumping handled separately

	move_and_slide()
	player_animations()
	was_on_floor = is_on_floor()

	# Debug
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


# === Movement and State Behaviors ===
func player_falling(delta: float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func player_jump(delta: float):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(State.Jump)
	if !is_on_floor() and current_state == State.Jump:
		var direction = input_movement()
		velocity.x = direction * jump_horizontal


func player_idle(delta: float):
	velocity.x = 0


func player_run(delta: float):
	var direction = input_movement()
	velocity.x = direction * speed
	if direction != 0:
		facing_left = direction < 0
	animated_sprite_2d.flip_h = facing_left


func player_shooting(delta: float):
	var direction = input_movement()

	if current_state == State.Shoot:
		velocity.x = direction * speed
	elif current_state == State.Stand:
		velocity.x = 0

	# Allow flipping direction even when standing
	if direction != 0:
		facing_left = direction < 0
	animated_sprite_2d.flip_h = facing_left

	# Bullet instantiation logic (TODO)
	# if Input.is_action_just_pressed("shoot"):
	#     var bullet_instance = bullet.instantiate()
	#     bullet_instance.global_position = muzzle.global_position
	#     bullet_instance.set("direction", facing_left ? -1 : 1)
	#     get_tree().current_scene.add_child(bullet_instance)


func player_animations():
	match current_state:
		State.Idle:
			animated_sprite_2d.play("idle")
		State.Run:
			animated_sprite_2d.play("run")
		State.Jump:
			animated_sprite_2d.play("jump")
		State.Shoot:
			animated_sprite_2d.play("run_shoot")
		State.Stand:
			animated_sprite_2d.play("stand")


func input_movement():
	return Input.get_axis("move_left", "move_right")
