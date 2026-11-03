extends Node3D
class_name HarborDefenseTower3D

@export var tower_name: String = "Bastion of the Sea Watch"
@export var attack_range: float = 65.0
@export var fire_interval: float = 3.8
@export var attack_damage: float = 55.0

var _fire_timer: float = 0.0
var _cannon_node: Node3D = null
var _cannon_muzzle: Node3D = null
var _target_ship: Node3D = null
var _sentry_anim: AnimationPlayer = null

func _ready() -> void:
	name = "HarborDefenseTower3D"
	add_to_group("harbor_defense_tower")
	_build_visuals()
	_fire_timer = randf_range(1.0, 2.5)

func _build_visuals() -> void:
	# 1. Fortified Stone Bastion Watchtower
	var tower_model = AssetLoader.load_or_generate_model("res://assets/ships/tower-complete-large.glb", "prop", "tower-complete-large")
	if not tower_model:
		tower_model = AssetLoader.load_or_generate_model("res://assets/overworld/building_tower_catapult_blue.gltf", "prop", "coastal_tower")
	if tower_model:
		tower_model.scale = Vector3.ONE * 3.4
		tower_model.position = Vector3(0.0, 0.0, 0.0)
		add_child(tower_model)

	# 2. Heavy Coastal Artillery Cannon on Battlements (Y = 8.8m)
	_cannon_node = Node3D.new()
	_cannon_node.name = "CoastalCannonMount"
	_cannon_node.position = Vector3(0.0, 8.8, 0.0)
	add_child(_cannon_node)

	var cannon_model = AssetLoader.load_or_generate_model("res://assets/ships/cannon.glb", "prop", "cannon")
	if cannon_model:
		cannon_model.scale = Vector3.ONE * 2.2
		_cannon_node.add_child(cannon_model)

	_cannon_muzzle = Node3D.new()
	_cannon_muzzle.name = "MuzzlePoint"
	_cannon_muzzle.position = Vector3(0.0, 0.45, -2.2)
	_cannon_node.add_child(_cannon_muzzle)

	# 3. Armed Battlement Marine Sentry
	var sentry = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Knight.glb", "character", "CoastalGunner")
	if sentry:
		sentry.scale = Vector3.ONE * 0.54
		sentry.position = Vector3(1.1, 8.8, 0.4)
		sentry.rotation_degrees.y = -90.0
		add_child(sentry)
		_sentry_anim = sentry.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _sentry_anim and _sentry_anim.has_animation("Cheer"):
			var a = _sentry_anim.get_animation("Cheer")
			if a: a.loop_mode = Animation.LOOP_LINEAR
			_sentry_anim.play("Cheer")

	# 4. Signal Beacon Fire Brazier
	var brazier = AssetLoader.load_or_generate_model("res://assets/overworld/shrine_candles.gltf", "prop", "beacon_brazier")
	if brazier:
		brazier.scale = Vector3.ONE * 2.0
		brazier.position = Vector3(-1.2, 8.8, -0.6)
		add_child(brazier)
	var fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.65, 0.25)
	fire_light.light_energy = 3.5
	fire_light.omni_range = 14.0
	fire_light.position = Vector3(-1.2, 9.6, -0.6)
	add_child(fire_light)

	# 5. Bastion Static Collider
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 3.6
	cyl.height = 10.0
	cs.shape = cyl
	cs.position = Vector3(0.0, 5.0, 0.0)
	sb.add_child(cs)
	add_child(sb)

	# 6. Overhead Nameplate
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 11.2, 0.0)
	AssetLoader.style_world_label3d(lbl, "🏰 " + tower_name + "\n[Coastal Defense Battery]", 36, Color(1.0, 0.88, 0.62))
	add_child(lbl)

func _process(delta: float) -> void:
	_fire_timer -= delta
	_acquire_target()

	if _target_ship and is_instance_valid(_target_ship) and _cannon_node:
		var target_pos = _target_ship.global_position
		target_pos.y = _cannon_node.global_position.y
		var look_dir = (target_pos - _cannon_node.global_position).normalized()
		if look_dir.length_squared() > 0.01:
			var target_rot = atan2(-look_dir.x, -look_dir.z)
			_cannon_node.rotation.y = lerp_angle(_cannon_node.rotation.y, target_rot, delta * 3.5)

	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		if _target_ship and is_instance_valid(_target_ship):
			_fire_coastal_cannon()

func _acquire_target() -> void:
	if _target_ship and is_instance_valid(_target_ship) and not _target_ship.is_queued_for_deletion():
		if global_position.distance_to(_target_ship.global_position) <= attack_range:
			return
	_target_ship = null
	var enemies = get_tree().get_nodes_in_group("enemy_naval_ship")
	var closest_dist = attack_range
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < closest_dist:
				closest_dist = d
				_target_ship = e

func _fire_coastal_cannon() -> void:
	if not _target_ship or not is_instance_valid(_target_ship):
		return

	# Audio
	AudioManager.play_sfx_at_position("cannon_fire", global_position + Vector3(0, 8.8, 0), 65.0, 0.08, 0.0)
	CombatJuice.add_trauma(0.18)

	# Muzzle Flash VFX
	var muzzle_pos = _cannon_muzzle.global_position if _cannon_muzzle else global_position + Vector3(0, 9.2, -2.0)
	CombatJuice.spawn_hit_spark(muzzle_pos, Color(1.0, 0.75, 0.2))

	# Projectile Arc toward Enemy Ship
	var dir = (_target_ship.global_position - muzzle_pos).normalized()
	var ball = AssetLoader.load_or_generate_model("res://assets/ships/cannon-ball.glb", "prop", "cannon_ball")
	if not ball:
		ball = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.28
		sp.height = 0.56
		ball.mesh = sp
	get_tree().current_scene.add_child(ball)
	ball.global_position = muzzle_pos
	ball.scale = Vector3.ONE * 0.5

	var target_dest = _target_ship.global_position + Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5))
	var fly_time = 0.85
	var tween = ball.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ball, "global_position:x", target_dest.x, fly_time)
	tween.tween_property(ball, "global_position:z", target_dest.z, fly_time)
	tween.tween_property(ball, "global_position:y", target_dest.y + 3.2, fly_time * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(ball, "global_position:y", target_dest.y, fly_time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		if is_instance_valid(ball):
			ball.queue_free()
		AudioManager.play_sfx_at_position("cannon_impact", target_dest, 50.0, 0.1, 0.0)
		CombatJuice.spawn_hit_spark(target_dest, Color(1.0, 0.6, 0.2))
		if is_instance_valid(_target_ship) and _target_ship.has_method("take_naval_damage"):
			_target_ship.take_naval_damage(attack_damage, self)
	)
