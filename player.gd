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
var cur_dir = -1
var was_running = 0
var attacking = false
var damaged = []
var is_hit = false
var hit_by
var dead = false
var health = 100

@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer = $JumpBuffer
@onready var wall_slide_timer = $WallSlideTimer
@onready var wall_jump_timer = $WallJumpTimer
@onready var left_raycast = $Raycasters/LeftRaycast
@onready var right_raycast = $Raycasters/RightRaycast
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var collision_rect = load("res://player_collision_rectangle.tres")
@onready var attack_area = $AttackArea
@onready var attack_polygon = $AttackArea/CollisionPolygon2D
@onready var bottom_raycast = $Raycasters/BottomRaycast
@onready var knockback =  $KnockbackTimer
@onready var healthbar = $ProgressBar
@onready var respawn_timer = $RespawnTimer
@onready var safe_timer = $SafeTimer
@onready var boss = $"../Boss"

func _process(delta: float) -> void:
	healthbar.value = health
	if sprite.flip_h:
		healthbar.position = Vector2(-26,-10)
		match sprite.animation:
			"idle", "run", "jump": 
				collision_rect.size = Vector2(20.75, 38.0)
				collision.position = Vector2(11.25, 42.0)
			"wall_hang", "wall_slide":
				collision_rect.size = Vector2(20.0, 38.0)
				collision.position = Vector2(2, 42.0)
			"attack_1":
				collision_rect.size = Vector2(23.25, 38.0)
				collision.position = Vector2(8.75, 42.0)
	else:
		healthbar.position = Vector2(-45,-10)
		match sprite.animation:
			"idle", "run", "jump": 
				collision_rect.size = Vector2(20.75, 38.0)
				collision.position = Vector2(-10.75, 42.0)
			"wall_hang", "wall_slide":
				collision_rect.size = Vector2(22.0, 34.0)
				collision.position = Vector2(-2, 42.0)
			"attack_1":
				collision_rect.size = Vector2(23.25, 38.0)
				collision.position = Vector2(-8.25, 42.0)

