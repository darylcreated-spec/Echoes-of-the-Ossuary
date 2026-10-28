extends Node3D
class_name LootChest

signal chest_opened(relic_drawn: bool)

@export var contains_relic: bool = true
@export var gold_amount: int = 35
@export var heal_amount: float = 30.0

var is_opened: bool = false
var _model: Node3D = null
var _lid_pivot: Node3D = null
var _interact_area: Area3D = null

func _ready() -> void:
	_setup_visuals()
	_setup_interaction()

func _setup_visuals() -> void:
	_model = AssetLoader.load_or_generate_model("res://assets/dungeon/chest_gold.glb", "dungeon", "chest_gold")
	add_child(_model)
	_lid_pivot = _model.find_child("LidPivot", true, false)

func _setup_interaction() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	_interact_area.collision_mask = 0
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.8
	col.shape = shape
	col.position.y = 0.5
	_interact_area.add_child(col)
	add_child(_interact_area)

func interact(player: Node3D) -> void:
	if is_opened:
		return
	is_opened = true
	
	AudioManager.play_sfx("chest_open", 0.05, 2.0)
	CombatJuice.add_trauma(0.12)
	
	# Animate Lid Opening
	if _lid_pivot:
		var tween = _lid_pivot.create_tween()
		tween.tween_property(_lid_pivot, "rotation_degrees:x", -105.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Golden Beam / Light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.3)
	light.light_energy = 3.5
	light.omni_range = 5.0
	light.position = Vector3(0, 0.6, 0)
	add_child(light)
	
	# Sparks
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.6, 0), Color(1.0, 0.8, 0.2))
	
	# Give Rewards
	var bonus = 1.6 if GameManager.has_boon("soul_siphon") else 1.0
	GameManager.add_gold(int(gold_amount * bonus))
	if player and heal_amount > 0:
		player.heal(heal_amount)
		
	chest_opened.emit(contains_relic)
	
	if contains_relic:
		# Trigger Boon Selection UI Modal
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_boon_selection"):
			hud.show_boon_selection()
