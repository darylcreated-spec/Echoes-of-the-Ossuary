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
	# 1. Pack Horse in Front (Z = +1.0m)
	var horse_scene = load("res://assets/characters/animals/Horse.glb")
	if horse_scene:
		var horse = horse_scene.instantiate()
		horse.scale = Vector3.ONE * 0.42
		horse.position = Vector3(0.0, 0.0, 0.8)
		add_child(horse)
		_horse_anim = horse.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_play_loop_anim(_horse_anim, "Walk")

		# Trade saddlebags on pack horse flanks
		var sack_l = AssetLoader.load_or_generate_model("res://assets/overworld/sack.gltf", "dungeon", "prop")
		sack_l.scale = Vector3.ONE * 0.65
		sack_l.position = Vector3(-0.45, 0.75, 0.0)
		horse.add_child(sack_l)

		var sack_r = AssetLoader.load_or_generate_model("res://assets/overworld/sack.gltf", "dungeon", "prop")
		sack_r.scale = Vector3.ONE * 0.65
		sack_r.position = Vector3(0.45, 0.75, 0.0)
		horse.add_child(sack_r)

	# 2. Walking Caravan Trader alongside the Pack Horse
	var driver = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue.glb", "character", "Rogue")
	driver.scale = Vector3(0.53, 0.53, 0.53)
	driver.position = Vector3(1.1, 0.0, 0.5)
	add_child(driver)
	_driver_anim = driver.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_loop_anim(_driver_anim, "Walking_A")

	# Floating Caravan Label
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 2.85, 0.0)
	AssetLoader.style_world_label3d(lbl, "🐎 " + caravan_name + "\n[E] Trade & Hail", 36, Color(1.0, 0.92, 0.65))
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
	if _sfx_timer >= 1.6:
		_sfx_timer = 0.0
		AudioManager.play_sfx_at_position("wagon_rattle", global_position, 20.0, 0.1, -12.0)

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
