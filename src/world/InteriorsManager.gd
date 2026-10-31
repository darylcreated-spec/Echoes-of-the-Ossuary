extends Node
class_name InteriorsManager

# Subterranean coordinate offsets for isolated building interiors
const CASTLE_ORIGIN = Vector3(0.0, -100.0, 0.0)
const TAVERN_ORIGIN = Vector3(60.0, -100.0, 0.0)
const FORGE_ORIGIN = Vector3(120.0, -100.0, 0.0)
const COTTAGE_ORIGIN = Vector3(180.0, -100.0, 0.0)

static func build_all_interiors(parent: Node3D) -> Node3D:
	var interiors_root = Node3D.new()
	interiors_root.name = "SubterraneanInteriors"
	parent.add_child(interiors_root)
	
	_build_castle_throne_room(interiors_root)
	_build_tavern_interior(interiors_root)
	_build_forge_interior(interiors_root)
	_build_cottage_interior(interiors_root)
	
	return interiors_root

# --- 1. CASTLE GRAND THRONE ROOM ---
static func _build_castle_throne_room(parent: Node3D) -> void:
	var room = Node3D.new()
	room.name = "Interior_Castle"
	room.position = CASTLE_ORIGIN
	parent.add_child(room)
	
	# Floor & Ceiling (18m wide x 26m long)
	_add_room_box_collider(room, Vector3(0, -0.25, 0), Vector3(18.0, 0.5, 26.0)) # Floor
	_create_room_floor(room, Vector3(18.0, 0.02, 26.0), Color(0.22, 0.25, 0.30), "res://assets/village/Floor_UnevenBrick.gltf")
	
	# Perimeter Walls (Height 6.5m)
	_add_wall_with_mesh(room, Vector3(0, 3.25, -13.0), Vector3(18.0, 6.5, 0.8), Color(0.32, 0.35, 0.40)) # North Wall
	_add_wall_with_mesh(room, Vector3(-9.0, 3.25, 0), Vector3(0.8, 6.5, 26.0), Color(0.32, 0.35, 0.40)) # West Wall
	_add_wall_with_mesh(room, Vector3(9.0, 3.25, 0), Vector3(0.8, 6.5, 26.0), Color(0.32, 0.35, 0.40))  # East Wall
	_add_wall_with_mesh(room, Vector3(-5.5, 3.25, 13.0), Vector3(7.0, 6.5, 0.8), Color(0.32, 0.35, 0.40)) # South Wall L
	_add_wall_with_mesh(room, Vector3(5.5, 3.25, 13.0), Vector3(7.0, 6.5, 0.8), Color(0.32, 0.35, 0.40))  # South Wall R
	
	# Colonnade of Stone Pillars
	for z in [-7.5, -2.5, 2.5, 7.5]:
		_place_model(room, "res://assets/overworld/pillar.gltf", Vector3(-5.5, 0, z), Vector3.ONE * 2.2)
		_place_model(room, "res://assets/overworld/pillar.gltf", Vector3(5.5, 0, z), Vector3.ONE * 2.2)
		_add_warm_light(room, Vector3(-5.5, 3.5, z), Color(1.0, 0.80, 0.45), 1.3, 7.0)
		_add_warm_light(room, Vector3(5.5, 3.5, z), Color(1.0, 0.80, 0.45), 1.3, 7.0)
	
	# Grand Dais & Throne
	var dais = _add_box(room, Vector3(0, 0.3, -9.5), Vector3(7.0, 0.6, 5.0), Color(0.38, 0.32, 0.28))
	_place_model(room, "res://assets/furniture/chair_A_wood.gltf", Vector3(0, 0.6, -10.5), Vector3.ONE * 2.4, 180.0)
	
	# Red Carpet Runner
	_place_model(room, "res://assets/furniture/rug_rectangle_A.gltf", Vector3(0, 0.05, -7.5), Vector3(3.2, 1.0, 3.8), 0.0)
	_place_model(room, "res://assets/furniture/rug_rectangle_A.gltf", Vector3(0, 0.05, -2.5), Vector3(3.2, 1.0, 3.8), 0.0)
	_place_model(room, "res://assets/furniture/rug_rectangle_A.gltf", Vector3(0, 0.05, 2.5), Vector3(3.2, 1.0, 3.8), 0.0)
	_place_model(room, "res://assets/furniture/rug_rectangle_A.gltf", Vector3(0, 0.05, 7.5), Vector3(3.2, 1.0, 3.8), 0.0)
	
	# Benches & Weapon Racks
	_place_model(room, "res://assets/overworld/bench_decorated.gltf", Vector3(-6.8, 0, -4.0), Vector3.ONE * 1.8, 90.0)
	_place_model(room, "res://assets/overworld/bench_decorated.gltf", Vector3(6.8, 0, -4.0), Vector3.ONE * 1.8, -90.0)
	_place_model(room, "res://assets/overworld/weaponrack.gltf", Vector3(-7.5, 0, 4.0), Vector3.ONE * 1.8, 90.0)
	_place_model(room, "res://assets/overworld/weaponrack.gltf", Vector3(7.5, 0, 4.0), Vector3.ONE * 1.8, -90.0)
	
	# Candelabras near dais
	_place_model(room, "res://assets/overworld/candle_triple.gltf", Vector3(-2.2, 0.6, -10.5), Vector3.ONE * 1.5)
	_place_model(room, "res://assets/overworld/candle_triple.gltf", Vector3(2.2, 0.6, -10.5), Vector3.ONE * 1.5)
	_add_warm_light(room, Vector3(0, 3.8, -9.5), Color(1.0, 0.88, 0.55), 1.8, 9.0)
	
	# NPC: Royal Steward Alden
	var steward = TownNPC.new()
	steward.npc_id = "steward"
	steward.npc_name = "Steward Alden"
	steward.npc_title = "Royal Castellan"
	steward.icon = "👑"
	steward.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	steward.model_scale = Vector3(0.55, 0.55, 0.55)
	steward.model_rotation_y = 180.0
	steward.dialogue_text = "Welcome to the Grand Hall, champion. The Ossuary stirs below, and our King seeks heroes of fortitude. The royal chalice was lost to the northern ruins—bring it to me and receive the blessing of the Crown!"
	steward.position = Vector3(2.5, 0.6, -8.5)
	room.add_child(steward)
	
	# Exit Doorway back to Town Castle Exterior
	var exit_door = BuildingDoorway.new()
	exit_door.door_id = "castle_exit"
	exit_door.prompt_text = "[E] Exit Castle to Town"
	exit_door.target_position = Vector3(0.0, 0.2, 38.0) # In front of Overworld Castle Keep
	exit_door.target_rotation_y = 180.0
	exit_door.is_interior_exit = true
	exit_door.target_cam_distance = 16.0
	exit_door.target_cam_pitch = 48.0
	exit_door.position = Vector3(0.0, 0.0, 12.0)
	room.add_child(exit_door)

