extends CharacterBody3D

var damage = 10
var speed  # السرعة الحالية للاعب (بتتغير بين مشي وركض)
@export var WALK_SPEED = 5.0 
@export var SPRINT_SPEED = 8.0  # سرعة الركض (سبرينت)
@export var JUMP_VELOCITY = 4.8  # قوة القفزة (السرعة اللي بتندفع بيها لفوق)
@export var SENSITIVITY = 0.003  # حساسية الماوس عشان نتحكم في الدوران
var lr_power = 3 #قوة اهتزاز الشاشه يمينا ويسارا عند تحرك الاعب لليمين او اليسار
# متغيرات الحركة الرأسية اللي بتعمل تأثير الـ head bob
@export var BOB_FREQ = 2.4  # تردد حركة الهيد بوب (قد إيه بيهتز بسرعة)
@export var BOB_AMP = 0.08  # مدى حركة الهيد بوب (شدة الهز)
@export var t_bob = 0.0  # المؤقت اللي بيزيد عشان نحسب حركة الهيد بوب بتاعت الوقت الحالي

# متغيرات لتغيير زاوية الرؤية (FOV)
@export var BASE_FOV = 75.0  # زاوية الرؤية الأساسية للكاميرا
@export var FOV_CHANGE = 1.5  # مقدار التغيير في زاوية الرؤية لما تركض (بتزود الفيو علشان تحس بالسرعة)

# جاذبية اللعبة من إعدادات المشروع (عشان تكون متزامنة مع باقي الفيزياء)
@export var gravity = 9.8

@onready var head = $Head # الوصول لعقدة الرأس (head) في المشهد
@onready var camera = $Head/Camera3D  # الوصول لكاميرا الرأس عشان نقدر نتحكم فيها (الدوران، الهد بوب، الفيو)
@onready var anim_player = $AnimationPlayer
@onready var raycast = $Head/Camera3D/RayCast3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # لما اللعبة تبدأ، نخلي الماوس متحكم فيه ومخفي (مهم للحركة السلسة)
func fire():
	if Input.is_action_pressed("fire"):
		if not anim_player.is_playing():
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if target.is_in_group("enemy"):
					target.health -= damage

		anim_player.play("Fire attack")
	else:
		anim_player.stop()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# لما تحرك الماوس، ندور الرأس حوالين المحور الرأسي (Y) والكميرا حوالين المحور الأفقي (X)
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		# نحدد حد للدوران لأعلى ولأسفل عشان ما تدورش كاميرا 360 درجة (مفيش إحساس حقيقي بالرأس بيتلف)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	Global.target = global_position
	fire()
	# نضيف تأثير الجاذبية على اللاعب لما يكون مش على الأرض (يبقى في الهواء)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# لو ضغطت على زر القفز وكنت على الأرض، ندي للاعب دفعة لفوق (قفزة)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# لو بتضغط على زر الركض، سرعة اللاعب تزيد
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# ناخد اتجاه الحركة من لوحة المفاتيح (يمين، شمال، لقدام، لورا)
	var input_dir = Input.get_vector("left", "right", "up", "down")
	# نحول اتجاه الحركة من فضاء اللاعب (local) لعالم اللعبة (global) مع مراعاة اتجاه الرأس والجسم
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			# لو في اتجاه، نحرك اللاعب بسرعة ثابتة
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# لو مفيش اتجاه (واقف)، نبطئ الحركة تدريجيًا (تسارع وتهدئة سلسة)
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# لما تكون في الهواء الحركة تكون أقل سلاسة، عشان مش على الأرض
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# حساب تأثير حركة الرأس (head bob) بناء على سرعة اللاعب وهل هو على الأرض ولا لا
	t_bob += delta * velocity.length() * float(is_on_floor())
	# بنغير موقع الكاميرا بناءً على الهد بوب عشان الإحساس بالحركة يكون طبيعي أكتر
	camera.transform.origin = _headbob(t_bob)
	
	# تعديل زاوية رؤية الكاميرا حسب السرعة (الفيو بيتوسع لو ركضت عشان تحس بالسرعة)
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	
	if input_dir.x != 0:
		head.rotation.z = lerp(head.rotation.z , (lr_power * delta) * -Input.get_axis("left" , "right") , 0.05)
	else:
		head.rotation.z = lerp(head.rotation.z , 0.0, 0.05)
	
	
	
	# ننفذ حركة اللاعب مع الاصطدامات والفيزياء
	move_and_slide()

func _headbob(time) -> Vector3:
	# بنحسب ازاحة بسيطة في مكان الكاميرا عشان نعمل حركة اهتزاز (هيد بوب)
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP  # اهتزاز طولي في الارتفاع
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP # اهتزاز جانبي خفيف
	return pos
