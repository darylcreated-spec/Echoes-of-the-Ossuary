extends Node3D
class_name EnemyShipAI3D

@export var ship_name: String = "Crimson Corsair Cog"
@export var max_health: float = 220.0
@export var cruise_speed: float = 2.8
@export var battle_speed: float = 4.2
@export var patrol_waypoints: Array = []

enum ShipAIState { PATROL, CHASE, BROADSIDE, RAMMING, SINKING }
var current_state: ShipAIState = ShipAIState.PATROL

var current_health: float = 220.0
var is_sunk: bool = false
var _reload_timer: float = 0.0
var _current_wp_idx: int = 0
var _target_player_ship: Node3D = null
var _hull_pivot: Node3D = null
var _mast_node: Node3D = null
var _hp_label: Label3D = null
var _sinking_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy_ship")
	add_to_group("enemies")
	add_to_group("naval_target")
	add_to_group("destructible")
	current_health = max_health

	if patrol_waypoints.is_empty():
		patrol_waypoints = [
			global_position,
			global_position + Vector3(-45.0, 0.0, 35.0),
			global_position + Vector3(-25.0, 0.0, 65.0),
			global_position + Vector3(20.0, 0.0, 30.0)
		]

	_build_pirate_ship_visuals()
	_build_ui_and_collider()

func _build_pirate_ship_visuals() -> void:
	_hull_pivot = Node3D.new()
	_hull_pivot.name = "HullPivot"
	add_child(_hull_pivot)

	# 1. Dark Timber Pirate Hull
	var wood_dark = StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.22, 0.16, 0.12)
	wood_dark.roughness = 0.88

	var hull = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(4.8, 2.4, 13.5)
	hm.material = wood_dark
	hull.mesh = hm
	hull.position = Vector3(0.0, 1.2, 0.0)
	_hull_pivot.add_child(hull)

	# Bow & Stern sheer blocks
	var bow = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(4.2, 2.8, 4.0)
	bm.material = wood_dark
	bow.mesh = bm
	bow.position = Vector3(0.0, 1.6, -7.0)
	_hull_pivot.add_child(bow)

	# 2. Mainmast & Black/Crimson Jolly Roger Sail
	_mast_node = Node3D.new()
	_mast_node.name = "Mainmast"
	_hull_pivot.add_child(_mast_node)

	var mast = MeshInstance3D.new()
	var mm = CylinderMesh.new()
	mm.top_radius = 0.16
	mm.bottom_radius = 0.22
	mm.height = 9.5
	mm.material = wood_dark
	mast.mesh = mm
	mast.position = Vector3(0.0, 5.2, -0.5)
	_mast_node.add_child(mast)

	# Square Rigged Black Pirate Sail
	var sail_mat = StandardMaterial3D.new()
	sail_mat.albedo_color = Color(0.12, 0.11, 0.13)
	sail_mat.roughness = 0.95
	var sail = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(6.5, 5.0, 0.12)
	sm.material = sail_mat
	sail.mesh = sm
	sail.position = Vector3(0.0, 6.0, -0.45)
	_mast_node.add_child(sail)

	# Crimson Cross / Skull Insignia on Sail
	var skull_lbl = Label3D.new()
	skull_lbl.text = "☠️"
	skull_lbl.font_size = 96
	skull_lbl.position = Vector3(0.0, 6.0, -0.38)
	skull_lbl.double_sided = true
	_mast_node.add_child(skull_lbl)

	# 3. Bronze Ram Prow at waterline
	var ram = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(1.4, 0.8, 2.5)
	var bronze = StandardMaterial3D.new()
	bronze.albedo_color = Color(0.72, 0.48, 0.22)
	bronze.metallic = 0.8
	ram.mesh = rm
	ram.material_override = bronze
	ram.position = Vector3(0.0, 0.4, -9.0)
	_hull_pivot.add_child(ram)

func _build_ui_and_collider() -> void:
	# Static / Area collider for cannonball & ram hits
	var sb = StaticBody3D.new()
	sb.collision_layer = 1 | (1 << 2) # World & Enemy Hurtbox
	sb.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(5.5, 4.0, 15.0)
	col.shape = box
	col.position = Vector3(0.0, 2.0, 0.0)
	sb.add_child(col)
	add_child(sb)

	# Overhead Naval Health & Faction Label
	_hp_label = Label3D.new()
	_hp_label.position = Vector3(0.0, 11.0, 0.0)
	_hp_label.font_size = 32
	_hp_label.outline_size = 8
	_hp_label.outline_modulate = Color(0.1, 0.05, 0.05, 0.95)
	_hp_label.modulate = Color(1.0, 0.45, 0.45)
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.double_sided = true
	_update_hp_display()
	add_child(_hp_label)