# --- 2. THE BOAR'S TUSK TAVERN INTERIOR ---
static func _build_tavern_interior(parent: Node3D) -> void:
	var room = Node3D.new()
	room.name = "Interior_Tavern"
	room.position = TAVERN_ORIGIN
	parent.add_child(room)
	
	# Floor (15m wide x 15m long)
	_add_room_box_collider(room, Vector3(0, -0.25, 0), Vector3(15.0, 0.5, 15.0))
	_create_room_floor(room, Vector3(15.0, 0.02, 15.0), Color(0.25, 0.18, 0.12), "res://assets/village/Floor_WoodDark.gltf")
	
	# Perimeter Walls (Height 4.5m)
	_add_wall_with_mesh(room, Vector3(0, 2.25, -7.5), Vector3(15.0, 4.5, 0.6), Color(0.40, 0.32, 0.24))
	_add_wall_with_mesh(room, Vector3(-7.5, 2.25, 0), Vector3(0.6, 4.5, 15.0), Color(0.40, 0.32, 0.24))
	_add_wall_with_mesh(room, Vector3(7.5, 2.25, 0), Vector3(0.6, 4.5, 15.0), Color(0.40, 0.32, 0.24))
	_add_wall_with_mesh(room, Vector3(-4.5, 2.25, 7.5), Vector3(6.0, 4.5, 0.6), Color(0.40, 0.32, 0.24))
	_add_wall_with_mesh(room, Vector3(4.5, 2.25, 7.5), Vector3(6.0, 4.5, 0.6), Color(0.40, 0.32, 0.24))
	
	# Cozy Fireplace on North Wall
	_place_model(room, "res://assets/furniture/fireplace.gltf", Vector3(0, 0, -6.8), Vector3.ONE * 2.2, 0.0)
	_add_warm_light(room, Vector3(0, 1.2, -5.5), Color(1.0, 0.60, 0.25), 2.2, 8.5)
	
	# Tavern Bar Counter along West Wall (X = -3.8)
	_add_box(room, Vector3(-3.8, 0.55, -2.0), Vector3(1.2, 1.1, 7.0), Color(0.32, 0.22, 0.15))
	for z in [-4.5, -3.0, -1.5, 0.0, 1.5]:
		_place_model(room, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-2.6, 0, z), Vector3.ONE * 1.5)
	
	# Shelves & Ale Barrels behind Bar Counter
	_place_model(room, "res://assets/furniture/shelf_B_large_decorated.gltf", Vector3(-6.5, 0, -2.5), Vector3.ONE * 1.6, 90.0)
	_place_model(room, "res://assets/overworld/barrel.gltf", Vector3(-5.8, 0, 0.5), Vector3.ONE * 1.8)
	_place_model(room, "res://assets/overworld/barrel.gltf", Vector3(-5.8, 0, -5.2), Vector3.ONE * 1.8)
	
	# Dining Tables in Center / East
	_place_model(room, "res://assets/furniture/table_medium_long.gltf", Vector3(2.5, 0, -1.5), Vector3.ONE * 1.6)
	_place_model(room, "res://assets/furniture/chair_A_wood.gltf", Vector3(2.5, 0, -2.8), Vector3.ONE * 1.4, 0.0)
	_place_model(room, "res://assets/furniture/chair_A_wood.gltf", Vector3(2.5, 0, -0.2), Vector3.ONE * 1.4, 180.0)
	_place_model(room, "res://assets/furniture/rug_oval_A.gltf", Vector3(2.5, 0.03, -1.5), Vector3(2.4, 1.0, 3.2))
	
	_place_model(room, "res://assets/furniture/table_medium_long.gltf", Vector3(2.5, 0, 3.5), Vector3.ONE * 1.6)
	_place_model(room, "res://assets/furniture/chair_A_wood.gltf", Vector3(2.5, 0, 2.2), Vector3.ONE * 1.4, 0.0)
	_place_model(room, "res://assets/furniture/chair_A_wood.gltf", Vector3(2.5, 0, 4.8), Vector3.ONE * 1.4, 180.0)
	
	# Warm tavern chandeliers
	_add_warm_light(room, Vector3(2.5, 3.2, 1.0), Color(1.0, 0.82, 0.50), 1.6, 9.0)
	_add_warm_light(room, Vector3(-4.5, 2.8, -2.0), Color(1.0, 0.78, 0.48), 1.4, 7.5)
	
	# NPC: Barkeep Barnaby (behind bar)
	var barkeep = TownNPC.new()
	barkeep.npc_id = "barkeep"
	barkeep.npc_name = "Barkeep Barnaby"
	barkeep.npc_title = "Tavern Master"
	barkeep.icon = "🍺"
	barkeep.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	barkeep.model_scale = Vector3(0.55, 0.55, 0.55)
	barkeep.model_rotation_y = 90.0
	barkeep.dialogue_text = "Welcome to The Boar's Tusk! Rest your boots by the hearth, traveler. Say, my granddad's secret spiced mead recipe scroll was lost near the old watchtower cemetery. If you retrieve it, I've got gold and my finest draughts for you!"
	barkeep.position = Vector3(-5.2, 0, -2.0)
	room.add_child(barkeep)
	
	# NPC: Bard Finn (near hearth)
	var bard = TownNPC.new()
	bard.npc_id = "bard"
	bard.npc_name = "Bard Finn"
	bard.npc_title = "Minstrel of Oakhaven"
	bard.icon = "🪕"
	bard.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	bard.model_scale = Vector3(0.52, 0.52, 0.52)
	bard.model_rotation_y = -45.0
	bard.dialogue_text = "Listen close to the embers, traveler... 'Beneath the stone, the ossuary sighs, where fallen kings and hollow shadows rise!' Keep your sword sharp when you step into the depths."
	bard.position = Vector3(3.8, 0, -5.2)
	room.add_child(bard)
	
	# Exit Doorway back to Town Tavern Exterior
	var exit_door = BuildingDoorway.new()
	exit_door.door_id = "tavern_exit"
	exit_door.prompt_text = "[E] Exit Tavern to Town"
	exit_door.target_position = Vector3(-8.0, 0.2, 17.5) # In front of Overworld Tavern patio
	exit_door.target_rotation_y = 90.0
	exit_door.is_interior_exit = true
	exit_door.target_cam_distance = 16.0
	exit_door.target_cam_pitch = 48.0
	exit_door.position = Vector3(0.0, 0.0, 6.8)
	room.add_child(exit_door)

