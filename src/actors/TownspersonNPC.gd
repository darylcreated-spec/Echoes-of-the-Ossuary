extends Node3D
class_name TownspersonNPC

enum NPCRole {
	VENDOR,
	TOWN_CRIER,
	MINSTREL,
	WATCH_PATROL,
	CITIZEN,
	MONK,
	BEGGAR,
	CHILD
}

@export var citizen_name: String = "Townsperson"
@export var citizen_title: String = "Oakhaven Resident"
@export var role: NPCRole = NPCRole.CITIZEN
@export var model_path: String = "res://assets/characters/adventurers/Rogue.glb"
@export var model_scale: Vector3 = Vector3(0.52, 0.52, 0.52)
@export var speech_barks: Array = []
@export var waypoints: Array = []
@export var move_speed: float = 2.2
@export var icon: String = "👤"
@export var trade_items: Array = []

var _anim_player: AnimationPlayer = null
var _model_root: Node3D = null
var _bark_label: Label3D = null
var _bark_timer: float = 0.0
var _current_wp_idx: int = 0
var _is_moving: bool = false
var _player_ref: Node3D = null

func _ready() -> void:
	add_to_group("npc")
	add_to_group("townsperson")
	add_to_group("interactable")

	_build_visuals()
	_build_speech_bark_ui()
	_build_interaction_area()
	_bark_timer = randf_range(2.0, 7.0)

	if speech_barks.is_empty():
		_setup_default_barks()

func _build_visuals() -> void:
	_model_root = AssetLoader.load_or_generate_model(model_path, "character", citizen_name)
	_model_root.scale = model_scale
	add_child(_model_root)

	_anim_player = _model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not _anim_player:
		for c in _model_root.get_children():
			if c is AnimationPlayer:
				_anim_player = c
				break

	if waypoints.is_empty():
		_play_anim("Idle" if role != NPCRole.BEGGAR else "Sit_Floor_Idle")
	else:
		_play_anim("Walking_A")

func _build_speech_bark_ui() -> void:
	_bark_label = Label3D.new()
	_bark_label.position = Vector3(0.0, 2.25 if role != NPCRole.CHILD else 1.6, 0.0)
	_bark_label.font_size = 28
	_bark_label.outline_size = 8
	_bark_label.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	_bark_label.modulate = Color(1.0, 0.94, 0.75, 0.0) # Start invisible
	_bark_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark_label.double_sided = true
	_bark_label.text = ""
	add_child(_bark_label)

func _build_interaction_area() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactables
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 2.8
	col.shape = sp
	col.position = Vector3(0.0, 1.0, 0.0)
	area.add_child(col)
	add_child(area)

func _setup_default_barks() -> void:
	match role:
		NPCRole.TOWN_CRIER:
			speech_barks = [
				"Hear ye! King Aldric promises rich bounties for sealed bone relics!",
				"The Southern Warlords stir beyond the river! Maintain vigilance!",
				"Shipments of silver and timber arrive daily at Port Blackwater!"
			]
		NPCRole.VENDOR:
			speech_barks = [
				"Fine goods fresh from the road! Come browse!",
				"Best prices north of the Weeping Fen!",
				"Supplies for weary crypt-delvers and champions alike!"
			]
		NPCRole.MINSTREL:
			speech_barks = [
				"♪ Across the jagged sea of bone, the fearless champion stood alone... ♪",
				"A ballad of the High Citadel for any generous patron!",
				"♪ O hear the bell of Blackwater bay, that wards the raider cogs away... ♪"
			]
		NPCRole.WATCH_PATROL:
			speech_barks = [
				"Keep your blade sheathed within town walls, traveler.",
				"All quiet along the North Wall.",
				"King's Vanguard stands ready."
			]
		NPCRole.MONK:
			speech_barks = [
				"May the Sacred Dawn cleanse the shadows from your path.",
				"Pray for the fallen whose bones rest in the crypts below.",
				"Peace unto this holy sanctuary."
			]
		NPCRole.BEGGAR:
			speech_barks = [
				"A coin for a crippled soldier of the Citadel war?",
				"Bless your kind heart, noble champion...",
				"The dead whisper in the night under the mausoleum..."
			]
		NPCRole.CHILD:
			speech_barks = [
				"Look at that shiny armor! Are you a knight of the King?",
				"I saw a huge ship with eight cannons sailing into port!",
				"Catch me if you can!"
			]
		_:
			speech_barks = [
				"Good morrow, champion.",
				"Have you explored the coastal docks at Port Blackwater?",
				"Safe travels on the King's highway."
			]

