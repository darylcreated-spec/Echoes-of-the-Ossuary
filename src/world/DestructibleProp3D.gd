extends Node3D
class_name DestructibleProp3D

enum PropType {
	WOODEN_BARREL,
	CARGO_CRATE,
	WOODEN_FENCE,
	SIEGE_BARRICADE,
	STONE_WALL,
	WEAPON_RACK
}

@export var prop_type: PropType = PropType.WOODEN_BARREL
@export var max_health: float = 25.0
@export var drop_loot: String = "random" # "random", "gold", "bread", "arrows", "lumber", "none"
@export var visual_node: Node3D = null
@export var collider_size: Vector3 = Vector3(1.2, 1.4, 1.2)

var current_health: float = 25.0
var is_destroyed: bool = false
var _initial_visual_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	add_to_group("destructible")
	add_to_group("damageable")
	add_to_group("hittable")
	current_health = max_health

	# If visual_node wasn't assigned in editor, find first child MeshInstance3D or Node3D
	if not visual_node:
		for c in get_children():
			if c is MeshInstance3D or (c is Node3D and not (c is StaticBody3D or c is Area3D)):
				visual_node = c
				break
	if visual_node:
		_initial_visual_scale = visual_node.scale

	_ensure_physics_collider()

func _ensure_physics_collider() -> void:
	# Add static collider so player and pathfinding collide with the prop
	var sb = find_child("PropStaticBody", false, false) as StaticBody3D
	if not sb:
		sb = StaticBody3D.new()
		sb.name = "PropStaticBody"
		sb.collision_layer = 1 # Layer 1: World
		sb.collision_mask = 0
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = collider_size
		col.shape = box
		col.position = Vector3(0.0, collider_size.y * 0.5, 0.0)
		sb.add_child(col)
		add_child(sb)

	# Add standard Hurtbox3D so player melee, projectiles, and explosions damage it
	var hb = find_child("Hurtbox3D", false, false) as Area3D
	if not hb:
		hb = Area3D.new()
		hb.name = "Hurtbox3D"
		hb.collision_layer = 4 # Layer 3: Enemy / Object Hurtbox
		hb.collision_mask = 8 | 16 # Layer 4: Player Hitbox & Projectiles
		var HurtboxScript = load("res://src/combat/Hurtbox3D.gd")
		if HurtboxScript:
			hb.set_script(HurtboxScript)
			hb.set("owner_character", self)
		var hb_col = CollisionShape3D.new()
		var hb_box = BoxShape3D.new()
		hb_box.size = collider_size * 1.15
		hb_col.shape = hb_box
		hb_col.position = Vector3(0.0, collider_size.y * 0.5, 0.0)
		hb.add_child(hb_col)
		add_child(hb)

		if hb.has_signal("damage_received"):
			hb.damage_received.connect(func(amount: float, _kb: Vector3, _crit: bool, _source: Node3D):
				take_damage(amount, "combat", global_position + Vector3(0, collider_size.y * 0.5, 0))
			)

