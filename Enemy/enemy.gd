extends CharacterBody3D

var health = 100
var gravity = 9.8
@export var speed : int = 30
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var hp_bar: ProgressBar = $SubViewport/Hp/ProgressBar



func _process(delta: float) -> void:
	hp_bar.value = health
	if health <= 0:
		queue_free()
func _physics_process(delta: float) -> void:
	nav.target_position = Global.target
	var direction = (nav.target_position - global_position) * (speed * delta)
	velocity.y -= gravity * delta
	velocity.x = direction.x
	velocity.z = direction.z
	move_and_slide()
