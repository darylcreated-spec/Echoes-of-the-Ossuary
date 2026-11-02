extends Node3D
class_name EnemyNavalShip3D

@export var ship_name: String = "Dread Corsair Cog"
@export var max_health: float = 160.0
@export var current_health: float = 160.0
@export var move_speed: float = 3.4
@export var attack_damage: float = 24.0

var _is_sinking: bool = false
var _wave_time: float = 0.0
var _fire_timer: float = 3.0
var _hull_pivot: Node3D = null
var _health_bar_fill: MeshInstance3D = null
var _damage_smoke: GPUParticles3D = null
var _target: Node3D = null
var _waypoints: Array[Vector3] = []
var _wp_index: int = 0

func _ready() -> void:
	name = "EnemyNavalShip3D"
	add_to_group("enemy_naval_ship")
	add_to_group("enemies")
	current_health = max_health
	_wave_time = randf_range(0.0, 10.0)

	_hull_pivot = Node3D.new()
	_hull_pivot.name = "EnemyHullBuoyancy"
	add_child(_hull_pivot)

	_build_visuals()
	_build_health_bar()
	_setup_patrol_path()

func _build_visuals() -> void:
	# 1. Pirate Ship Model
	var ship_model = AssetLoader.load_or_generate_model("res://assets/ships/ship-pirate-medium.glb", "prop", "pirate_ship")
	if not ship_model:
		ship_model = AssetLoader.load_or_generate_model("res://assets/ships/ship-medium.glb", "prop", "pirate_ship_fallback")
	if ship_model:
		ship_model.scale = Vector3.ONE * 2.8
		_hull_pivot.add_child(ship_model)

	# 2. Black Pirate Jolly Roger Pennant Flag
	var flag = AssetLoader.load_or_generate_model("res://assets/ships/flag-pirate-high.glb", "prop", "pirate_flag")
	if flag:
		flag.scale = Vector3.ONE * 2.2
		flag.position = Vector3(0.0, 9.8, 0.0)
		_hull_pivot.add_child(flag)

	# 3. Skeleton Pirate Crew on Gun Deck
	var pirate_skel = AssetLoader.load_or_generate_model("res://assets/characters/monsters/Skeleton_Warrior.glb", "character", "PirateSkel")
	if pirate_skel:
		pirate_skel.scale = Vector3.ONE * 0.52
		pirate_skel.position = Vector3(0.0, 1.8, 2.4)
		pirate_skel.rotation_degrees.y = 180.0
		_hull_pivot.add_child(pirate_skel)
		var ap = pirate_skel.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap and ap.has_animation("Cheer"):
			var a = ap.get_animation("Cheer")
			if a: a.loop_mode = Animation.LOOP_LINEAR
			ap.play("Cheer")

	# 4. Floating Nameplate
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 12.0, 0.0)
	AssetLoader.style_world_label3d(lbl, "🏴‍☠️ " + ship_name, 38, Color(1.0, 0.35, 0.35))
	_hull_pivot.add_child(lbl)

	# 5. Static Collision Hull
	var sb = StaticBody3D.new()
	sb.name = "EnemyShipCollider"
	sb.collision_layer = 1 | (1 << 2) # World + Enemy
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(5.2, 3.2, 12.0)
	cs.shape = box
	cs.position = Vector3(0.0, 1.5, 0.0)
	sb.add_child(cs)
	add_child(sb)

func _build_health_bar() -> void:
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(3.6, 0.32, 0.1)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.12, 0.12, 0.12, 0.85)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.material_override = bg_mat
	bg.position = Vector3(0.0, 11.2, 0.0)
	_hull_pivot.add_child(bg)

	_health_bar_fill = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(3.5, 0.28, 0.12)
	_health_bar_fill.mesh = fill_mesh
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.95, 0.22, 0.18)
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_health_bar_fill.material_override = fill_mat
	_health_bar_fill.position = Vector3(0.0, 11.2, 0.01)
	_hull_pivot.add_child(_health_bar_fill)

func _setup_patrol_path() -> void:
	_waypoints = [
		Vector3(-108.0, -0.22, 58.0),
		Vector3(-96.0, -0.22, 75.0),
		Vector3(-104.0, -0.22, 95.0),
		Vector3(-118.0, -0.22, 78.0)
	]

func _process(delta: float) -> void:
	if _is_sinking:
		return

	_wave_time += delta
	if _hull_pivot:
		_hull_pivot.position.y = sin(_wave_time * 1.8) * 0.15
		_hull_pivot.rotation_degrees.z = sin(_wave_time * 1.4) * 2.5
		_hull_pivot.rotation_degrees.x = cos(_wave_time * 1.1) * 1.5

	_navigate_and_attack(delta)

