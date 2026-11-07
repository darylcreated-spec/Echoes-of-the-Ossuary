extends Node3D
class_name ChoppableTree3D

@export var max_health: float = 60.0
@export var timber_reward: int = 2

var current_health: float = 60.0
var is_felled: bool = false
var _tree_mesh: Node3D = null
var _stump_mesh: Node3D = null
var _hit_count: int = 0

func _ready() -> void:
	add_to_group("destructible")
	add_to_group("damageable")
	add_to_group("hittable")
	add_to_group("choppable_tree")
	current_health = max_health

	# Look for child tree model
	for c in get_children():
		if c is Node3D and not (c is StaticBody3D or c is Area3D):
			_tree_mesh = c
			break

	_ensure_tree_collider()

func _ensure_tree_collider() -> void:
	var sb = find_child("TreeStaticBody", false, false) as StaticBody3D
	if not sb:
		sb = StaticBody3D.new()
		sb.name = "TreeStaticBody"
		sb.collision_layer = 1
		sb.collision_mask = 0
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 0.65
		cyl.height = 7.0
		col.shape = cyl
		col.position = Vector3(0.0, 3.5, 0.0)
		sb.add_child(col)
		add_child(sb)

	var hb = find_child("Hurtbox3D", false, false) as Area3D
	if not hb:
		hb = Area3D.new()
		hb.name = "Hurtbox3D"
		hb.collision_layer = 4 # Layer 3: Enemy / Object Hurtbox
		hb.collision_mask = 8 | 16
		var HurtboxScript = load("res://src/combat/Hurtbox3D.gd")
		if HurtboxScript:
			hb.set_script(HurtboxScript)
			hb.set("owner_character", self)
		var hb_col = CollisionShape3D.new()
		var hb_cyl = CylinderShape3D.new()
		hb_cyl.radius = 0.95
		hb_cyl.height = 7.2
		hb_col.shape = hb_cyl
		hb_col.position = Vector3(0.0, 3.5, 0.0)
		hb.add_child(hb_col)
		add_child(hb)

		if hb.has_signal("damage_received"):
			hb.damage_received.connect(func(amount: float, _kb: Vector3, _crit: bool, _source: Node3D):
				take_damage(amount, "melee", global_position + Vector3(0, 1.2, 0))
			)

