extends Area3D
class_name WorldRepairStation

@export var repair_id: String = "port_crane"
@export var station_name: String = "Harbor Cargo Crane"
@export var required_materials: Dictionary = {"lumber": 1, "iron_ore": 1}
@export var target_story_act: int = 2
@export var gold_reward: int = 150
@export var echo_reward: int = 50

var is_repaired: bool = false
var _player_in_range: bool = false
var _label: Label3D = null
var ruined_node: Node3D = null
var restored_node: Node3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detects player
	monitoring = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 3.2
	col.shape = sphere
	add_child(col)

	_build_floating_label()
	_update_visual_state()

func _process(_delta: float) -> void:
	if not is_repaired and GameManager.world_repairs.get(repair_id, false):
		_on_repaired_externally()

	if _player_in_range and not is_repaired:
		if Input.is_action_just_pressed("interact"):
			attempt_repair()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_update_label_text()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

func _build_floating_label() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.8
	_label.font_size = 26
	_label.outline_size = 8
	_label.outline_modulate = Color(0.02, 0.03, 0.05)
	add_child(_label)
	_update_label_text()

func _update_label_text() -> void:
	if not _label:
		return
	if is_repaired or GameManager.world_repairs.get(repair_id, false):
		_label.text = "✨ " + station_name + "\n[RESTORED & ACTIVE]"
		_label.modulate = Color(0.3, 0.95, 0.5)
	else:
		var req_strs: Array[String] = []
		for mat in required_materials.keys():
			var req_count = required_materials[mat]
			var cur_count = GameManager.materials.get(mat, 0)
			req_strs.append(mat.capitalize() + " (" + str(cur_count) + "/" + str(req_count) + ")")
		_label.text = "🔨 " + station_name + "\n[E] Reconstruct: " + ", ".join(req_strs)
		_label.modulate = Color(1.0, 0.85, 0.3)

func _update_visual_state() -> void:
	is_repaired = GameManager.world_repairs.get(repair_id, false)
	if ruined_node and is_instance_valid(ruined_node):
		ruined_node.visible = not is_repaired
	if restored_node and is_instance_valid(restored_node):
		restored_node.visible = is_repaired
	_update_label_text()

func attempt_repair() -> bool:
	if is_repaired:
		return false

	# Check materials
	var has_all = true
	for mat in required_materials.keys():
		var req_count = required_materials[mat]
		var cur_count = GameManager.materials.get(mat, 0)
		# Fallback: if player has general wood or metal
		if cur_count < req_count:
			has_all = false
			break

	var hud = get_tree().get_first_node_in_group("hud")
	if not has_all:
		AudioManager.play_sfx("ui_switch", 0.08, 0.7)
		if hud and "mission_toast" in hud and "mission_toast_lbl" in hud:
			hud.mission_toast_lbl.text = "❌ Cannot repair " + station_name + "!\nMissing required materials."
			hud.mission_toast.visible = true
			hud.mission_toast.modulate.a = 1.0
			get_tree().create_timer(2.4).timeout.connect(func(): if hud and hud.mission_toast: hud.mission_toast.visible = false)
		return false

	# Deduct materials
	for mat in required_materials.keys():
		var req_count = required_materials[mat]
		GameManager.materials[mat] = maxi(0, GameManager.materials.get(mat, 0) - req_count)

	# Mark repaired
	is_repaired = true
	GameManager.repair_structure(repair_id)
	GameManager.add_gold(gold_reward)
	GameManager.add_echoes(echo_reward)
	GameManager.advance_story_act(target_story_act)

	AudioManager.play_sfx("level_up", 0.08, 1.2)
	AmbientFX.create_sacred_aura(self, Vector3(0, 1.0, 0))
	_update_visual_state()

	if hud and "mission_toast" in hud and "mission_toast_lbl" in hud:
		hud.mission_toast_lbl.text = "🎉 " + station_name.to_upper() + " RESTORED!\n+" + str(gold_reward) + " Gold, +" + str(echo_reward) + " Echoes! Story Advanced!"
		hud.mission_toast.visible = true
		hud.mission_toast.modulate.a = 1.0
		get_tree().create_timer(3.5).timeout.connect(func(): if hud and hud.mission_toast: hud.mission_toast.visible = false)

	return true

func _on_repaired_externally() -> void:
	is_repaired = true
	_update_visual_state()
