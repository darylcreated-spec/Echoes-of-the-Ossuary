extends Node3D
class_name ArmyFormation3D

@export var regiment_name: String = "Royal Vanguard"
@export var faction_color: String = "blue" # "blue" or "red"
@export var march_speed: float = 2.5
@export var waypoints: Array = []
@export var wait_time: float = 2.8

var _soldiers: Array = []
var _anim_players: Array = []
var _current_wp_idx: int = 0
var _wait_timer: float = 0.0
var _is_waiting: bool = false
var _march_sfx_timer: float = 0.0

func _ready() -> void:
	add_to_group("army_formation")
	add_to_group("interactable")
	if waypoints.is_empty():
		waypoints.append(global_position)
		waypoints.append(global_position + Vector3(0.0, 0.0, 14.0))

	_build_squadron()
	_build_interaction()

func _build_squadron() -> void:
	# 5-Soldier Formation:
	# [0] Commander Knight (Front Center)
	# [1] Left Front Footman (Knight)
	# [2] Right Front Footman (Knight)
	# [3] Left Rear Halberdier/Vanguard (Barbarian)
	# [4] Right Rear Marksman (Rogue_Hooded with Crossbow)
	var offsets = [
		Vector3(0.0, 0.0, -1.6),
		Vector3(-1.3, 0.0, 0.2),
		Vector3(1.3, 0.0, 0.2),
		Vector3(-1.3, 0.0, 2.0),
		Vector3(1.3, 0.0, 2.0)
	]
	var models = [
		"res://assets/characters/adventurers/Knight.glb",
		"res://assets/characters/adventurers/Knight.glb",
		"res://assets/characters/adventurers/Knight.glb",
		"res://assets/characters/adventurers/Barbarian.glb",
		"res://assets/characters/adventurers/Rogue_Hooded.glb"
	]

	var flag_path = "res://assets/overworld/flag_red.gltf" if faction_color == "red" else "res://assets/overworld/flag_blue.gltf"

	for i in range(offsets.size()):
		var soldier_root = Node3D.new()
		soldier_root.name = "Soldier_%d" % i
		soldier_root.position = offsets[i]
		add_child(soldier_root)

		var model = AssetLoader.load_or_generate_model(models[i], "character", "Knight")
		model.scale = Vector3(0.85, 0.85, 0.85)
		soldier_root.add_child(model)
		_soldiers.append(soldier_root)

		# Attach weapons & shields
		if i <= 2:
			var sword = AssetLoader.load_or_generate_model("res://assets/weapons/sword_1handed.gltf", "weapon", "sword")
			AssetLoader.attach_weapon_socket(model, sword, "handslot.r")
			var shield = AssetLoader.load_or_generate_model("res://assets/weapons/shield_square_color.gltf", "weapon", "shield")
			AssetLoader.attach_weapon_socket(model, shield, "handslot.l")
		elif i == 3:
			var axe = AssetLoader.load_or_generate_model("res://assets/weapons/axe_2handed.gltf", "weapon", "axe")
			AssetLoader.attach_weapon_socket(model, axe, "handslot.r")
		else:
			var xbow = AssetLoader.load_or_generate_model("res://assets/weapons/crossbow_2handed.gltf", "weapon", "crossbow")
			AssetLoader.attach_weapon_socket(model, xbow, "handslot.r")

		# Commander carries the tall Heraldic Standard Banner
		if i == 0:
			var banner = AssetLoader.load_or_generate_model(flag_path, "dungeon", "flag")
			banner.scale = Vector3.ONE * 1.4
			banner.position = Vector3(-0.35, 0.0, 0.25)
			soldier_root.add_child(banner)

		var ap = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			_anim_players.append(ap)
			_play_soldier_anim(ap, "Walking_A")

	# Regiment Floating Label
	var lbl = Label3D.new()
	var icon_str = "⚔️ " if faction_color == "red" else "🛡️ "
	lbl.position = Vector3(0.0, 2.7, -1.0)
	var primary_c = Color(1.0, 0.72, 0.72) if faction_color == "red" else Color(0.82, 0.92, 1.0)
	AssetLoader.style_world_label3d(lbl, icon_str + regiment_name + " (Marching Column)\n[E] Rally", 36, primary_c)
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
	return "[E] Inspect " + regiment_name

func interact(player: Node = null) -> void:
	_is_waiting = true
	_wait_timer = 3.5
	AudioManager.play_sfx_at_position("horn_rally", global_position, 40.0, 0.05, 0.0)
	for ap in _anim_players:
		_play_soldier_anim(ap, "Cheer")
	if player and player.has_method("heal"):
		player.heal(20.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🎺 " + regiment_name + " salutes and sounds the War Horn! (+20 HP Morale Boost)")
	elif hud and hud.has_method("show_mission_notification"):
		hud.show_mission_notification("🛡️ " + regiment_name + ": 'Steel and honor! We hold the realm's borders!'")

func _process(delta: float) -> void:
	# Ensure every soldier's animation stays looping continuously
	var target_anim = "Idle" if _is_waiting else "Walking_A"
	for ap in _anim_players:
		if is_instance_valid(ap) and not ap.is_playing():
			_play_soldier_anim(ap, target_anim)

	if waypoints.is_empty():
		return

	if _is_waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_is_waiting = false
			_current_wp_idx = (_current_wp_idx + 1) % waypoints.size()
			for ap in _anim_players:
				_play_soldier_anim(ap, "Walking_A")
		return

	_march_sfx_timer += delta
	if _march_sfx_timer >= 0.56:
		_march_sfx_timer = 0.0
		AudioManager.play_sfx_at_position("army_march", global_position, 26.0, 0.08, -7.0)

	var target: Vector3 = waypoints[_current_wp_idx]
	var diff = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if diff.length() < 0.6:
		_is_waiting = true
		_wait_timer = wait_time
		for ap in _anim_players:
			_play_soldier_anim(ap, "Idle")
		return

	var dir = diff.normalized()
	global_position += dir * march_speed * delta
	var target_angle = atan2(dir.x, dir.z) + PI # KayKit models face -Z or +Z depending on root
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 5.0)

func _play_soldier_anim(ap: AnimationPlayer, desired: String) -> void:
	if not ap:
		return
	var anim_list = ap.get_animation_list()
	var chosen = ""
	if ap.has_animation(desired):
		chosen = desired
	else:
		for a in anim_list:
			if desired.to_lower() in a.to_lower():
				chosen = a
				break
	if chosen == "" and anim_list.size() > 0:
		chosen = anim_list[0]
	if chosen != "":
		var res = ap.get_animation(chosen)
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
		ap.play(chosen, 0.15)
