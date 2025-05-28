extends CharacterBody3D

var health = 100

func _process(delta: float) -> void:
	if health <= 0:
		queue_free()
