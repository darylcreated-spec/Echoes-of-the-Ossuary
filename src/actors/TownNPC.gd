extends Node3D
class_name TownNPC

@export var npc_id: String = "blacksmith"
@export var npc_name: String = "Master Torval"
@export var npc_title: String = "Village Blacksmith"
@export var icon: String = "⚒️"
@export_multiline var dialogue_text: String = "Hail, warrior! The forge fires burn night and day. Bring me Soul Echoes from the Ossuary depths and I shall re-temper your blade, fortify your armor, and sharpen your dash reflexes!"
@export var model_path: String = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
@export var model_scale: Vector3 = Vector3(0.55, 0.55, 0.55)
@export var model_rotation_y: float = 0.0

var _model: Node3D = null
var _label: Label3D = null
var _interact_area: Area3D = null
var _anim_player: AnimationPlayer = null

func _ready() -> void:
	name = "NPC_" + npc_id
	add_to_group("interactable")
	_build_visuals()
	_build_interaction()

func _build_visuals() -> void:
	_model = AssetLoader.load_or_generate_model(model_path, "character", npc_name)
	_model.scale = model_scale
	if model_rotation_y != 0.0:
		_model.rotation_degrees.y = model_rotation_y
	add_child(_model)
	
	# Look for AnimationPlayer and start idle
	_anim_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player:
		var anims = _anim_player.get_animation_list()
		if anims.size() > 0:
			# Play first idle-like or default animation
			var idle_anim = anims[0]
			for a in anims:
				if "idle" in a.to_lower():
					idle_anim = a
					break
			_anim_player.play(idle_anim)
	
	# Floating Name Tag & Prompt
	_label = Label3D.new()
	_label.text = icon + " " + npc_name + "\n[E] Speak"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.0
	_label.font_size = 28
	_label.outline_size = 8
	_label.outline_modulate = Color(0.02, 0.03, 0.05)
	_label.modulate = Color(1.0, 0.90, 0.55)
	add_child(_label)

func _build_interaction() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	_interact_area.collision_mask = 0
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.4
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	_interact_area.add_child(col)
	add_child(_interact_area)

func interact(player: Node3D) -> void:
	if player:
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if look_target.distance_to(global_position) > 0.1:
			look_at(look_target, Vector3.UP)
			rotation.x = 0.0
			rotation.z = 0.0

	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		return
		
	var actions: Array[Dictionary] = []
	match npc_id:
		"blacksmith":
			actions.append({
				"id": "open_upgrades",
				"label": "⚒️ Forge Upgrades",
				"color": Color(0.62, 0.28, 0.12),
				"closes": true
			})
		"priestess":
			actions.append({
				"id": "open_missions",
				"label": "📜 View Bounties",
				"color": Color(0.18, 0.42, 0.65),
				"closes": true
			})
		"guard":
			actions.append({
				"id": "gate_info",
				"label": "🛡️ Catacomb Advice",
				"color": Color(0.24, 0.32, 0.48),
				"closes": false
			})
		"farmer":
			actions.append({
				"id": "open_missions",
				"label": "📜 Hamlet Requests",
				"color": Color(0.25, 0.52, 0.22),
				"closes": true
			})
		"commander":
			actions.append({
				"id": "open_missions",
				"label": "🛡️ Royal Decrees",
				"color": Color(0.55, 0.22, 0.22),
				"closes": true
			})
		"hermit":
			actions.append({
				"id": "open_upgrades",
				"label": "✨ Channel Soul Echoes",
				"color": Color(0.35, 0.20, 0.58),
				"closes": true
			})
			
	if hud.has_method("open_dialogue"):
		hud.open_dialogue(npc_name + " (" + npc_title + ")", icon, dialogue_text, actions)