# --- 3. MASTER TORVAL'S FORGE WORKSHOP ---
static func _build_forge_interior(parent: Node3D) -> void:
	var room = Node3D.new()
	room.name = "Interior_Forge"
	room.position = FORGE_ORIGIN
	parent.add_child(room)
	
	# Floor (13m wide x 13m long)
	_add_room_box_collider(room, Vector3(0, -0.25, 0), Vector3(13.0, 0.5, 13.0))
	_create_room_floor(room, Vector3(13.0, 0.02, 13.0), Color(0.28, 0.24, 0.22), "res://assets/village/Floor_RedBrick.gltf")
	
	# Perimeter Walls (Height 4.5m)
	_add_wall_with_mesh(room, Vector3(0, 2.25, -6.5), Vector3(13.0, 4.5, 0.6), Color(0.35, 0.32, 0.30))
	_add_wall_with_mesh(room, Vector3(-6.5, 2.25, 0), Vector3(0.6, 4.5, 13.0), Color(0.35, 0.32, 0.30))
	_add_wall_with_mesh(room, Vector3(6.5, 2.25, 0), Vector3(0.6, 4.5, 13.0), Color(0.35, 0.32, 0.30))
	_add_wall_with_mesh(room, Vector3(-3.8, 2.25, 6.5), Vector3(5.4, 4.5, 0.6), Color(0.35, 0.32, 0.30))
	_add_wall_with_mesh(room, Vector3(3.8, 2.25, 6.5), Vector3(5.4, 4.5, 0.6), Color(0.35, 0.32, 0.30))
	
	# Massive Smelting Furnace on North Wall
	_add_box(room, Vector3(0, 1.5, -5.5), Vector3(3.8, 3.0, 1.8), Color(0.25, 0.20, 0.18))
	_add_warm_light(room, Vector3(0, 1.2, -4.2), Color(1.0, 0.45, 0.15), 2.8, 7.5)
	
	# Heavy Anvil on Stump
	_place_model(room, "res://assets/overworld/anvil.gltf", Vector3(0, 0, -1.8), Vector3.ONE * 2.2)
	_place_model(room, "res://assets/overworld/bucket_water.gltf", Vector3(-1.8, 0, -1.8), Vector3.ONE * 1.5)
	
	# Ingot Stacks & Raw Ore Benches
	_place_model(room, "res://assets/overworld/ingot_stacked.gltf", Vector3(-4.5, 0, -3.5), Vector3.ONE * 2.0)
	_place_model(room, "res://assets/furniture/shelf_A_big.gltf", Vector3(-5.5, 0, 0.5), Vector3.ONE * 1.6, 90.0)
	_place_model(room, "res://assets/overworld/weaponrack.gltf", Vector3(5.5, 0, -2.5), Vector3.ONE * 1.8, -90.0)
	_place_model(room, "res://assets/overworld/weaponrack.gltf", Vector3(5.5, 0, 1.5), Vector3.ONE * 1.8, -90.0)
	
	# NPC: Master Torval (Inside the Workshop)
	var torval = TownNPC.new()
	torval.npc_id = "blacksmith"
	torval.npc_name = "Master Torval"
	torval.npc_title = "Grand Forge Smith"
	torval.icon = "⚒️"
	torval.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torval.model_scale = Vector3(0.55, 0.55, 0.55)
	torval.dialogue_text = "Step into the heart of the forge, warrior! My bellows roar day and night. If you bring me refined ingots from the ruined quarry, I'll hone your blade with razor lethality!"
	torval.position = Vector3(1.8, 0, -1.8)
	room.add_child(torval)
	
	# Exit Doorway back to Town Forge Exterior
	var exit_door = BuildingDoorway.new()
	exit_door.door_id = "forge_exit"
	exit_door.prompt_text = "[E] Exit Forge to Town"
	exit_door.target_position = Vector3(-11.5, 0.2, 0.0) # In front of Overworld Forge
	exit_door.target_rotation_y = 90.0
	exit_door.is_interior_exit = true
	exit_door.target_cam_distance = 16.0
	exit_door.target_cam_pitch = 48.0
	exit_door.position = Vector3(0.0, 0.0, 5.8)
	room.add_child(exit_door)