func _physics_process(delta: float) -> void:
	if not dead:
		# Gravity
		if not is_on_floor():
			if safe_timer.is_stopped():
				if velocity.y >= 0:
					velocity += get_gravity() * delta * 1.8
				else:
					velocity += get_gravity() * delta * 1.2
			else:
				velocity += get_gravity() * delta * 0.75
		
		# Jump
		if Input.is_action_just_pressed("jump") or jump_buffered:
			if sprite.animation == "turn":
				cur_dir = -cur_dir
				sprite.flip_h = true if cur_dir == -1 else false
			if is_on_floor():
				sprite.play("jump")
				attacking = false
				jump_buffered = false
				velocity.y = JUMP_VELOCITY
			elif can_coyote:
				sprite.play("jump")
				attacking = false
				can_coyote = false
				velocity.y = JUMP_VELOCITY
			elif velocity.y >= 0 and not jump_buffered:
				jump_buffer.start()
				jump_buffered = true

		# Allow variable jump height
		if Input.is_action_just_released("jump") and velocity.y <= 0 and not wall_jumping:
			velocity.y *= 0.5

		if not wall_jumping and not attacking:
			# Movement
			var direction := Input.get_axis("left", "right")
			if direction and not is_hit:
				if was_wall_jumping:
					velocity.x = direction * SPEED * 1.3
					cur_dir = direction
				else:
					if cur_dir == direction or velocity.y != 0:
						cur_dir = direction
						if velocity.y == 0 and not is_hit and not attacking:
							sprite.play("run")
						velocity.x = direction * SPEED
					else:
						if was_running < 0:
							sprite.flip_h = true if cur_dir == 1 else false
							cur_dir = direction
							velocity.x = direction * SPEED
						else:
							if sprite.animation != "turn" and not attacking:
								sprite.play("turn")
							velocity.x = -direction * SPEED / 2
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED/1.2)
			if velocity.y <= 0:
				wall_jumping = false
				was_wall_jumping = true
		
		last_on_wall += delta
		if is_on_wall_only() and not bottom_raycast.is_colliding():
			sprite.play("wall_slide")
			if left_raycast.is_colliding():
				sprite.flip_h = false
			elif right_raycast.is_colliding():
				sprite.flip_h = true
			last_on_wall = 0
			if not slide_timeout:
				if not sliding:
					wall_slide_timer.start()
					sliding = true
				velocity.y = 100
		else:
			sliding = false
			slide_timeout = false
		
		if last_on_wall < 0.2 and Input.is_action_just_pressed("jump") and can_wall_jump:
			wall_jump_timer.start()
			can_wall_jump = false
			wall_jumping = true
			velocity.y = wall_y_force
			if left_raycast.is_colliding():
				sprite.flip_h = true
				velocity.x = wall_x_force
			elif right_raycast.is_colliding():
				sprite.flip_h = false
				velocity.x = -wall_x_force
			else:
				wall_jumping = false
		
		# Check if landed
		if is_on_floor():
			wall_jumping = false
			was_wall_jumping = false
		
		# Coyote Time
		var was_on_floor := is_on_floor()
		
		if velocity.x == 0:
			if not attacking and not is_hit and not was_wall_jumping and not wall_jumping:
				sprite.play("idle")
			was_running -= delta
		else:
			was_running = 0.1
		
		if Input.is_action_just_pressed("attack") and is_on_floor() and not attacking:
			attack_polygon.scale.x = -1 if sprite.flip_h else 1
			if boss.active:
				sprite.play("attack_1")
			else:
				sprite.play("attack_2")
			attacking = true
			damaged = []
		
		if attacking:
			if (sprite.animation == "attack_1" and sprite.frame != 0) or (sprite.animation == "attack_2" and not sprite.frame in [0,1]):
				for attacked_body in attack_area.get_overlapping_bodies():
					if not attacked_body in damaged:
						damaged.append(attacked_body)
						attacked_body.hit(self)
		
		if is_hit:
			velocity.x = position.direction_to(hit_by.position).x * -600
		
		if not sprite.animation == "turn" and not sprite.animation == "wall_slide":
			if velocity.x < 0:
				sprite.flip_h = true
			elif velocity.x > 0:
				sprite.flip_h = false
		
		# Move character
		move_and_slide()
		
		# Coyote Time
		if was_on_floor and not is_on_floor() and velocity.y >= 0:
			can_coyote = true
			coyote_timer.start()
	else:
		if not is_on_floor():
			velocity = Vector2(0,0)
			if velocity.y >= 0:
				velocity += get_gravity() * delta * 1.8
			else:
				velocity += get_gravity() * delta * 1.2
			move_and_slide()

func _on_coyote_timeout() -> void:
	can_coyote = false

func _on_jump_buffer_timeout() -> void:
	jump_buffered = false

func _on_wall_slide_timer_timeout() -> void:
	slide_timeout = true

func _on_wall_jump_timer_timeout() -> void:
	can_wall_jump = true

func _on_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"turn":
			sprite.play("run")
			cur_dir = -cur_dir
			sprite.flip_h = true if cur_dir == -1 else false
		"attack_1", "attack_2": attacking = false

func hit(attacker):
	if not dead:
		if "Fire" in attacker.name:
			if not dead and safe_timer.is_stopped():
				health = 0
				sprite.play("death")
				dead = true
				healthbar.hide()
				respawn_timer.start()
				safe_timer.start()
		elif "Skeleton" in attacker.name:
			if not dead and safe_timer.is_stopped():
				health -= 33.34
				if health <= 0:
					healthbar.hide()
					sprite.play("death")
					dead = true
					respawn_timer.start()
					safe_timer.start()
				else:
					sprite.play("hit")
					is_hit = true
					knockback.start()
					hit_by = attacker
		elif "Boss" in attacker.name:
			if not dead:
				health -= 12.5
				if health <= 0:
					healthbar.hide()
					sprite.play("death")
					dead = true
					respawn_timer.start(3)
					safe_timer.start(3.5)
				else:
					is_hit = true
					sprite.play("hit")
					knockback.start()
					hit_by = attacker

func _on_knockback_timer_timeout() -> void:
	is_hit = false
	attacking = false
	sprite.play("idle")

func _on_boss_battle_begin() -> void:
	health = 100

func _on_respawn_timer_timeout() -> void:
	position = Vector2(137,150)
	health = 100
	healthbar.show()
	sprite.play("idle")
	dead = false
