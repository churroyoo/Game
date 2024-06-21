extends CharacterBody2D

@export var movement_data : PlayerMovementData

var air_jump = false
var direction_last_moved = ""
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_jump_timer = $CoyoteJumpTimer
@onready var dash_timer = $DashTimer

func _physics_process(delta):
	apply_gravity(delta)
	handle_jump()
	var input_axis = Input.get_axis("walk_left", "walk_right")
	handle_acceleration(input_axis, delta)
	handle_air_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)

	update_animations(input_axis)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	print(velocity.x)
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_jump_timer.start()
	
func apply_gravity(delta):
		if not is_on_floor():
			velocity.y += gravity * movement_data.gravity_scale * delta
func handle_jump():
	if is_on_floor(): air_jump = true
	
	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y = movement_data.jump_velocity
	if not is_on_floor():
		if Input.is_action_just_released("jump") and velocity.y < movement_data.jump_velocity / 2:
				velocity.y = movement_data.jump_velocity / 2
		if Input.is_action_just_pressed("jump") and air_jump:
			velocity.y = movement_data.jump_velocity * 0.8
			air_jump = false
func apply_friction(input_axis, delta):
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)
func apply_air_resistance(input_axis, delta):
	if input_axis == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)
func handle_acceleration(input_axis, delta):
	if not is_on_floor(): return
	if input_axis != 0:
		handle_dash(input_axis, delta)
		velocity.x = move_toward(velocity.x, input_axis * movement_data.speed, movement_data.acceleration * delta)

func handle_air_acceleration(input_axis, delta):
	if is_on_floor(): return
	velocity.x = move_toward(velocity.x, input_axis * movement_data.speed, movement_data.air_acceleration * delta)
func update_animations(input_axis):
	if input_axis != 0:
		animated_sprite_2d.flip_h = (input_axis > 0)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor():
		animated_sprite_2d.play("jump")
func handle_dash(input_axis, delta):
	if Input.is_action_just_pressed("walk_left"):
		if direction_last_moved == "left":
			movement_data.speed += 100
			print("dash left", velocity.x)
		else: 
			direction_last_moved = "left"
			movement_data.speed = 200
			dash_timer.start()
	if Input.is_action_just_pressed("walk_right"):
		if direction_last_moved == "right":
			movement_data.speed += 100
			print("dash right", velocity.x)
		else: 
			direction_last_moved = "right"
			movement_data.speed = 200
			dash_timer.start()
func on_dash_timer_timeout():
	direction_last_moved = ""
