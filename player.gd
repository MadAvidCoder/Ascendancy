extends CharacterBody2D

const SPEED = 375.0
const JUMP_VELOCITY = -430.0

var wall_x_force = 1000.0
var wall_y_force = -645.0

var can_coyote = false
var jump_buffered = false
var sliding = false
var slide_timeout = false
var wall_jumping = false
var can_wall_jump = true
var last_on_wall = INF
var was_wall_jumping = false
var cur_dir = 1
var was_running = 0

@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer = $JumpBuffer
@onready var wall_slide_timer = $WallSlideTimer
@onready var wall_jump_timer = $WallJumpTimer
@onready var left_raycast = $Raycasters/LeftRaycast
@onready var right_raycast = $Raycasters/RightRaycast
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		if velocity.y >= 0:
			velocity += get_gravity() * delta * 1.8
		else:
			velocity += get_gravity() * delta * 1.2

	# Jump
	if Input.is_action_just_pressed("ui_accept") or jump_buffered:
		if is_on_floor():
			jump_buffered = false
			velocity.y = JUMP_VELOCITY
		elif can_coyote:
			can_coyote = false
			velocity.y = JUMP_VELOCITY
		elif velocity.y >= 0 and not jump_buffered:
			jump_buffer.start()
			jump_buffered = true

	# Allow variable jump height
	if Input.is_action_just_released("ui_accept") and velocity.y <= 0 and not wall_jumping:
		velocity.y *= 0.5

	if not wall_jumping:
		# Movement
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			if was_wall_jumping:
				velocity.x = direction * SPEED * 1.3
			else:
				if cur_dir == direction:
					sprite.play("run")
					velocity.x = direction * SPEED
				else:
					if was_running < 0:
						sprite.flip_h = true if cur_dir == 1 else false
						cur_dir = direction
						velocity.x = direction * SPEED
					else:
						if sprite.animation != "turn":
							sprite.play("turn")
						velocity.x = -direction * SPEED / 2
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED/1.2)
		if velocity.x <= 0:
			wall_jumping = false
			was_wall_jumping = true
	
	last_on_wall += delta
	if is_on_wall_only():
		last_on_wall = 0
		if not slide_timeout:
			if not sliding:
				wall_slide_timer.start()
				sliding = true
			velocity.y = 100
	else:
		sliding = false
		slide_timeout = false
	if last_on_wall < 0.1 and Input.is_action_just_pressed("ui_accept") and can_wall_jump:
		wall_jump_timer.start()
		can_wall_jump = false
		wall_jumping = true
		velocity.y = wall_y_force
		if left_raycast.is_colliding():
			velocity.x = wall_x_force
		elif right_raycast.is_colliding():
			velocity.x = -wall_x_force
		else:
			wall_jumping = false
	
	# Check if landed
	if is_on_floor():
		wall_jumping = false
	
	# Coyote Time
	var was_on_floor := is_on_floor()
	if velocity.x == 0:
		sprite.play("idle")
		was_running -= delta
	else:
		was_running = 0.1
	# Move character
	move_and_slide()
	
	# Coyote Time
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		can_coyote = true
		coyote_timer.start()

func _on_coyote_timeout() -> void:
	can_coyote = false

func _on_jump_buffer_timeout() -> void:
	jump_buffered = false

func _on_wall_slide_timer_timeout() -> void:
	slide_timeout = true

func _on_wall_jump_timer_timeout() -> void:
	can_wall_jump = true

func _on_sprite_2d_animation_finished() -> void:
	if sprite.animation == "turn":
		cur_dir = -cur_dir
		sprite.flip_h = true if cur_dir == -1 else false
