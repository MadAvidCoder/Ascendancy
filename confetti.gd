extends Node2D

var active = false

@onready var particle_1 = $CPUParticles2D
@onready var particle_2 = $CPUParticles2D2
@onready var particle_3 = $CPUParticles2D3
@onready var particle_4 = $CPUParticles2D4

func activate():
	if active == false:
		active = true
		
		particle_1.emitting = true
		particle_2.emitting = true
		particle_3.emitting = true
		particle_4.emitting = true
		
		await get_tree().create_timer(5).timeout
		
		particle_1.lifetime = 1.4
		particle_2.lifetime = 1.4
		particle_3.lifetime = 1.4
		particle_4.lifetime = 1.4
		
		particle_1.explosiveness = 0.2
		particle_2.explosiveness = 0.2
		particle_3.explosiveness = 0.2
		particle_4.explosiveness = 0.2
		
		particle_1.initial_velocity_min = 60
		particle_2.initial_velocity_min = 60
		particle_3.initial_velocity_min = 60
		particle_4.initial_velocity_min = 60
		
		particle_1.initial_velocity_max = 140
		particle_2.initial_velocity_max = 140
		particle_3.initial_velocity_max = 140
		particle_4.initial_velocity_max = 140
		
		particle_1.amount = 50
		particle_2.amount = 50
		particle_3.amount = 50
		particle_4.amount = 50
		
		particle_1.one_shot = false
		particle_2.one_shot = false
		particle_3.one_shot = false
		particle_4.one_shot = false
		
		particle_1.emitting = true
		particle_2.emitting = true
		particle_3.emitting = true
		particle_4.emitting = true

func _on_confetti_activate_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not active:
		activate()
