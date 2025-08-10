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

var active = false
var health = 150
var state = RUN
var direction = directions.right
var player_direction: Vector2
var has_damaged = false

@onready var player = $"../Player"
@onready var sprite = $AnimatedSprite2D
@onready var jump_timer = $JumpTimer
@onready var collision = $CollisionPolygon2D
@onready var attack_sense = $AttackPlayerArea
@onready var cooldown = $AttackCooldown
@onready var healthbar = $ProgressBar
@onready var attack_area = $AttackArea
@onready var exit_ramp = $"../TileMapLayer/BossExit"
@onready var boss_start_zone = $"../BossStartZone"

func animation() -> void:
	sprite.flip_h =  true if direction == directions.left else false
	collision.scale.x = -1 if direction == directions.left else 1
	attack_area.scale.x = -1 if direction == directions.left else 1
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
			if sprite.frame == 9 or sprite.frame == 10:
				for body in attack_area.get_overlapping_bodies():
					if body.name == "Player":
						if not has_damaged:
							has_damaged = true
							body.hit(self)
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
				if body.name == "Player" and cooldown.is_stopped() and state != ATTACK:
					has_damaged = false
					cooldown.start()
					state = ATTACK
		
		if velocity.x < 0:
			direction = directions.left
		elif velocity.x > 0:
			direction = directions.right
		
		
		if player.dead:
			state = IDLE
			velocity.x = 0
			active = false
			boss_start_zone.battle_started = false
		
		move_and_slide()
		animation()
		
		if health <= 0:
			state = DEAD
			active = false
			sprite.play("death")
			healthbar.hide()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		state = IDLE
	elif sprite.animation == "death":
		player.health = 100
		exit_ramp.show()
		exit_ramp.collision_enabled = true
		queue_free()

func hit(attacker: CharacterBody2D) -> void:
	if attacker.name == "Player":
		health -= 15
		healthbar.value = health

func _on_boss_battle_begin() -> void:
	active = true
	health = 150
	healthbar.value = health
