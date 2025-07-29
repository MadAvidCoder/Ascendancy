extends Area2D

func _ready() -> void:
	await get_tree().create_timer(randf()).timeout
	$Sprite2D.play()

func _process(_delta: float) -> void:
	for body in self.get_overlapping_bodies():
		if body.name == "Player":
			body.hit(self)
