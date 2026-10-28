extends Node3D
class_name QuestMaterialNode

@export var material_id: String = "arcane_crystal"
@export var display_name: String = "Arcane Crystal"
@export var icon: String = "💎"
@export var model_path: String = "res://assets/items/quest_materials/Crystal1.glb"
@export var model_scale: Vector3 = Vector3(1.4, 1.4, 1.4)
@export var glow_color: Color = Color(0.2, 0.8, 1.0)
@export var gold_reward: int = 15
@export var echo_reward: int = 10

var _model: Node3D = null
var _label: Label3D = null
var _light: OmniLight3D = null
var _interact_area: Area3D = null
var _time: float = 0.0
var _base_y: float = 0.5

func _ready() -> void:
	name = "MaterialNode_" + material_id
	add_to_group("interactable")
	_build_visuals()
	_build_interaction()

func _build_visuals() -> void:
	_model = AssetLoader.load_or_generate_model(model_path, "prop", material_id)
	_model.scale = model_scale
	_model.position.y = _base_y
	add_child(_model)
	
	# Glow Light
	_light = OmniLight3D.new()
	_light.light_color = glow_color
	_light.light_energy = 1.4
	_light.omni_range = 3.5
	_light.position.y = _base_y + 0.3
	add_child(_light)
	
	# Floating billboard label
	_label = Label3D.new()
	_label.text = icon + " " + display_name + "\n[E] Gather"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = _base_y + 1.2
	_label.font_size = 24
	_label.outline_size = 6
	_label.outline_modulate = Color(0.05, 0.05, 0.08)
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)

func _build_interaction() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	_interact_area.collision_mask = 0
	
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0
	col.shape = sphere
	col.position.y = _base_y
	_interact_area.add_child(col)
	add_child(_interact_area)

func _process(delta: float) -> void:
	_time += delta
	if _model:
		_model.rotation.y += delta * 1.5
		_model.position.y = _base_y + sin(_time * 2.5) * 0.12

func interact(_player: Node3D) -> void:
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, _base_y, 0), glow_color)
	CombatJuice.add_trauma(0.08)
	AudioManager.play_sfx("chest_open", 0.08, 1.4)
	
	if GameManager.has_method("add_material"):
		GameManager.add_material(material_id, 1)
	if GameManager.has_method("record_material_gathered"):
		GameManager.record_material_gathered(material_id)
		
	GameManager.add_gold(gold_reward)
	GameManager.add_echoes(echo_reward)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and "interact_prompt" in hud and hud.interact_prompt:
		hud.interact_prompt.visible = false
		
	queue_free()
