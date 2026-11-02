extends Node3D
class_name SiegeTrebuchet3D

@export var trebuchet_name: String = "Counterweight Trebuchet"
@export var fire_interval: float = 7.5
@export var launch_direction: Vector3 = Vector3(0.0, 0.0, -1.0) # Fires North toward Citadel by default

var _arm_pivot: Node3D = null
var _counterweight_pivot: Node3D = null
var _loaded_boulder: Node3D = null
var _active_projectile: Node3D = null
var _winch_wheel_l: Node3D = null
var _winch_wheel_r: Node3D = null
var _crew_anims: Array = []
var _winch_sfx_timer: float = 0.0

enum SiegeState { WINCHING, ARMED, FIRING, RECOIL }
var _state: SiegeState = SiegeState.WINCHING
var _timer: float = 0.0
var _proj_time: float = 0.0
var _proj_start: Vector3 = Vector3.ZERO
var _proj_vel: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("siege_trebuchet")
	add_to_group("interactable")
	_timer = randf_range(0.0, fire_interval * 0.5)
	_build_trebuchet_assembly()
	_build_interaction()

func _build_trebuchet_assembly() -> void:
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.34, 0.23, 0.14)
	wood_mat.roughness = 0.88

	var dark_iron_mat = StandardMaterial3D.new()
	dark_iron_mat.albedo_color = Color(0.18, 0.19, 0.21)
	dark_iron_mat.metallic = 0.65
	dark_iron_mat.roughness = 0.45

	# 1. Heavy Timber Base Frame (Sills & Crossbeams)
	for side_x in [-1.8, 1.8]:
		var sill = MeshInstance3D.new()
		var sill_mesh = BoxMesh.new()
		sill_mesh.size = Vector3(0.38, 0.38, 6.8)
		sill_mesh.material = wood_mat
		sill.mesh = sill_mesh
		sill.position = Vector3(side_x, 0.2, 0.0)
		add_child(sill)

	for cross_z in [-3.0, 0.0, 3.0]:
		var cross = MeshInstance3D.new()
		var cross_mesh = BoxMesh.new()
		cross_mesh.size = Vector3(4.2, 0.35, 0.38)
		cross_mesh.material = wood_mat
		cross.mesh = cross_mesh
		cross.position = Vector3(0.0, 0.25, cross_z)
		add_child(cross)

	# 2. Tall A-Frame Trestles supporting the Main Axle (Height 5.2m)
	for side_x in [-1.6, 1.6]:
		# Vertical main post
		var post = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(0.36, 5.2, 0.36)
		p_mesh.material = wood_mat
		post.mesh = p_mesh
		post.position = Vector3(side_x, 2.7, 0.0)
		add_child(post)

		# Front angled brace
		var brace_f = MeshInstance3D.new()
		var bf_mesh = BoxMesh.new()
		bf_mesh.size = Vector3(0.28, 5.4, 0.28)
		bf_mesh.material = wood_mat
		brace_f.mesh = bf_mesh
		brace_f.position = Vector3(side_x, 2.5, -1.4)
		brace_f.rotation_degrees.x = -28.0
		add_child(brace_f)

		# Rear angled brace
		var brace_b = MeshInstance3D.new()
		var bb_mesh = BoxMesh.new()
		bb_mesh.size = Vector3(0.28, 5.4, 0.28)
		bb_mesh.material = wood_mat
		brace_b.mesh = bb_mesh
		brace_b.position = Vector3(side_x, 2.5, 1.4)
		brace_b.rotation_degrees.x = 28.0
		add_child(brace_b)

	# 3. Iron Main Axle at Y = 5.0m
	var axle = MeshInstance3D.new()
	var ax_mesh = CylinderMesh.new()
	ax_mesh.top_radius = 0.18
	ax_mesh.bottom_radius = 0.18
	ax_mesh.height = 4.0
	ax_mesh.material = dark_iron_mat
	axle.mesh = ax_mesh
	axle.position = Vector3(0.0, 5.0, 0.0)
	axle.rotation_degrees.z = 90.0
	add_child(axle)

	# 4. Articulated Throwing Arm Pivot (Rotates around X at Y = 5.0m)
	_arm_pivot = Node3D.new()
	_arm_pivot.name = "ThrowingArmPivot"
	_arm_pivot.position = Vector3(0.0, 5.0, 0.0)
	add_child(_arm_pivot)

	# Long tapered throwing beam ( extends 1.8m forward to counterweight, 6.2m backward to sling )
	var beam = MeshInstance3D.new()
	var bm_mesh = BoxMesh.new()
	bm_mesh.size = Vector3(0.32, 0.34, 8.0)
	bm_mesh.material = wood_mat
	beam.mesh = bm_mesh
	beam.position = Vector3(0.0, 0.0, 2.1)
	_arm_pivot.add_child(beam)

	# 5. Swinging Heavy Counterweight Box (Hinged at short end of arm, Z = -1.6m)
	_counterweight_pivot = Node3D.new()
	_counterweight_pivot.name = "CounterweightPivot"
	_counterweight_pivot.position = Vector3(0.0, 0.0, -1.6)
	_arm_pivot.add_child(_counterweight_pivot)

	var cw_hanger = MeshInstance3D.new()
	var cwh_mesh = BoxMesh.new()
	cwh_mesh.size = Vector3(0.8, 1.6, 0.25)
	cwh_mesh.material = dark_iron_mat
	cw_hanger.mesh = cwh_mesh
	cw_hanger.position = Vector3(0.0, -0.8, 0.0)
	_counterweight_pivot.add_child(cw_hanger)

	var cw_box = MeshInstance3D.new()
	var cwb_mesh = BoxMesh.new()
	cwb_mesh.size = Vector3(1.5, 1.6, 1.4)
	cwb_mesh.material = wood_mat
	cw_box.mesh = cwb_mesh
	cw_box.position = Vector3(0.0, -1.9, 0.0)
	_counterweight_pivot.add_child(cw_box)

	# 6. Loaded Siege Boulder at Long Tip of Arm (Z = +5.8m)
	var boulder_scene = load("res://assets/overworld/projectile_catapult.gltf")
	if boulder_scene:
		_loaded_boulder = boulder_scene.instantiate()
		_loaded_boulder.scale = Vector3.ONE * 2.2
	else:
		_loaded_boulder = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.45
		(_loaded_boulder as MeshInstance3D).mesh = sp
	_loaded_boulder.position = Vector3(0.0, -0.4, 5.8)
	_arm_pivot.add_child(_loaded_boulder)

	# Ammunition Pile beside the Trebuchet
	if boulder_scene:
		for b_offset in [Vector3(2.8, 0.3, 1.5), Vector3(3.3, 0.3, 2.1), Vector3(2.6, 0.3, 2.4), Vector3(3.0, 0.8, 1.9)]:
			var ammo = boulder_scene.instantiate()
			ammo.scale = Vector3.ONE * 1.8
			ammo.position = b_offset
			add_child(ammo)

	# 7. Rotating Windlass Winch Wheels at Rear of Frame (Z = 2.8m)
	_winch_wheel_l = _create_winch_wheel(wood_mat, dark_iron_mat)
	_winch_wheel_l.position = Vector3(-1.95, 1.1, 2.8)
	add_child(_winch_wheel_l)

	_winch_wheel_r = _create_winch_wheel(wood_mat, dark_iron_mat)
	_winch_wheel_r.position = Vector3(1.95, 1.1, 2.8)
	add_child(_winch_wheel_r)

	# 8. Animated Siege Engineer Crew operating the Winch
	var crew_configs = [
		{"pos": Vector3(-2.5, 0.0, 2.8), "rot": 90.0, "model": "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf", "scale": Vector3.ONE * 0.38},
		{"pos": Vector3(2.5, 0.0, 2.8), "rot": -90.0, "model": "res://assets/characters/adventurers/Knight.glb", "scale": Vector3.ONE * 0.52}
	]
	for cc in crew_configs:
		var eng = AssetLoader.load_or_generate_model(cc["model"], "character", "Engineer")
		eng.scale = cc["scale"]
		eng.position = cc["pos"]
		eng.rotation_degrees.y = cc["rot"]
		add_child(eng)
		var ap = eng.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			_crew_anims.append(ap)
			_play_crew_anim(ap, "Interact")

	# Static Physics Collider
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4.2, 5.5, 6.8)
	col.shape = box
	col.position = Vector3(0.0, 2.75, 0.0)
	sb.add_child(col)
	add_child(sb)

	# Floating Label
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 6.6, 0.0)
	AssetLoader.style_world_label3d(lbl, "☄️ " + trebuchet_name + "\n[E] Fire Siege Volley", 38, Color(1.0, 0.82, 0.50))
	add_child(lbl)

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactables
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 4.5
	col.shape = sp
	col.position = Vector3(0.0, 1.5, 0.0)
	area.add_child(col)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Loose " + trebuchet_name

