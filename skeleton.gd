extends CharacterBody2D

const SPEED = 45

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
@onready var death_timer = $DeathTimer
@onready var raycasts = {
	"left": {
		"down": $Raycasters/DownLeft,
		"top": $Raycasters/LeftTop,
		"bottom": $Raycasters/LeftBottom,
	},
	"right" : {
		"down": $Raycasters/DownRight,
		"top": $Raycasters/RightTop,
		"bottom": $Raycasters/RightBottom,
	}
}

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
		if direction == -1:
			if not raycasts["left"]["down"].is_colliding() or raycasts["left"]["top"].is_colliding() or raycasts["left"]["bottom"].is_colliding():
				dir_timer.start(choose([2, 2.5, 3]))
				state = IDLE
				velocity.x = 0
		elif direction == 1:
			if not raycasts["right"]["down"].is_colliding() or raycasts["right"]["top"].is_colliding() or raycasts["right"]["bottom"].is_colliding():
				dir_timer.start(choose([2, 2.5, 3]))
				state = IDLE
				velocity.x = 0
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

func hit(attacker):
	if health >= 0:
		health -= 30
		state = HIT
		if health < 0:
			state = DEAD
			sprite.play("dead")
			death_timer.start()

func _on_death_timer_timeout() -> void:
	self.queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == 'hit':
		sprite.play("idle")
		state = IDLE
		dir_timer.start(0.1)
