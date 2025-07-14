extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var coyote_timer = $CoyoteTimer
var can_coyote = false

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or can_coyote):
		can_coyote = false
		velocity.y = JUMP_VELOCITY

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Coyote Time
	var was_on_floor := is_on_floor()
	
	# Move character
	move_and_slide()
	
	# Coyote Time
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		can_coyote = true
		coyote_timer.start()

func _on_coyote_timeout() -> void:
	can_coyote = false