func interact(_player: Node = null) -> void:
	# Immediately trigger a dramatic launch when the player interacts
	_state = SiegeState.FIRING
	_timer = 0.0
	_launch_boulder()

func _process(delta: float) -> void:
	_timer += delta
	for ap in _crew_anims:
		if is_instance_valid(ap) and not ap.is_playing():
			_play_crew_anim(ap, "Cheer" if _state in [SiegeState.FIRING, SiegeState.RECOIL] else "Interact")

	match _state:
		SiegeState.WINCHING:
			# Winch the long throwing arm down toward the ground (angle from +60 deg down to -36 deg)
			var progress = clamp(_timer / 4.0, 0.0, 1.0)
			if _arm_pivot:
				_arm_pivot.rotation_degrees.x = lerp(60.0, -36.0, progress)
			if _counterweight_pivot:
				_counterweight_pivot.rotation_degrees.x = -_arm_pivot.rotation_degrees.x
			if _winch_wheel_l:
				_winch_wheel_l.rotation_degrees.x -= delta * 140.0
			if _winch_wheel_r:
				_winch_wheel_r.rotation_degrees.x -= delta * 140.0
			_winch_sfx_timer += delta
			if _winch_sfx_timer >= 0.95:
				_winch_sfx_timer = 0.0
				AudioManager.play_sfx_at_position("trebuchet_winch", global_position, 34.0, 0.08, -6.0)
			if _loaded_boulder:
				_loaded_boulder.visible = true
			if progress >= 1.0:
				_state = SiegeState.ARMED
				_timer = 0.0

		SiegeState.ARMED:
			# Hold tension briefly before releasing the trigger latch
			if _arm_pivot:
				_arm_pivot.rotation_degrees.x = -36.0 + sin(_timer * 18.0) * 0.6
			if _timer >= 1.2:
				_state = SiegeState.FIRING
				_timer = 0.0
				_launch_boulder()

		SiegeState.FIRING:
			# Counterweight plummets, whipping the long arm upward from -36 deg to +68 deg
			var whip_t = clamp(_timer / 0.38, 0.0, 1.0)
			var ease_t = whip_t * whip_t
			if _arm_pivot:
				_arm_pivot.rotation_degrees.x = lerp(-36.0, 68.0, ease_t)
			if _counterweight_pivot:
				_counterweight_pivot.rotation_degrees.x = -_arm_pivot.rotation_degrees.x
			if whip_t >= 1.0:
				_state = SiegeState.RECOIL
				_timer = 0.0

		SiegeState.RECOIL:
			# Settle arm oscillation before winching again
			if _arm_pivot:
				_arm_pivot.rotation_degrees.x = 60.0 + sin(_timer * 8.0) * exp(-_timer * 2.0) * 8.0
			if _counterweight_pivot:
				_counterweight_pivot.rotation_degrees.x = -_arm_pivot.rotation_degrees.x
			if _timer >= 2.2:
				_state = SiegeState.WINCHING
				_timer = 0.0
				for ap in _crew_anims:
					_play_crew_anim(ap, "Interact")

	# Update flying boulder ballistic trajectory
	if _active_projectile and is_instance_valid(_active_projectile):
		_proj_time += delta
		var p = _proj_start + _proj_vel * _proj_time + Vector3(0.0, -0.5 * 18.0 * _proj_time * _proj_time, 0.0)
		_active_projectile.global_position = p
		_active_projectile.rotation.x += delta * 6.0
		if p.y <= 0.2 and _proj_time > 0.3:
			var impact_pos = Vector3(p.x, 0.15, p.z)
			_spawn_impact_explosion(impact_pos)
			AudioManager.play_sfx_at_position("boulder_explosion", impact_pos, 48.0, 0.08, 0.0)
			_active_projectile.queue_free()
			_active_projectile = null

