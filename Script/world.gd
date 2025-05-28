extends Node3D

@onready var spawn_timer: Timer = $"Spawn-Timer"    #سيتم تغيير حاصية ال wait time بعد انشاء ال waves



func _on_spawn_timer_timeout() -> void:
	randomize()
	var enemy = preload("res://Enemy/enemy.tscn").instantiate()
	get_tree().root.add_child(enemy)
	var spwan_pos = randi_range(1,4)
	var spwan_node = get_node("Spawners/" + str(spwan_pos))
	enemy.global_position = spwan_node.global_position