func _navigate_and_attack(delta: float) -> void:
	# Follow patrol / siege path
	if _waypoints.size() > 0:
		var target_wp = _waypoints[_wp_index]
		var to_wp = target_wp - global_position
		to_wp.y = 0.0
		if to_wp.length() < 4.0:
			_wp_index = (_wp_index + 1) % _waypoints.size()
		else:
			var move_dir = to_wp.normalized()
			global_position += move_dir * move_speed * delta
			var target_yaw = atan2(-move_dir.x, -move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 1.8)

	# Firing Timer
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = randf_range(3.8, 5.2)
		_fire_broadside_volley()

func _fire_broadside_volley() -> void:
	# Find target: flagship or harbor pier
	var targets = get_tree().get_nodes_in_group("medieval_ship")
	var chosen: Node3D = null
	for t in targets:
		if is_instance_valid(t) and t != self and not (t is EnemyNavalShip3D):
			chosen = t
			break

	var target_pos = chosen.global_position if chosen else Vector3(-76.0, 0.0, 72.0)
	var dir_to_target = (target_pos - global_position).normalized()

	# Audio & Muzzle Spark
	AudioManager.play_sfx_at_position("cannon_fire", global_position + Vector3(0, 1.8, 0), 55.0, 0.08, 0.0)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 2.0, 0) + dir_to_target * 2.5, Color(1.0, 0.4, 0.1))

	# Launch arcing cannonball
	var ball = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.26
	sp.height = 0.52
	ball.mesh = sp
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.18)
	mat.metallic = 0.8
	ball.material_override = mat
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 2.0, 0) + dir_to_target * 2.5

	var dest = target_pos + Vector3(randf_range(-2.0, 2.0), 0.5, randf_range(-2.0, 2.0))
	var fly_time = 0.9
	var tw = ball.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ball, "global_position:x", dest.x, fly_time)
	tw.tween_property(ball, "global_position:z", dest.z, fly_time)
	tw.tween_property(ball, "global_position:y", dest.y + 2.8, fly_time * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(ball, "global_position:y", dest.y, fly_time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if is_instance_valid(ball):
			ball.queue_free()
		AudioManager.play_sfx_at_position("cannon_impact", dest, 45.0, 0.1, 0.0)
		CombatJuice.spawn_hit_spark(dest, Color(1.0, 0.5, 0.2))
		if chosen and is_instance_valid(chosen) and chosen.has_method("take_ship_damage"):
			chosen.take_ship_damage(attack_damage)
	)

func take_naval_damage(amount: float, _source: Node = null) -> void:
	if _is_sinking:
		return
	current_health = max(0.0, current_health - amount)
	CombatJuice.add_trauma(0.15)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 2.2, 0), Color(1.0, 0.8, 0.3))

	# Update Health Bar
	var ratio = current_health / max_health
	if _health_bar_fill:
		_health_bar_fill.scale.x = max(0.01, ratio)

	if current_health <= 0.0:
		_sink_ship()

func _sink_ship() -> void:
	if _is_sinking:
		return
	_is_sinking = true
	remove_from_group("enemy_naval_ship")
	remove_from_group("enemies")

	AudioManager.play_sfx_at_position("cannon_impact", global_position, 60.0, 0.15, 2.0)
	CombatJuice.add_trauma(0.25)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("💥 ENEMY WARSHIP DESTROYED! The " + ship_name + " sinks into the ocean deeps!")

	# Spawn Floating Loot Salvage
	_spawn_floating_loot()

	# Dramatic Sinking Tween (Roll 45 degrees and submerge below water)
	var sink_tw = create_tween()
	sink_tw.set_parallel(true)
	sink_tw.tween_property(_hull_pivot, "rotation_degrees:z", 48.0, 3.8).set_trans(Tween.TRANS_SINE)
	sink_tw.tween_property(_hull_pivot, "position:y", -3.2, 4.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sink_tw.chain().tween_callback(queue_free)

func _spawn_floating_loot() -> void:
	var chest_scene = load("res://assets/items/quest_materials/Chest_Ingots.glb")
	if chest_scene:
		var chest = chest_scene.instantiate()
		chest.scale = Vector3.ONE * 1.6
		chest.position = global_position + Vector3(randf_range(-1.5, 1.5), 0.05, randf_range(-1.5, 1.5))
		get_tree().current_scene.add_child(chest)

		# Add Gold Reward
		GameManager.add_gold(50)
		GameManager.add_echoes(35)