func take_damage(amount: float, source_type: String = "melee", hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_destroyed:
		return

	current_health = max(0.0, current_health - amount)
	var p = hit_point if hit_point != Vector3.ZERO else global_position + Vector3(0, 0.6, 0)
	
	var is_wood = prop_type != PropType.STONE_WALL
	var spark_color = Color(0.85, 0.65, 0.35) if is_wood else Color(0.95, 0.85, 0.55)
	CombatJuice.spawn_hit_spark(p, spark_color)
	CombatJuice.add_trauma(0.06)

	_play_wobble_reaction()

	if is_wood:
		AudioManager.play_sfx_at_position("wood_chop", global_position, 28.0, 0.12, -4.0)
	else:
		AudioManager.play_sfx_at_position("anvil_strike", global_position, 28.0, 0.12, -6.0)

	if current_health <= 0.0:
		destroy(hit_point)

func _play_wobble_reaction() -> void:
	if not visual_node or not is_instance_valid(visual_node):
		return
	var tw = create_tween()
	tw.tween_property(visual_node, "scale", _initial_visual_scale * Vector3(1.15, 0.85, 1.15), 0.06)
	tw.tween_property(visual_node, "scale", _initial_visual_scale, 0.12)

func destroy(hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_destroyed:
		return
	is_destroyed = true

	var p = hit_point if hit_point != Vector3.ZERO else global_position + Vector3(0, 0.5, 0)
	var is_wood = prop_type != PropType.STONE_WALL

	# Sound effect
	var sfx_name = "wood_break" if is_wood else "stone_break"
	AudioManager.play_sfx_at_position(sfx_name, global_position, 40.0, 0.1, 0.0)

	# Impact camera shake & hitstop
	CombatJuice.add_trauma(0.14)

	# Spawn flying debris physics shards
	_spawn_debris_shards(p, is_wood)

	# Spawn dust / splinter explosion particles
	_spawn_dust_cloud(p, is_wood)

	# Loot drops (Gold, bread, arrows, lumber)
	_spawn_loot(p)

	queue_free()

func _spawn_debris_shards(center_pos: Vector3, is_wood: bool) -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		return

	var shard_count = 5 if is_wood else 6
	var mat = StandardMaterial3D.new()
	if is_wood:
		mat.albedo_color = Color(0.42, 0.28, 0.16)
		mat.roughness = 0.90
	else:
		mat.albedo_color = Color(0.45, 0.44, 0.42)
		mat.roughness = 0.92

	for i in range(shard_count):
		var rb = RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = 1 # Collide with ground floor only
		rb.position = center_pos + Vector3(randf_range(-0.35, 0.35), randf_range(0.1, 0.4), randf_range(-0.35, 0.35))

		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new()
		if is_wood:
			bm.size = Vector3(randf_range(0.15, 0.35), randf_range(0.08, 0.16), randf_range(0.35, 0.65))
		else:
			bm.size = Vector3(randf_range(0.20, 0.42), randf_range(0.18, 0.38), randf_range(0.20, 0.42))
		bm.material = mat
		mi.mesh = bm
		rb.add_child(mi)

		var col = CollisionShape3D.new()
		var cs = BoxShape3D.new()
		cs.size = bm.size
		col.shape = cs
		rb.add_child(col)

		parent_scene.add_child(rb)

		# Random burst impulse
		var dir = Vector3(randf_range(-1.0, 1.0), randf_range(0.8, 2.2), randf_range(-1.0, 1.0)).normalized()
		rb.linear_velocity = dir * randf_range(4.5, 9.5)
		rb.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))

		# Fade out and clean up after 2.8s
		var tw = rb.create_tween()
		tw.tween_interval(1.8)
		tw.tween_property(mi, "scale", Vector3.ZERO, 0.8)
		tw.tween_callback(Callable(rb, "queue_free"))

func _spawn_dust_cloud(pos: Vector3, is_wood: bool) -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		return

	var dust = CPUParticles3D.new()
	dust.position = pos
	dust.one_shot = true
	dust.explosiveness = 0.92
	dust.amount = 14
	dust.lifetime = 0.65
	dust.direction = Vector3.UP
	dust.spread = 80.0
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 4.5
	dust.gravity = Vector3(0.0, -3.5, 0.0)
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.3
	dust.color = Color(0.65, 0.55, 0.42, 0.65) if is_wood else Color(0.60, 0.60, 0.60, 0.65)

	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	d_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var d_tex = load("res://assets/particles/dirt_01.png")
	if d_tex:
		d_mat.albedo_texture = d_tex
	var qm = QuadMesh.new()
	qm.size = Vector2(0.85, 0.85)
	qm.material = d_mat
	dust.mesh = qm

	parent_scene.add_child(dust)
	dust.emitting = true
	var d_wr = weakref(dust)
	get_tree().create_timer(1.0).timeout.connect(func():
		var d = d_wr.get_ref()
		if d: d.queue_free()
	)

func _spawn_loot(pos: Vector3) -> void:
	if drop_loot == "none":
		return

	var chosen = drop_loot
	if chosen == "random":
		var roll = randf()
		if roll < 0.45:
			chosen = "gold"
		elif roll < 0.75:
			chosen = "bread"
		elif roll < 0.90:
			chosen = "arrows"
		else:
			chosen = "lumber"

	match chosen:
		"gold":
			var gold_val = randi_range(3, 12)
			GameManager.add_gold(gold_val)
			HUD.show_notification("💰 Found " + str(gold_val) + " Gold inside broken container!")
			AudioManager.play_sfx("gold_pickup", 0.08, 0.0)
		"bread":
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal"):
				player.heal(18.0)
				HUD.show_notification("🥖 Found Fresh Bread! Restored 18 HP.")
		"arrows":
			HUD.show_notification("🏹 Recovered +6 Bodkin Arrows!")
		"lumber":
			var player = get_tree().get_first_node_in_group("player")
			if player and "collected_materials" in player:
				player.collected_materials["lumber"] = player.collected_materials.get("lumber", 0) + 1
				HUD.show_notification("🪵 Salvaged +1 Sturdy Timber Plank!")