func _process(delta: float) -> void:
	_bark_timer -= delta
	if _bark_timer <= 0.0:
		_bark_timer = randf_range(9.0, 18.0)
		_trigger_ambient_bark()

	# Proximity check for player approaching
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as Node3D
	elif _player_ref and is_instance_valid(_player_ref):
		var dist = global_position.distance_to(_player_ref.global_position)
		if dist < 4.5 and randf() < 0.005:
			_trigger_ambient_bark()

	_process_movement(delta)

func _process_movement(delta: float) -> void:
	if waypoints.is_empty():
		return

	var target = waypoints[_current_wp_idx]
	var diff = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if diff.length() < 0.6:
		_current_wp_idx = (_current_wp_idx + 1) % waypoints.size()
		# Pause briefly at waypoint
		if randf() < 0.5:
			_play_anim("Idle")
			set_process(false)
			get_tree().create_timer(randf_range(2.0, 4.5)).timeout.connect(func():
				if is_instance_valid(self):
					set_process(true)
					_play_anim("Walking_A")
			)
		return

	var dir = diff.normalized()
	global_position += dir * move_speed * delta

	# Look toward movement
	var look_target = global_position + dir
	if not look_target.is_equal_approx(global_position):
		look_at(look_target, Vector3.UP)

func _trigger_ambient_bark() -> void:
	if speech_barks.is_empty() or not _bark_label:
		return

	var text = speech_barks[randi() % speech_barks.size()]
	_bark_label.text = icon + " \"" + text + "\""

	var tw = create_tween()
	tw.tween_property(_bark_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(4.2)
	tw.tween_property(_bark_label, "modulate:a", 0.0, 0.5)

func get_prompt_text() -> String:
	return "[E] Speak with " + citizen_name

func interact(_player: Node = null) -> void:
	# Face the player
	if _player_ref and is_instance_valid(_player_ref):
		var p_pos = Vector3(_player_ref.global_position.x, global_position.y, _player_ref.global_position.z)
		if not p_pos.is_equal_approx(global_position):
			look_at(p_pos, Vector3.UP)

	AudioManager.play_sfx("button_click", 0.08, -2.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		return

	if role == NPCRole.VENDOR and not trade_items.is_empty():
		hud.open_dialogue(
			citizen_name + " (" + citizen_title + ")",
			icon,
			"Welcome to my stall, traveler! What supplies do you require for your journey?",
			trade_items
		)
	elif role == NPCRole.BEGGAR:
		var beggar_actions: Array[Dictionary] = [
			{"id": "give_alms", "label": "🪙 Offer 5 Gold Alms (+Karma)", "color": Color(0.9, 0.75, 0.2), "closes": true}
		]
		hud.open_dialogue(
			citizen_name + " (" + citizen_title + ")",
			icon,
			"May the light bless your path, noble one. A few coins would buy warm soup for the night...",
			beggar_actions
		)
	else:
		var bark = speech_barks[0] if not speech_barks.is_empty() else "Hail, champion of Oakhaven!"
		hud.open_dialogue(
			citizen_name + " (" + citizen_title + ")",
			icon,
			bark,
			[{"id": "close", "label": "Farewell", "color": Color(0.7, 0.7, 0.7), "closes": true}]
		)

func _play_anim(anim_name: String) -> void:
	if _anim_player and is_instance_valid(_anim_player):
		if _anim_player.has_animation(anim_name):
			_anim_player.play(anim_name, 0.15)
		elif _anim_player.has_animation("Idle"):
			_anim_player.play("Idle", 0.15)