func _launch_boulder() -> void:
	if _loaded_boulder:
		_loaded_boulder.visible = false

	for ap in _crew_anims:
		_play_crew_anim(ap, "Cheer")
	AudioManager.play_sfx_at_position("trebuchet_launch", global_position, 42.0, 0.06, 0.0)

	if _active_projectile and is_instance_valid(_active_projectile):
		_active_projectile.queue_free()

	var boulder_scene = load("res://assets/overworld/projectile_catapult.gltf")
	if boulder_scene:
		_active_projectile = boulder_scene.instantiate()
		_active_projectile.scale = Vector3.ONE * 2.4
	else:
		_active_projectile = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.5
		(_active_projectile as MeshInstance3D).mesh = sp

	# Add fiery trail light to projectile
	var fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.45, 0.1)
	fire_light.light_energy = 2.5
	fire_light.omni_range = 7.0
	_active_projectile.add_child(fire_light)

	get_parent().add_child(_active_projectile)
	_proj_start = global_position + Vector3(0.0, 8.2, 0.0)
	_active_projectile.global_position = _proj_start
	var dir = -global_transform.basis.z.normalized()
	_proj_vel = dir * 24.0 + Vector3(0.0, 15.0, 0.0)
	_proj_time = 0.0

func _create_winch_wheel(wood_mat: Material, iron_mat: Material) -> Node3D:
	var root = Node3D.new()
	var rim = MeshInstance3D.new()
	var r_mesh = CylinderMesh.new()
	r_mesh.top_radius = 0.75
	r_mesh.bottom_radius = 0.75
	r_mesh.height = 0.16
	r_mesh.material = iron_mat
	rim.mesh = r_mesh
	rim.rotation_degrees.z = 90.0
	root.add_child(rim)

	for angle_deg in [0.0, 45.0, 90.0, 135.0]:
		var spoke = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.20, 1.75, 0.12)
		s_mesh.material = wood_mat
		spoke.mesh = s_mesh
		spoke.rotation_degrees.x = angle_deg
		root.add_child(spoke)
	return root