func _update_hp_display() -> void:
	if not _hp_label:
		return
	var pct = int(clamp(current_health / max_health, 0.0, 1.0) * 100.0)
	_hp_label.text = "🏴‍☠️ " + ship_name + "\nHull: " + str(int(current_health)) + " / " + str(int(max_health)) + " HP (" + str(pct) + "%)"

func _process(delta: float) -> void:
	if is_sunk:
		_process_sinking(delta)
		return

	# Wave buoyancy rocking
	var time = Time.get_ticks_msec() / 1000.0
	if _hull_pivot:
		_hull_pivot.rotation_degrees.z = sin(time * 1.8 + global_position.x) * 2.8
		_hull_pivot.rotation_degrees.x = cos(time * 1.4 + global_position.z) * 1.8

	_reload_timer = max(0.0, _reload_timer - delta)

	# Find player warship in the ocean theater
	_find_player_ship()

	match current_state:
		ShipAIState.PATROL:
			_process_patrol(delta)
			if _target_player_ship and is_instance_valid(_target_player_ship):
				if global_position.distance_to(_target_player_ship.global_position) < 65.0:
					current_state = ShipAIState.CHASE

		ShipAIState.CHASE:
			_process_combat_maneuver(delta)

func _find_player_ship() -> void:
	var ships = get_tree().get_nodes_in_group("ship")
	for s in ships:
		if is_instance_valid(s) and s != self and s.get("is_captained") == true:
			_target_player_ship = s
			return
	# Also allow tracking unmounted player swimming/skiff
	if not _target_player_ship:
		var p = get_tree().get_first_node_in_group("player") as Node3D
		if p and p.global_position.x < -55.0 and p.global_position.z > 45.0:
			_target_player_ship = p

func _process_patrol(delta: float) -> void:
	if patrol_waypoints.is_empty():
		return
	var target = patrol_waypoints[_current_wp_idx]
	var diff = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if diff.length() < 5.0:
		_current_wp_idx = (_current_wp_idx + 1) % patrol_waypoints.size()
		return

	var fwd = -global_transform.basis.z.normalized()
	var desired = diff.normalized()
	var next_fwd = fwd.slerp(desired, delta * 0.8)
	var look_target = global_position + next_fwd
	if not look_target.is_equal_approx(global_position):
		look_at(look_target, Vector3.UP)

	global_position += fwd * cruise_speed * delta

func _process_combat_maneuver(delta: float) -> void:
	if not _target_player_ship or not is_instance_valid(_target_player_ship):
		current_state = ShipAIState.PATROL
		return

	var dist = global_position.distance_to(_target_player_ship.global_position)
	if dist > 85.0:
		current_state = ShipAIState.PATROL
		return

	var diff = Vector3(_target_player_ship.global_position.x - global_position.x, 0.0, _target_player_ship.global_position.z - global_position.z)
	var dir_to_player = diff.normalized()

	# If within 18m, ramming charge!
	if dist < 18.0:
		var fwd = -global_transform.basis.z.normalized()
		var look_target = global_position + fwd.slerp(dir_to_player, delta * 1.5)
		look_at(look_target, Vector3.UP)
		global_position += fwd * battle_speed * 1.25 * delta

		if dist < 8.0 and _reload_timer <= 0.0:
			_ram_target()
		return

	# Broadside positioning: steer parallel/perpendicular to player
	var broadside_dir = dir_to_player.rotated(Vector3.UP, deg_to_rad(90.0))
	var fwd = -global_transform.basis.z.normalized()
	var look_target = global_position + fwd.slerp(broadside_dir, delta * 1.2)
	look_at(look_target, Vector3.UP)
	global_position += fwd * battle_speed * delta

	# Fire broadside cannons when aligned and reloaded
	if _reload_timer <= 0.0 and dist < 55.0:
		_fire_broadside()

func _fire_broadside() -> void:
	_reload_timer = 4.0
	AudioManager.play_sfx_at_position("naval_cannon", global_position + Vector3(0, 2, 0), 65.0, 0.1, 0.0)
	CombatJuice.add_trauma(0.12)

	# Fire from broadside side facing target
	var side_dir = global_transform.basis.x.normalized()
	if _target_player_ship:
		var to_p = (_target_player_ship.global_position - global_position).normalized()
		if side_dir.dot(to_p) < 0.0:
			side_dir = -side_dir

	for i in [-3.5, 0.0, 3.5]:
		var muzzle = global_position + Vector3(0, 1.8, 0) + global_transform.basis.z * i + side_dir * 2.8
		_spawn_cannonball(muzzle, side_dir)

