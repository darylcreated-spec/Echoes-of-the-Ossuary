extends Node3D
class_name MarketStall3D

enum StallTheme { PROVISIONS, ARMORER, HARBOR_FISH }

@export var stall_theme: StallTheme = StallTheme.PROVISIONS
@export var stall_name: String = "Oakhaven Market Stall"
@export var canopy_color: String = "blue"

func _ready() -> void:
	add_to_group("market_stall")
	add_to_group("interactable")
	_build_stall_visuals()
	_setup_interaction_area()

func _build_stall_visuals() -> void:
	# Primary market structure
	var model_path = "res://assets/overworld/building_market_%s.gltf" % canopy_color
	if not ResourceLoader.exists(model_path):
		model_path = "res://assets/overworld/building_market_blue.gltf"
		
	var stall_model = AssetLoader.load_or_generate_model(model_path, "building", "market_stall")
	if stall_model:
		stall_model.scale = Vector3.ONE * 1.6
		add_child(stall_model)

	# Clutter & Goods
	# Sacks and barrels on left
	var sack = AssetLoader.load_or_generate_model("res://assets/overworld/sack.gltf", "prop", "sack")
	if sack:
		sack.position = Vector3(-1.4, 0.0, 0.8)
		sack.scale = Vector3.ONE * 1.8
		add_child(sack)

	var barrel = AssetLoader.load_or_generate_model("res://assets/overworld/barrel.gltf", "prop", "barrel")
	if barrel:
		barrel.position = Vector3(-1.5, 0.0, -0.6)
		barrel.scale = Vector3.ONE * 1.6
		add_child(barrel)

	# Crates on right
	var crate = AssetLoader.load_or_generate_model("res://assets/overworld/crate_open.gltf", "prop", "crate_open")
	if crate:
		crate.position = Vector3(1.4, 0.0, 0.7)
		crate.scale = Vector3.ONE * 1.5
		add_child(crate)

	# Small hanging lantern
	var lantern = AssetLoader.load_or_generate_model("res://assets/overworld/lantern_hanging.gltf", "prop", "lantern_hanging")
	if lantern:
		lantern.position = Vector3(0.0, 2.2, 1.1)
		lantern.scale = Vector3.ONE * 1.2
		add_child(lantern)

	# Warm stall light
	var light = OmniLight3D.new()
	light.position = Vector3(0.0, 1.8, 0.4)
	light.light_color = Color(1.0, 0.85, 0.5)
	light.light_energy = 1.4
	light.omni_range = 5.5
	add_child(light)

func _setup_interaction_area() -> void:
	var area = Area3D.new()
	area.name = "MarketInteractArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactable
	area.collision_mask = 0
	
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 2.4, 3.2)
	cs.shape = box
	cs.position.y = 1.0
	area.add_child(cs)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Inspect %s" % stall_name

func interact(_player: Node3D) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud or not hud.dialogue_modal:
		return
		
	var actions: Array[Dictionary] = [
		{"id": "buy_market_apple", "label": "🍎 Honeyed Apple (4 Gold)", "color": Color(0.2, 0.45, 0.25)},
		{"id": "buy_market_jerky", "label": "🥩 Venison Jerky (8 Gold)", "color": Color(0.45, 0.25, 0.2)},
		{"id": "buy_market_whetstone", "label": "⚔️ Whetstone Oil (15 Gold)", "color": Color(0.25, 0.35, 0.55)},
		{"id": "farewell", "label": "Step Away", "color": Color(0.2, 0.2, 0.25)}
	]
	
	hud.dialogue_modal.show_dialogue(
		stall_name,
		"🧺",
		"Fresh wares straight from the regional farmsteads and artisan guilds! What supplies do you require for your travels, traveler?",
		actions
	)
