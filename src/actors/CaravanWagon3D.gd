extends Node3D
class_name CaravanWagon3D

@export var caravan_name: String = "Royal Guild Trade Caravan"
@export var travel_speed: float = 2.6
@export var waypoints: Array = []

var _horse_anim: AnimationPlayer = null
var _driver_anim: AnimationPlayer = null
var _wagon_node: Node3D = null
var _current_wp_idx: int = 0
var _roll_time: float = 0.0
var _sfx_timer: float = 0.0

func _ready() -> void:
	add_to_group("caravan_wagon")
	add_to_group("interactable")
	if waypoints.is_empty():
		waypoints = [
			global_position,
			global_position + Vector3(-20.0, 0.0, 0.0)
		]

	_build_caravan_assembly()
	_build_interaction()

func _build_caravan_assembly() -> void:
	# 1. Draft Horse in Front (Z = +2.8m)
	var horse_scene = load("res://assets/characters/animals/Horse.glb")
	if horse_scene:
		var horse = horse_scene.instantiate()
		horse.scale = Vector3.ONE * 0.42
		horse.position = Vector3(0.0, 0.0, 2.8)
		add_child(horse)
		_horse_anim = horse.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_play_loop_anim(_horse_anim, "Walk")

	# 2. Wooden Harness Shafts connecting Horse to Wagon
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.24, 0.14)
	wood_mat.roughness = 0.88
	for side_x in [-0.55, 0.55]:
		var shaft = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.10, 0.10, 2.8)
		s_mesh.material = wood_mat
		shaft.mesh = s_mesh
		shaft.position = Vector3(side_x, 0.75, 1.5)
		add_child(shaft)

	# 3. Loaded Medieval Cargo Wagon (Z = -0.5m)
	_wagon_node = AssetLoader.load_or_generate_model("res://assets/village/Prop_Wagon.gltf", "dungeon", "prop")
	_wagon_node.scale = Vector3.ONE * 1.65
	_wagon_node.position = Vector3(0.0, 0.0, -0.5)
	add_child(_wagon_node)

	# Cargo Barrels, Crates & Grain Sacks inside Wagon Bed
	var barrel = AssetLoader.load_or_generate_model("res://assets/overworld/barrel.gltf", "dungeon", "prop")
	barrel.scale = Vector3.ONE * 1.15
	barrel.position = Vector3(-0.35, 0.85, -0.6)
	add_child(barrel)

	var crate = AssetLoader.load_or_generate_model("res://assets/overworld/crate_A_small.gltf", "dungeon", "prop")
	crate.scale = Vector3.ONE * 1.25
	crate.position = Vector3(0.35, 0.85, -0.4)
	add_child(crate)

	var sack = AssetLoader.load_or_generate_model("res://assets/overworld/sack.gltf", "dungeon", "prop")
	sack.scale = Vector3.ONE * 1.3
	sack.position = Vector3(0.0, 0.85, -1.2)
	add_child(sack)

	# 4. Walking Caravan Master beside the Draft Horse
	var driver = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue.glb", "character", "Rogue")
	driver.scale = Vector3(0.53, 0.53, 0.53)
	driver.position = Vector3(1.4, 0.0, 1.6)
	add_child(driver)
	_driver_anim = driver.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_loop_anim(_driver_anim, "Walking_A")

	# Floating Caravan Label
	var lbl = Label3D.new()
	lbl.text = "🐎 " + caravan_name + "\n[E] Trade & Hail"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.7, 0.0)
	lbl.font_size = 24
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.90, 0.60)
	add_child(lbl)

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 3.5
	col.shape = sp
	col.position = Vector3(0.0, 1.2, 0.0)
	area.add_child(col)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Hail " + caravan_name

func interact(_player: Node = null) -> void:
	AudioManager.play_sfx_at_position("horse_neigh", global_position, 28.0, 0.08, -2.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_dialogue"):
		var actions: Array[Dictionary] = [
			{"id": "buy_mill_bread", "label": "🥖 Buy Trail Loaf (+25 HP - 5 Gold)", "color": Color(0.70, 0.48, 0.18), "closes": false},
			{"id": "buy_lumber", "label": "🪵 Buy Caravan Timber (+1 Lumber - 25 Gold)", "color": Color(0.55, 0.36, 0.16), "closes": false},
			{"id": "buy_iron_ore", "label": "⛏️ Buy Highland Iron (+1 Iron Ore - 30 Gold)", "color": Color(0.38, 0.45, 0.55), "closes": false}
		]
		hud.open_dialogue(
			caravan_name + " (Highway Supply Quartermaster)",
			"🐎",
			"Whoa there, steady boy! Hail, traveler! Our guild wagon hauls fresh provisions, seasoned timber, and highland iron ore between Oakhaven, Greenhollow, and Port Blackwater. Care to trade on the road?",
			actions
		)
	elif hud and hud.has_method("show_mission_notification"):
		hud.show_mission_notification("📦 " + caravan_name + ": 'Safe roads, traveler! Carrying grain, iron, and spiced ale across the kingdom!'")

func _process(delta: float) -> void:
	_roll_time += delta * 9.0
	_sfx_timer += delta
	if _sfx_timer >= 1.1:
		_sfx_timer = 0.0
		AudioManager.play_sfx_at_position("wagon_rattle", global_position, 24.0, 0.1, -7.0)

	if _wagon_node and is_instance_valid(_wagon_node):
		_wagon_node.position.y = abs(sin(_roll_time)) * 0.035
		_wagon_node.rotation_degrees.z = sin(_roll_time * 0.7) * 1.4

	if _horse_anim and is_instance_valid(_horse_anim) and not _horse_anim.is_playing():
		_play_loop_anim(_horse_anim, "Walk")
	if _driver_anim and is_instance_valid(_driver_anim) and not _driver_anim.is_playing():
		_play_loop_anim(_driver_anim, "Walking_A")

	if waypoints.is_empty():
		return

	var target: Vector3 = waypoints[_current_wp_idx]
	var diff = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if diff.length() < 0.75:
		_current_wp_idx = (_current_wp_idx + 1) % waypoints.size()
		return

	var dir = diff.normalized()
	global_position += dir * travel_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.5)

func _play_loop_anim(ap: AnimationPlayer, keyword: String) -> void:
	if not ap:
		return
	var anim_list = ap.get_animation_list()
	var chosen = ""
	for a in anim_list:
		if keyword.to_lower() in a.to_lower():
			chosen = a
			break
	if chosen == "" and anim_list.size() > 0:
		chosen = anim_list[0]
	if chosen != "":
		var res = ap.get_animation(chosen)
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
		ap.play(chosen)
