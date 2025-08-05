extends Object

# Handles ground acceleration
func handle_acceleration(velocity: Vector2, input_axis: float, delta: float, speed: float, acceleration: float) -> Vector2:
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)
	return velocity

# Applies ground friction
func apply_friction(velocity: Vector2, input_axis: float, delta: float, friction: float) -> Vector2:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	return velocity

# Handles air acceleration
func handle_air_acceleration(velocity: Vector2, input_axis: float, delta: float, speed: float, air_acceleration: float) -> Vector2:
	if input_axis == 1 and velocity.x < 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta * 4)
	elif input_axis == -1 and velocity.x > 1:
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta * 4)
	else: 
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta)
	return velocity

# Applies air resistance
func apply_air_resistance(velocity: Vector2, input_axis: float, delta: float, air_resistance: float) -> Vector2:
	if input_axis == 0:
		velocity.x = move_toward(velocity.x, 0, air_resistance * delta)
	return velocity