func _play_crew_anim(ap: AnimationPlayer, keyword: String) -> void:
	if not ap:
		return
	var anims = ap.get_animation_list()
	var chosen = ""
	for candidate in [keyword.to_lower(), "interact", "attack", "walking", "idle"]:
		for a in anims:
			if candidate in a.to_lower():
				chosen = a
				break
		if chosen != "":
			break
	if chosen == "" and anims.size() > 0:
		chosen = anims[0]
	if chosen != "":
		var res = ap.get_animation(chosen)
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
		ap.play(chosen, 0.15)

func _spawn_impact_explosion(pos: Vector3) -> void:
	if not get_parent():
		return
	var burst = CPUParticles3D.new()
	burst.position = pos
	burst.emitting = true
	burst.one_shot = true
	burst.amount = 28
	burst.lifetime = 0.65
	burst.explosiveness = 0.92
	burst.direction = Vector3(0.0, 1.0, 0.0)
	burst.spread = 68.0
	burst.initial_velocity_min = 4.5
	burst.initial_velocity_max = 9.5
	burst.gravity = Vector3(0.0, -14.0, 0.0)
	var m = SphereMesh.new()
	m.radius = 0.22
	m.height = 0.44
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.45, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.38, 0.08)
	mat.emission_energy_multiplier = 2.4
	m.material = mat
	burst.mesh = m
	get_parent().add_child(burst)
	get_tree().create_timer(0.8).timeout.connect(func(): if is_instance_valid(burst): burst.queue_free())
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if player and player.global_position.distance_to(pos) < 35.0:
		CombatJuice.add_trauma(0.18)
