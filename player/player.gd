extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_up: Marker2D = $MuzzleUp
@onready var muzzle_duck: Marker2D = $MuzzleDuck
@onready var muzzle_cling: Marker2D = $MuzzleCling

@onready var wall_check: ShapeCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck
@onready var ledge_grab: CollisionShape2D = $LedgeGrab
@onready var top_check: ShapeCast2D = $TopCheck

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer: Timer = $JumpBuffer
@onready var weapon_cooldown: Timer = $WeaponCooldown

@onready var hit_animation_player: AnimationPlayer = $HitAnimationPlayer

const GRAVITY = 1000

@export var speed: int = 300
@export var acceleration: float = 400.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -350.0
@export var air_resistance: float = 150.0
@export var air_acceleration: float = 275.0
@export var shoot_cooldown_time: float = 0.2

enum State { Idle, Run, Jump, Fall, Up, Duck, LedgeGrab }

var current_state: State = State.Idle
var previous_state: State = State.Idle

var bullet = preload("res://player/bullet.tscn")
var active_muzzle: Marker2D
var facing_left = false

var shoot_cooldown = 0.0
var is_shooting = false
var is_ducking = false
var is_looking_up = false

func _ready():
	active_muzzle = muzzle
	weapon_cooldown.wait_time = shoot_cooldown_time
	weapon_cooldown.one_shot = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer.start()

func _physics_process(delta: float):
	shoot_cooldown = max(shoot_cooldown - delta, 0)

	var direction = input_movement()
	var on_floor = is_on_floor()

	is_shooting = Input.is_action_pressed("shoot")
	is_ducking = Input.is_action_pressed("duck")
	is_looking_up = Input.is_action_pressed("look_up")

	update_facing_input()

	# Disable ledgegrab collider unless it's needed
	ledge_grab.disabled = current_state in [State.Run, State.Idle] or velocity.y < 0 or (current_state != State.LedgeGrab and top_check.is_colliding())

	# Check for ledge grab in airborne states
	if current_state in [State.Jump, State.Fall]:
		if check_ledge_grab():
			current_state = State.LedgeGrab

	# Check if landing, switch state as necessary
	if on_floor and current_state != State.LedgeGrab:
		if velocity.x != 0:
			current_state = State.Run
		elif is_ducking and !is_looking_up:
			current_state = State.Duck
		elif !is_ducking and is_looking_up:
			current_state = State.Up
		else:
			current_state = State.Idle

	# Check if falling
	if !on_floor and current_state in [State.Idle, State.Run]:
		current_state = State.Fall
	
	# In-air states movement
	if current_state in [State.Jump, State.Fall]:
		handle_jump_input()
		apply_gravity(delta)
		handle_air_acceleration(direction, delta)
		apply_air_resistance(direction, delta)
	
	# Grounded state movement
	if current_state in [State.Idle, State.Run]:
		handle_jump_input()
		handle_acceleration(direction, delta)
		apply_friction(direction, delta)

	# State-specific behavior
	match current_state:
		State.LedgeGrab:
			if floor_check.is_colliding():
				current_state = State.Idle
			velocity.x = 0
			var collider = wall_check.get_collision_normal(0)
			if collider.x == -1:
				animated_sprite_2d.flip_h = true
				if not is_on_wall():
					velocity.x = 25
			else:
				animated_sprite_2d.flip_h = false
				if not is_on_wall():
					velocity.x = -25
			if top_check.is_colliding():
				velocity.y = 80
			handle_jump_input()

	#Apply movement
	handle_shoot_input()
	player_animations()
	move_and_slide()

	# Start coyote timer if just left ledge
	if !is_on_floor() and on_floor:
		coyote_timer.start()
		
	#print("State: ", State.keys()[current_state])
	
	return
	

func apply_gravity(delta: float) -> void:
	if not is_on_floor() and velocity.y < 700:
		velocity.y += GRAVITY * delta

func handle_acceleration(input_axis, delta) -> void:
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)

func apply_friction(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_air_acceleration(input_axis, delta) -> void:
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta)

func apply_air_resistance(input_axis, delta) -> void:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, air_resistance * delta)

func handle_jump_input() -> void:
	if is_on_floor() or coyote_timer.time_left > 0:
		if jump_buffer.time_left > 0:
			velocity.y = jump_velocity
			animated_sprite_2d.play("jump")
			current_state = State.Jump
			jump_buffer.stop()

func input_movement() -> int:
	return Input.get_axis("move_left", "move_right")

func update_facing_input():
	if current_state == State.LedgeGrab:
		return
	if Input.is_action_pressed("move_left"):
		facing_left = true
	elif Input.is_action_pressed("move_right"):
		facing_left = false
	animated_sprite_2d.flip_h = facing_left
	flip_muzzle_markers(facing_left)

func flip_muzzle_markers(flip_left: bool):
	var direction = -1 if flip_left else 1
	muzzle.position.x = abs(muzzle.position.x) * direction
	muzzle_up.position.x = abs(muzzle_up.position.x) * direction
	muzzle_duck.position.x = abs(muzzle_duck.position.x) * direction
	muzzle_cling.position.x = abs(muzzle_cling.position.x) * -direction

func player_animations():
	if is_shooting:
		match current_state:
			State.Run:
				animated_sprite_2d.play("run_shoot")
			State.Idle:
				animated_sprite_2d.play("stand")
			State.Up:
				animated_sprite_2d.play("look_up")
			State.Duck:
				animated_sprite_2d.play("duck")
			State.LedgeGrab:
				animated_sprite_2d.flip_h = !facing_left
				animated_sprite_2d.play("cling")
	else:
		match current_state:
			State.Idle:
				animated_sprite_2d.play("idle")
			State.Run:
				animated_sprite_2d.play("run")
			State.Jump:
				animated_sprite_2d.play("jump")
			State.Up:
				animated_sprite_2d.play("look_up")
			State.Duck:
				animated_sprite_2d.play("duck")
			State.LedgeGrab:
				animated_sprite_2d.flip_h = !facing_left
				animated_sprite_2d.play("cling")

func handle_shoot_input():
	if !is_shooting or weapon_cooldown.time_left > 0:
		return

	var dir := Vector2.ZERO

	match current_state:
		State.Jump:
			active_muzzle = muzzle
			dir = Vector2(-1, 0) if facing_left else Vector2(1, 0)
		State.Up:
			active_muzzle = muzzle_up
			dir = Vector2(0, -1)
		State.Duck:
			active_muzzle = muzzle_duck
			dir = Vector2(-1, 0) if facing_left else Vector2(1, 0)
		State.LedgeGrab:
			active_muzzle = muzzle_cling
			dir = Vector2(1, 0) if facing_left else Vector2(-1, 0)
		_:
			active_muzzle = muzzle
			dir = Vector2(-1, 0) if facing_left else Vector2(1, 0)

	var bullet_instance = bullet.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.dir = dir
	bullet_instance.global_position = active_muzzle.global_position

	weapon_cooldown.start()

func check_ledge_grab():
	return wall_check.is_colliding() and not floor_check.is_colliding() and velocity.y == 0


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		print("enemy entered")
		hit_animation_player.play("hit")
		HealthManager.decrease_health(body.damage_amount)
