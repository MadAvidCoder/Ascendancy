extends CharacterBody2D

enum directions {
	left,
	right,
}

enum {
	IDLE,
	ATTACK,
	DEAD,
	HIT,
	RUN,
}

const SPEED = 290

var active: bool = true
var health: int = 150
var state: int = RUN
var direction: directions = directions.right
var player_direction: Vector2

@onready var player = $"../Player"
@onready var sprite = $AnimatedSprite2D
@onready var jump_timer = $JumpTimer
@onready var collision = $CollisionPolygon2D
@onready var attack_sense = $AttackPlayerArea
@onready var cooldown = $AttackCooldown

func animation() -> void:
	sprite.flip_h =  true if direction == directions.left else false
	collision.scale.x = -1 if direction == directions.left else 1
	match state:
		IDLE: sprite.animation = "idle"
		HIT: sprite.animation = "hit"
		RUN: sprite.animation = "run"
		DEAD: sprite.animation = "death"
		ATTACK: sprite.animation = "attack"
	if not sprite.is_playing() and state != DEAD:
		sprite.play()

func _physics_process(delta: float) -> void:
	if active:
		if not is_on_floor():
			velocity += get_gravity() * delta * 1.2
		
		if state == ATTACK:
			velocity.x = 0
		else:
			if position.y > player.position.y + 80 and is_on_floor() and jump_timer.is_stopped():
				velocity.y = -500
				jump_timer.start()
			
			if abs(position.x - player.position.x) < 100:
				velocity.x = 0
				state = IDLE
			else:
				player_direction = position.direction_to(player.position)
				velocity.x = player_direction.x * SPEED
				state = RUN
			
			for body in attack_sense.get_overlapping_bodies():
				if body.name == "Player" and cooldown.is_stopped():
					cooldown.start()
					state = ATTACK
		
		if velocity.x < 0:
			direction = directions.left
		elif velocity.x > 0:
			direction = directions.right

		move_and_slide()
		animation()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		state = IDLE

func hit(attacker: CharacterBody2D) -> void:
	if attacker.name == "Player":
		health -= 10