func take_damage(amount: float, _source_type: String = "melee", hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_felled:
		return

	_hit_count += 1
	current_health = max(0.0, current_health - amount)

	var p = hit_point if hit_point != Vector3.ZERO else global_position + Vector3(0, 1.2, 0)
	CombatJuice.spawn_hit_spark(p, Color(0.85, 0.65, 0.35))
	CombatJuice.add_trauma(0.08)

	AudioManager.play_sfx_at_position("wood_chop", global_position, 32.0, 0.08, 0.0)

	# Wood chip particle burst
	_spawn_wood_chips(p)

	# Foliage shake
	_shake_tree()

	if current_health <= 0.0 or _hit_count >= 3:
		fell_tree()
	else:
		var remaining = 3 - _hit_count
		HUD.show_notification("🪓 Chopping Timber... (" + str(remaining) + " strikes remaining)")

func _shake_tree() -> void:
	if not _tree_mesh or not is_instance_valid(_tree_mesh):
		return
	var tw = create_tween()
	var r_angle = randf_range(-4.0, 4.0)
	tw.tween_property(_tree_mesh, "rotation_degrees:z", r_angle, 0.06)
	tw.tween_property(_tree_mesh, "rotation_degrees:z", -r_angle * 0.5, 0.08)
	tw.tween_property(_tree_mesh, "rotation_degrees:z", 0.0, 0.1)

func fell_tree() -> void:
	if is_felled:
		return
	is_felled = true

	# Timber snapping crack and fall thud
	AudioManager.play_sfx_at_position("wood_break", global_position, 45.0, 0.08, 2.0)
	CombatJuice.add_trauma(0.16)

	HUD.show_notification("🌲 TIMBER! Tree felled! +" + str(timber_reward) + " Lumber added to inventory.")

	# Add lumber to player materials
	var player = get_tree().get_first_node_in_group("player")
	if player and "collected_materials" in player:
		player.collected_materials["lumber"] = player.collected_materials.get("lumber", 0) + timber_reward

	# Remove static collider so player can walk through
	var sb = find_child("TreeStaticBody", false, false)
	if sb:
		sb.queue_free()

	# Replace base with a mossy tree stump
	_spawn_tree_stump()

	# Dramatic falling animation
	if _tree_mesh and is_instance_valid(_tree_mesh):
		var fall_dir_angle = randf_range(0.0, 360.0)
		var rad = deg_to_rad(fall_dir_angle)
		var target_rot = Vector3(cos(rad) * 88.0, 0.0, sin(rad) * 88.0)

		var tw = create_tween()
		tw.set_trans(Tween.TRANS_QUAD)
		tw.set_ease(Tween.EASE_IN)
		tw.tween_property(_tree_mesh, "rotation_degrees", target_rot, 1.4)
		tw.tween_callback(func():
			AudioManager.play_sfx_at_position("boulder_explosion", global_position + Vector3(sin(rad) * 4.0, 0.0, cos(rad) * 4.0), 38.0, 0.15, -6.0)
			_spawn_dust_burst(global_position + Vector3(sin(rad) * 4.0, 0.0, cos(rad) * 4.0))
		)
		# Fade away trunk after resting on ground
		tw.tween_interval(3.5)
		tw.tween_property(_tree_mesh, "scale", Vector3.ZERO, 1.2)
		tw.tween_callback(Callable(_tree_mesh, "queue_free"))

func _spawn_tree_stump() -> void:
	var stump = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.52
	cyl.bottom_radius = 0.60
	cyl.height = 0.45
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.25, 0.15)
	mat.roughness = 0.94
	stump.mesh = cyl
	stump.material_override = mat
	stump.position = Vector3(0.0, 0.22, 0.0)
	add_child(stump)

func _spawn_wood_chips(pos: Vector3) -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		return
	var chips = CPUParticles3D.new()
	chips.position = pos
	chips.one_shot = true
	chips.explosiveness = 0.9
	chips.amount = 12
	chips.lifetime = 0.5
	chips.direction = Vector3.UP
	chips.spread = 75.0
	chips.initial_velocity_min = 2.0
	chips.initial_velocity_max = 4.0
	chips.gravity = Vector3(0.0, -9.0, 0.0)
	chips.color = Color(0.85, 0.68, 0.40)
	var qm = QuadMesh.new()
	qm.size = Vector2(0.18, 0.18)
	chips.mesh = qm
	parent_scene.add_child(chips)
	chips.emitting = true
	var c_wr = weakref(chips)
	get_tree().create_timer(0.8).timeout.connect(func():
		var c = c_wr.get_ref()
		if c: c.queue_free()
	)

func _spawn_dust_burst(pos: Vector3) -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		return
	var dust = CPUParticles3D.new()
	dust.position = pos
	dust.one_shot = true
	dust.explosiveness = 0.95
	dust.amount = 16
	dust.lifetime = 0.8
	dust.direction = Vector3.UP
	dust.spread = 85.0
	dust.initial_velocity_min = 2.5
	dust.initial_velocity_max = 5.0
	dust.gravity = Vector3(0.0, -3.0, 0.0)
	dust.scale_amount_min = 0.6
	dust.scale_amount_max = 1.6
	dust.color = Color(0.45, 0.55, 0.35, 0.6)
	var qm = QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var d_tex = load("res://assets/particles/dirt_01.png")
	if d_tex:
		mat.albedo_texture = d_tex
	qm.material = mat
	dust.mesh = qm
	parent_scene.add_child(dust)
	dust.emitting = true
	var d_wr = weakref(dust)
	get_tree().create_timer(1.2).timeout.connect(func():
		var d = d_wr.get_ref()
		if d: d.queue_free()
	)
