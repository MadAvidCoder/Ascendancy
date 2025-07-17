extends CharacterBody2D

const SPEED = 50

var health = 80
var max_health = 80 #??
var state = IDLE
var chasing = false

var knockback = 100
var direction = -1

enum {
	IDLE,
	WALKING,
	ATTACKING,
	HIT,
	DEAD
}

@onready var sprite = $AnimatedSprite2D
@onready var dir_timer = $DirectionTimer

func animation():
	sprite.flip_h = true if direction == -1 else false
	match state:
		IDLE:
			sprite.animation = "idle"
			sprite.position = Vector2(0,0)
		"react":
			sprite.position = Vector2(-3,0)
		HIT:
			sprite.animation = "hit"
			sprite.position = Vector2(-7,0)
		WALKING:
			sprite.animation = "walk"
			sprite.position = Vector2(-3,0)
		DEAD:
			sprite.animation = "dead"
			sprite.position = Vector2(-15,0)
		ATTACKING:
			sprite.animation = "attack"
			sprite.position = Vector2(15,-6)
	if sprite.flip_h:
		sprite.position.x = -sprite.position.x
		sprite.position.x -= 19

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity.x = 0
	
	if state == WALKING:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED/3)
	
	animation()
	
	move_and_slide()

func _on_direction_timer_timeout() -> void:
	if state == IDLE:
		state = WALKING
		dir_timer.start(choose([3.5, 4, 4.5, 5]))
		if not chasing:
			direction = -direction
	elif state == WALKING:
		dir_timer.start(choose([2, 2.5, 3]))
		state = IDLE

func choose(arr):
	arr.shuffle()
	return arr.front()
