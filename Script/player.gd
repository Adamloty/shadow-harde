extends CharacterBody3D

var damage = 10
var speed  # السرعة الحالية للاعب (بتتغير بين مشي وركض)

@export var WALK_SPEED = 5.0 
@export var SPRINT_SPEED = 8.0  # سرعة الركض (سبرينت)
@export var JUMP_VELOCITY = 4.8  # قوة القفزة
@export var SENSITIVITY = 0.003  # حساسية الماوس

var lr_power = 3  # قوة اهتزاز الرأس يمين وشمال

# متغيرات الهيد بوب
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var t_bob = 0.0

# تغيير زاوية الرؤية FOV
@export var BASE_FOV = 75.0
@export var FOV_CHANGE = 1.5

# الجاذبية
@export var gravity = 9.8

# العقد الجاهزة
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var anim_player = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

# الطلقات
var bullet = load("res://Scene/bullet.tscn")
@onready var pos = $Head/Camera3D/hand/Gun/pos_gun

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func fire():
	if Input.is_action_pressed("fire"):
		var instance = bullet.instantiate()
		instance.position = pos.global_position
		instance.transform.basis = pos.global_transform.basis
		get_parent().add_child(instance)

		if anim_player.is_playing():
			pass  # ممكن تحط راي كاست هنا لو عايز

		animation_tree.get("parameters/playback").travel("Fire attack")
	else:
		animation_tree.get("parameters/playback").travel("Idle")

	if Input.is_action_pressed("aim"):
		animation_tree.get("parameters/playback").travel("Aim")
	elif Input.is_action_just_released("aim"):
		animation_tree.get("parameters/playback").travel("CloseAim")
	else:
		anim_player.stop()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	Global.target = global_position
	fire()

	# الجاذبية
	if not is_on_floor():
		velocity.y -= gravity * delta

	# القفز
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# تغيير السرعة بين المشي والركض
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# الاتجاه
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# الحركة
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# الهيد بوب
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# تعديل الفيو حسب السرعة
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# اهتزاز الرأس يمين وشمال
	if input_dir.x != 0:
		head.rotation.z = lerp(head.rotation.z, (lr_power * delta) * -Input.get_axis("left", "right"), 0.05)
	else:
		head.rotation.z = lerp(head.rotation.z, 0.0, 0.05)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