# --- 4. FARMER GILES'S THATCHED COTTAGE ---
static func _build_cottage_interior(parent: Node3D) -> void:
	var room = Node3D.new()
	room.name = "Interior_Cottage"
	room.position = COTTAGE_ORIGIN
	parent.add_child(room)
	
	# Floor (11m wide x 11m long)
	_add_room_box_collider(room, Vector3(0, -0.25, 0), Vector3(11.0, 0.5, 11.0))
	_create_room_floor(room, Vector3(11.0, 0.02, 11.0), Color(0.35, 0.28, 0.20), "res://assets/village/Floor_WoodLight.gltf")
	
	# Perimeter Walls (Height 4.0m)
	_add_wall_with_mesh(room, Vector3(0, 2.0, -5.5), Vector3(11.0, 4.0, 0.5), Color(0.48, 0.42, 0.35))
	_add_wall_with_mesh(room, Vector3(-5.5, 2.0, 0), Vector3(0.5, 4.0, 11.0), Color(0.48, 0.42, 0.35))
	_add_wall_with_mesh(room, Vector3(5.5, 2.0, 0), Vector3(0.5, 4.0, 11.0), Color(0.48, 0.42, 0.35))
	_add_wall_with_mesh(room, Vector3(-3.2, 2.0, 5.5), Vector3(4.6, 4.0, 0.5), Color(0.48, 0.42, 0.35))
	_add_wall_with_mesh(room, Vector3(3.2, 2.0, 5.5), Vector3(4.6, 4.0, 0.5), Color(0.48, 0.42, 0.35))
	
	# Cozy Bed in Corner
	_place_model(room, "res://assets/furniture/bed_double_A.gltf", Vector3(-3.6, 0, -3.4), Vector3.ONE * 1.5, 90.0)
	
	# Cupboard & Shelves
	_place_model(room, "res://assets/furniture/cabinet_medium_decorated.gltf", Vector3(3.8, 0, -4.8), Vector3.ONE * 1.5)
	_place_model(room, "res://assets/furniture/shelf_A_small.gltf", Vector3(4.8, 0, -2.0), Vector3.ONE * 1.5, -90.0)
	
	# Rustic Dining Table & Stools
	_place_model(room, "res://assets/furniture/table_low.gltf", Vector3(1.2, 0, 0.5), Vector3.ONE * 1.5)
	_place_model(room, "res://assets/furniture/chair_stool_wood.gltf", Vector3(1.2, 0, -0.6), Vector3.ONE * 1.4)
	_place_model(room, "res://assets/furniture/chair_stool_wood.gltf", Vector3(1.2, 0, 1.6), Vector3.ONE * 1.4)
	_place_model(room, "res://assets/furniture/rug_oval_A.gltf", Vector3(1.2, 0.02, 0.5), Vector3(2.0, 1.0, 2.6))
	
	# Warm interior cottage lighting
	_add_warm_light(room, Vector3(0.0, 2.6, 0.0), Color(1.0, 0.85, 0.55), 1.6, 7.5)
	
	# NPC: Elder Giles
	var giles = TownNPC.new()
	giles.npc_id = "farmer"
	giles.npc_name = "Elder Giles"
	giles.npc_title = "Village Patriarch"
	giles.icon = "🌾"
	giles.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	giles.model_scale = Vector3(0.55, 0.55, 0.55)
	giles.dialogue_text = "Good day, traveler. Welcome to our humble home. Ferocious timber wolves have crept out from the eastern woods and stalked our sheep pasture! If you can hunt 3 wolves, our hamlet will reward you with gold and soul echoes."
	giles.position = Vector3(2.4, 0, 0.5)
	room.add_child(giles)
	
	# Exit Doorway back to Town Thatched Cottage Exterior
	var exit_door = BuildingDoorway.new()
	exit_door.door_id = "cottage_exit"
	exit_door.prompt_text = "[E] Exit Cottage to Town"
	exit_door.target_position = Vector3(20.0, 0.2, 14.0) # In front of Overworld Thatched Cottage
	exit_door.target_rotation_y = -30.0
	exit_door.is_interior_exit = true
	exit_door.target_cam_distance = 16.0
	exit_door.target_cam_pitch = 48.0
	exit_door.position = Vector3(0.0, 0.0, 4.8)
	room.add_child(exit_door)

# --- REUSABLE UTILITIES ---
static func _add_room_box_collider(parent: Node3D, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body

static func _add_wall_with_mesh(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var body = _add_room_box_collider(parent, pos, size)
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	mesh_inst.position = pos

static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	_add_room_box_collider(parent, pos, size)
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	parent.add_child(mesh_inst)
	return mesh_inst

static func _create_room_floor(parent: Node3D, size: Vector3, color: Color, fallback_model: String) -> void:
	var floor_mesh = MeshInstance3D.new()
	var plane = BoxMesh.new()
	plane.size = size
	floor_mesh.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0, 0.01, 0)
	parent.add_child(floor_mesh)

static func _place_model(parent: Node3D, path: String, pos: Vector3, scale_vec: Vector3, rot_y_deg: float = 0.0) -> Node3D:
	var model = AssetLoader.load_or_generate_model(path, "prop", "interior_prop")
	if model:
		model.position = pos
		model.scale = scale_vec
		if rot_y_deg != 0.0:
			model.rotation_degrees.y = rot_y_deg
		parent.add_child(model)
		return model
	return null

static func _add_warm_light(parent: Node3D, pos: Vector3, color: Color, energy: float, light_range: float) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.2
	parent.add_child(light)
	return light
