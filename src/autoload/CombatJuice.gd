extends Node

# Screen Shake Variables
var active_camera: Camera3D = null
var _trauma: float = 0.0
var _trauma_power: float = 2.0
var _max_offset: Vector3 = Vector3(0.5, 0.3, 0.5)
var _max_roll: float = 0.06
var _trauma_decay: float = 2.2
var _base_cam_rot: Vector3 = Vector3.ZERO
var _noise_y: float = 0.0

# Hit-stop / Freeze Frame
var _is_frozen: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_camera(cam: Camera3D) -> void:
	active_camera = cam
	if active_camera:
		_base_cam_rot = active_camera.rotation

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = max(_trauma - _trauma_decay * delta, 0.0)
		_apply_shake(delta)

func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)

func _apply_shake(delta: float) -> void:
	if not active_camera:
		return
	_noise_y += delta * 45.0
	var shake: float = pow(_trauma, _trauma_power)
	var offset_x: float = _max_offset.x * shake * sin(_noise_y * 1.3)
	var offset_y: float = _max_offset.y * shake * cos(_noise_y * 1.7)
	var offset_z: float = _max_offset.z * shake * sin(_noise_y * 0.9)
	var roll: float = _max_roll * shake * sin(_noise_y * 2.1)
	
	active_camera.h_offset = offset_x
	active_camera.v_offset = offset_y
	active_camera.rotation.z = _base_cam_rot.z + roll

# --- HIT-STOP / FREEZE FRAME ---
func freeze_frame(duration: float = 0.05, time_scale: float = 0.08) -> void:
	if _is_frozen:
		return
	_is_frozen = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0
	_is_frozen = false

# --- FLOATING DAMAGE NUMBERS ---
func spawn_damage_number(pos: Vector3, amount: float, is_crit: bool, is_player_damage: bool, is_heal: bool = false) -> void:
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.double_sided = true
	label.font_size = 40 if is_crit else 28
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.position = pos + Vector3(randf_range(-0.3, 0.3), 1.5 + randf_range(0.0, 0.4), randf_range(-0.3, 0.3))
	
	if is_heal:
		label.text = "+" + str(int(amount))
		label.modulate = Color(0.2, 0.95, 0.3, 1.0)
	elif is_player_damage:
		label.text = "-" + str(int(amount))
		label.modulate = Color(1.0, 0.25, 0.25, 1.0)
	else:
		label.text = str(int(amount)) + ("!" if is_crit else "")
		if is_crit:
			label.modulate = Color(1.0, 0.8, 0.1, 1.0)
		else:
			label.modulate = Color(1.0, 0.95, 0.85, 1.0)

	get_tree().current_scene.add_child(label)

	# Animate float and fade
	var tween = label.create_tween()
	var target_pos = label.position + Vector3(0, 1.4, 0)
	tween.set_parallel(true)
	tween.tween_property(label, "position", target_pos, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector3(1.3, 1.3, 1.3) if is_crit else Vector3(1.1, 1.1, 1.1), 0.15)
	tween.chain().tween_property(label, "scale", Vector3(0.8, 0.8, 0.8), 0.4)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.1)
	tween.chain().tween_callback(label.queue_free)

# --- IMPACT SPARKS & PARTICLES ---
func spawn_hit_spark(pos: Vector3, color: Color = Color(1.0, 0.85, 0.3)) -> void:
	var particles = CPUParticles3D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.amount = 14
	particles.lifetime = 0.35
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.08)
	mesh.material = mat
	particles.mesh = mesh
	
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 8.0
	particles.gravity = Vector3(0, -18.0, 0)
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.3
	
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(0.45).timeout.connect(particles.queue_free)

# --- BONE BURST ON SKELETON DEATH ---
func spawn_bone_burst(pos: Vector3, count: int = 16) -> void:
	var particles = CPUParticles3D.new()
	particles.position = pos + Vector3(0, 0.8, 0)
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = count
	particles.lifetime = 0.75
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.85, 0.76)
	mat.roughness = 0.8
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.12, 0.18, 0.12)
	mesh.material = mat
	particles.mesh = mesh
	
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 3.5
	particles.initial_velocity_max = 9.0
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.gravity = Vector3(0, -22.0, 0)
	
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(0.85).timeout.connect(particles.queue_free)
