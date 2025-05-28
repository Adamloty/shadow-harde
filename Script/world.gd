extends Node3D

@onready var spawn_timer: Timer = $"Spawn-Timer"    #سيتم تغيير حاصية ال wait time بعد انشاء ال waves
var sec = 0
var min = 0
@onready var time: Label = $Time


func _physics_process(delta: float) -> void:
	time.text = str(min) + ":"+ str(sec)
	if sec == 60:
		sec = 0
		min += 1
func _on_spawn_timer_timeout() -> void:
	randomize()
	var enemy = preload("res://Enemy/enemy.tscn").instantiate()
	get_tree().root.add_child(enemy)
	var spwan_pos = randi_range(1,4)
	var spwan_node = get_node("Spawners/" + str(spwan_pos))
	enemy.global_position = spwan_node.global_position


func _on_timer_timeout() -> void:
	sec += 1
