extends Area2D

## Emitted when the player enters this area to commence the boss battle
signal battle_begin

var battle_started = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not battle_started:
		battle_started = true
		battle_begin.emit()
		queue_free()