func _spawn_cannonball(start_pos: Vector3, shoot_dir: Vector3) -> void:
	CombatJuice.spawn_hit_spark(start_pos, Color(1.0, 0.7, 0.2))

	var ball = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.28
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.15)
	mat.metallic = 0.9
	sp.material = mat
	ball.mesh = sp
	get_parent().add_child(ball)
	ball.global_position = start_pos

	var target_dest = start_pos + shoot_dir * randf_range(25.0, 45.0)
	if _target_player_ship and is_instance_valid(_target_player_ship):
		target_dest = _target_player_ship.global_position + Vector3(randf_range(-2.0, 2.0), randf_range(0.2, 1.5), randf_range(-2.0, 2.0))

	var fly_time = 0.75
	var tw = ball.create_tween()
	tw.tween_property(ball, "global_position:x", target_dest.x, fly_time)
	tw.parallel().tween_property(ball, "global_position:z", target_dest.z, fly_time)
	tw.tween_property(ball, "global_position:y", target_dest.y + 2.0, fly_time * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(ball, "global_position:y", target_dest.y, fly_time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if is_instance_valid(ball):
			ball.queue_free()
		AudioManager.play_sfx_at_position("boulder_explosion", target_dest, 45.0, 0.1, -4.0)
		CombatJuice.spawn_hit_spark(target_dest, Color(1.0, 0.6, 0.2))
		if _target_player_ship and is_instance_valid(_target_player_ship):
			if _target_player_ship.has_method("take_ship_damage"):
				_target_player_ship.take_ship_damage(35.0)
			elif _target_player_ship.has_method("take_damage"):
				_target_player_ship.take_damage(25.0, Vector3.ZERO, false, self)
	)

func _ram_target() -> void:
	_reload_timer = 3.5
	AudioManager.play_sfx_at_position("wood_break", global_position, 55.0, 0.08, 3.0)
	CombatJuice.add_trauma(0.25)
	HUD.show_notification("💥 ENEMY WARSHIP RAM IMPACT! Hull breached!")
	if _target_player_ship and is_instance_valid(_target_player_ship):
		if _target_player_ship.has_method("take_ship_damage"):
			_target_player_ship.take_ship_damage(75.0)

func take_naval_damage(amount: float, _source_ship: Node3D = null) -> void:
	take_damage(amount, Vector3.ZERO, false, _source_ship)

func take_damage(amount: float, _kb: Variant = Vector3.ZERO, _crit: bool = false, _source: Node3D = null) -> void:
	if is_sunk:
		return

	current_health = max(0.0, current_health - amount)
	_update_hp_display()

	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 2.0, 0), Color(1.0, 0.5, 0.1))
	CombatJuice.add_trauma(0.08)
	AudioManager.play_sfx_at_position("wood_break", global_position, 45.0, 0.1, -2.0)

	if current_health <= 0.0:
		sink_ship()

func sink_ship() -> void:
	if is_sunk:
		return
	is_sunk = true
	current_state = ShipAIState.SINKING

	HUD.show_notification("🏴‍☠️ ENEMY CORSAIR COG CRITICALLY STRUCK! The raider is sinking!")
	AudioManager.play_sfx_at_position("boulder_explosion", global_position, 65.0, 0.08, 4.0)
	CombatJuice.add_trauma(0.3)

	# Snap mast
	if _mast_node and is_instance_valid(_mast_node):
		var tw = _mast_node.create_tween()
		tw.tween_property(_mast_node, "rotation_degrees:z", 55.0, 0.6)

	# Spawn floating salvage treasure barrel
	_spawn_salvage_barrel()

func _process_sinking(delta: float) -> void:
	_sinking_timer += delta
	# Tilt hull onto beam ends and plummet into sea
	if _hull_pivot:
		_hull_pivot.rotation_degrees.z = lerp(_hull_pivot.rotation_degrees.z, 42.0, delta * 1.5)
		_hull_pivot.rotation_degrees.x = lerp(_hull_pivot.rotation_degrees.x, -28.0, delta * 1.2)
	global_position.y -= delta * 1.1

	if _sinking_timer >= 4.8:
		queue_free()

func _spawn_salvage_barrel() -> void:
	var salvage = MeshInstance3D.new()
	salvage.name = "FloatingSalvageBarrel"
	var barrel_m = AssetLoader.load_or_generate_model("res://assets/overworld/barrel.gltf", "dungeon", "prop")
	barrel_m.scale = Vector3.ONE * 1.4
	salvage.add_child(barrel_m)
	salvage.position = global_position + Vector3(randf_range(-3.0, 3.0), 0.1, randf_range(-3.0, 3.0))

	# Floating bob
	var tw = salvage.create_tween().set_loops(15)
	tw.tween_property(salvage, "position:y", 0.35, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(salvage, "position:y", -0.1, 1.2).set_trans(Tween.TRANS_SINE)

	get_parent().add_child(salvage)

	# Reward gold & soul echoes
	GameManager.add_gold(45)
	GameManager.soul_echoes += 35
	HUD.show_notification("⚓ Salvaged Pirate Ship Cargo: +45 Gold, +35 Soul Echoes!")
