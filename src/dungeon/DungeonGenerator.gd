extends Node3D
class_name DungeonGenerator

const RoomControllerScript = preload("res://src/dungeon/RoomController.gd")
const SpikeTrapScript = preload("res://src/dungeon/SpikeTrap.gd")
const TownNPCScript = preload("res://src/actors/TownNPC.gd")
const QuestMaterialNodeScript = preload("res://src/world/QuestMaterialNode.gd")
const AnimalAIScript = preload("res://src/actors/AnimalAI.gd")
const EnemyAIScript = preload("res://src/actors/EnemyAI.gd")
const WorldRepairStationScript = preload("res://src/world/WorldRepairStation.gd")
const PatrolNPCScript = preload("res://src/actors/PatrolNPC.gd")
const SiegeTrebuchet3DScript = preload("res://src/world/SiegeTrebuchet3D.gd")
const ArmyFormation3DScript = preload("res://src/actors/ArmyFormation3D.gd")
const MedievalShip3DScript = preload("res://src/world/MedievalShip3D.gd")
const HarborSeal3DScript = preload("res://src/actors/HarborSeal3D.gd")
const CaravanWagon3DScript = preload("res://src/actors/CaravanWagon3D.gd")
const InteractiveTarget3DScript = preload("res://src/world/InteractiveTarget3D.gd")
const CampfireRestSite3DScript = preload("res://src/world/CampfireRestSite3D.gd")
const AncientShrine3DScript = preload("res://src/world/AncientShrine3D.gd")
const MarketStall3DScript = preload("res://src/world/MarketStall3D.gd")
const HarborLadder3DScript = preload("res://src/world/HarborLadder3D.gd")
const HarborAlarmBell3DScript = preload("res://src/world/HarborAlarmBell3D.gd")
const HarborDefenseTower3DScript = preload("res://src/world/HarborDefenseTower3D.gd")
const EnemyNavalShip3DScript = preload("res://src/world/EnemyNavalShip3D.gd")
const HarborLighthouse3DScript = preload("res://src/world/HarborLighthouse3D.gd")
const ShipwreckCove3DScript = preload("res://src/world/ShipwreckCove3D.gd")
const ShipwrightDrydock3DScript = preload("res://src/world/ShipwrightDrydock3D.gd")
const HarborTavernTerrace3DScript = preload("res://src/world/HarborTavernTerrace3D.gd")
const HarborFishingSpot3DScript = preload("res://src/world/HarborFishingSpot3D.gd")
const DockworkerNPCScript = preload("res://src/actors/DockworkerNPC.gd")
const DestructibleProp3DScript = preload("res://src/world/DestructibleProp3D.gd")
const ChoppableTree3DScript = preload("res://src/world/ChoppableTree3D.gd")
const TownspersonNPCScript = preload("res://src/actors/TownspersonNPC.gd")
const EnemyShipAI3DScript = preload("res://src/actors/EnemyShipAI3D.gd")

# KayKit Dungeon strict 2.0m tile footprint
const TILE_SIZE: float = 2.0

# 2D Grid Cell Constants
const CELL_VOID: int = 0
const CELL_FLOOR: int = 1
const CELL_WALL: int = 2
const CELL_PILLAR: int = 3
const CELL_TORCH_WALL: int = 4
const CELL_SPIKE_TRAP: int = 5
const CELL_ENEMY_SPAWN: int = 6
const CELL_EXIT_DOOR: int = 7

func build_floor_room(floor_num: int) -> Node3D:
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	var room_ctrl = RoomControllerScript.new()
	room_ctrl.name = "RoomController"
	
	if floor_num == 0:
		room_ctrl.is_hub_room = true
		add_child(room_ctrl)
		_build_overworld_sanctuary(room_ctrl)
		return room_ctrl
	elif floor_num >= 5:
		room_ctrl.is_boss_room = true
		add_child(room_ctrl)
		var matrix = _generate_boss_matrix()
		_instantiate_matrix(room_ctrl, matrix)
	else:
		room_ctrl.is_hub_room = false
		add_child(room_ctrl)
		var matrix = _generate_chamber_matrix(floor_num)
		_instantiate_matrix(room_ctrl, matrix)
		
	return room_ctrl

func _generate_hub_matrix() -> Array:
	# 11x11 Grid Matrix (22m x 22m)
	var w = 11
	var h = 11
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x == 5 and z == 0) or (z == 5 and (x == 0 or x == w - 1)):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 2 or x == w - 3) and (z == 2 or z == h - 3):
				row.append(CELL_PILLAR)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _generate_chamber_matrix(_floor_num: int) -> Array:
	# 11x11 Grid Matrix for Combat Chambers
	var w = 11
	var h = 11
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x == 5 and (z == 0 or z == h - 1)) or (z == 5 and (x == 0 or x == w - 1)):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 2 or x == w - 3) and (z == 2 or z == h - 3):
				row.append(CELL_PILLAR)
			elif (x == 3 or x == w - 4) and (z == 3 or z == h - 4):
				row.append(CELL_SPIKE_TRAP)
			elif (x == 5 and (z == 2 or z == h - 3)) or (z == 5 and (x == 2 or x == w - 3)):
				row.append(CELL_ENEMY_SPAWN)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _generate_boss_matrix() -> Array:
	# 15x15 Grand Boss Arena
	var w = 15
	var h = 15
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x % 4 == 0) or (z % 4 == 0):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 3 or x == w - 4) and (z == 3 or z == h - 4):
				row.append(CELL_PILLAR)
			elif (x == 5 or x == w - 6) and (z == 5 or z == h - 6):
				row.append(CELL_PILLAR)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _instantiate_matrix(parent: Node3D, grid: Array) -> void:
	var rows = grid.size()
	var cols = grid[0].size()
	var offset_x = float(cols - 1) * TILE_SIZE * 0.5
	var offset_z = float(rows - 1) * TILE_SIZE * 0.5
	
	# Floor static collision body with safety perimeter padding
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(float(cols) * TILE_SIZE + 6.0, 1.2, float(rows) * TILE_SIZE + 6.0)
	col_shape.shape = box
	col_shape.position.y = -0.6
	floor_body.add_child(col_shape)
	parent.add_child(floor_body)
	
	# Collect enemy spawn points for the room controller
	var spawns: Array[Vector3] = []
	
	for z in range(rows):
		for x in range(cols):
			var cell = grid[z][x]
			var pos = Vector3(x * TILE_SIZE - offset_x, 0, z * TILE_SIZE - offset_z)
			
			if cell == CELL_VOID:
				continue
				
			# Base Floor under all active cells
			var floor_tile = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
			floor_tile.scale = Vector3(0.5, 1.0, 0.5) # Scale 4m base model to 2m
			floor_tile.position = pos
			parent.add_child(floor_tile)
			
			match cell:
				CELL_WALL, CELL_TORCH_WALL:
					var wall = AssetLoader.load_or_generate_model("res://assets/dungeon/wall.glb", "dungeon", "wall")
					wall.scale = Vector3(0.5, 1.0, 1.0)
					wall.position = pos
					parent.add_child(wall)
					
					# Wall physics
					var w_body = StaticBody3D.new()
					w_body.collision_layer = 1
					var w_col = CollisionShape3D.new()
					var w_box = BoxShape3D.new()
					w_box.size = Vector3(TILE_SIZE, 4.0, 0.8)
					w_col.shape = w_box
					w_col.position.y = 2.0
					w_body.add_child(w_col)
					wall.add_child(w_body)
					
					if cell == CELL_TORCH_WALL:
						_attach_torch_sconce(parent, pos)

				CELL_PILLAR:
					var pillar = AssetLoader.load_or_generate_model("res://assets/dungeon/pillar.glb", "dungeon", "pillar")
					pillar.position = pos
					parent.add_child(pillar)
					
					var p_body = StaticBody3D.new()
					p_body.collision_layer = 1
					var p_col = CollisionShape3D.new()
					var p_cyl = CylinderShape3D.new()
					p_cyl.radius = 0.5
					p_cyl.height = 3.5
					p_col.shape = p_cyl
					p_col.position.y = 1.75
					p_body.add_child(p_col)
					pillar.add_child(p_body)

				CELL_SPIKE_TRAP:
					var trap = SpikeTrapScript.new()
					trap.position = pos
					parent.add_child(trap)

				CELL_ENEMY_SPAWN:
					spawns.append(pos)
					
	if spawns.size() > 0:
		parent.enemy_spawn_points = spawns
		
	# Unbreakable perimeter barrier walls
	_build_perimeter_barrier(parent, cols, rows)

func _build_perimeter_barrier(parent: Node3D, cols: int, rows: int) -> void:
	var barrier_body = StaticBody3D.new()
	barrier_body.name = "PerimeterBarriers"
	barrier_body.collision_layer = 1 # Environment
	parent.add_child(barrier_body)
	
	var total_w = float(cols) * TILE_SIZE
	var total_d = float(rows) * TILE_SIZE
	var half_w = total_w * 0.5
	var half_d = total_d * 0.5
	var wall_height = 8.0
	var wall_thick = 2.0
	
	# North Barrier
	var n_col = CollisionShape3D.new()
	var n_box = BoxShape3D.new()
	n_box.size = Vector3(total_w + 8.0, wall_height, wall_thick)
	n_col.shape = n_box
	n_col.position = Vector3(0, wall_height * 0.5, -half_d - wall_thick * 0.5 + TILE_SIZE * 0.5)
	barrier_body.add_child(n_col)
	
	# South Barrier
	var s_col = CollisionShape3D.new()
	var s_box = BoxShape3D.new()
	s_box.size = Vector3(total_w + 8.0, wall_height, wall_thick)
	s_col.shape = s_box
	s_col.position = Vector3(0, wall_height * 0.5, half_d + wall_thick * 0.5 - TILE_SIZE * 0.5)
	barrier_body.add_child(s_col)
	
	# West Barrier
	var w_col = CollisionShape3D.new()
	var w_box = BoxShape3D.new()
	w_box.size = Vector3(wall_thick, wall_height, total_d + 8.0)
	w_col.shape = w_box
	w_col.position = Vector3(-half_w - wall_thick * 0.5 + TILE_SIZE * 0.5, wall_height * 0.5, 0)
	barrier_body.add_child(w_col)
	
	# East Barrier
	var e_col = CollisionShape3D.new()
	var e_box = BoxShape3D.new()
	e_box.size = Vector3(wall_thick, wall_height, total_d + 8.0)
	e_col.shape = e_box
	e_col.position = Vector3(half_w + wall_thick * 0.5 - TILE_SIZE * 0.5, wall_height * 0.5, 0)
	barrier_body.add_child(e_col)

func _attach_torch_sconce(parent: Node3D, pos: Vector3) -> void:
	var torch = AssetLoader.load_or_generate_model("res://assets/dungeon/torch_lit.glb", "dungeon", "torch_lit")
	torch.position = pos
	parent.add_child(torch)
	
	# Sinusoidal noise torch light
	var light = torch.find_child("TorchLight", true, false)
	if not light:
		light = OmniLight3D.new()
		light.name = "TorchLight"
		light.position = Vector3(0, 2.0, 0.3)
		torch.add_child(light)
		
	light.light_color = Color(1.0, 0.55, 0.23) # Warm #ff8c3b
	light.omni_range = 9.0
	light.shadow_enabled = true
	light.add_to_group("nocturnal_lights")
	
	# Add flicker script
	var flicker = Node.new()
	flicker.set_script(_create_torch_flicker_script())
	light.add_child(flicker)

func _create_torch_flicker_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """extends Node
var _time: float = 0.0
@onready var parent_light: OmniLight3D = get_parent() as OmniLight3D
func _ready():
	_time = randf_range(0.0, 100.0)
func _process(delta: float):
	if parent_light:
		_time += delta
		var noise = sin(_time * 12.0) * 0.18 + sin(_time * 23.5) * 0.1 + sin(_time * 41.2) * 0.06
		parent_light.light_energy = 1.8 + noise
"""
	s.reload()
	return s

# --- SURFACE OVERWORLD SANCTUARY HUB & OPEN WORLD REALM ---
func _build_overworld_sanctuary(parent: Node3D) -> void:
	var ground_size = 260.0
	var half_s = ground_size * 0.5
	
	# 1. Slotted Floor Static Collision & Safety Void Safeguard (River & Ocean Harbor Basin cutouts)
	var floor_body = StaticBody3D.new()
	floor_body.name = "OverworldFloorColliders"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0

	var add_f_col = func(b_size: Vector3, b_pos: Vector3):
		var cs = CollisionShape3D.new()
		var bx = BoxShape3D.new()
		bx.size = b_size
		cs.shape = bx
		cs.position = b_pos
		floor_body.add_child(cs)

	# North Bank Floor (X: -137 to 137, Z: -137 to 20.0)
	add_f_col.call(Vector3(274.0, 1.2, 157.0), Vector3(0.0, -0.6, -58.5))
	# South-Central & East Landmass Floor (X: -62.0 to 137.0, Z: 28.0 to 137.0)
	add_f_col.call(Vector3(199.0, 1.2, 109.0), Vector3(37.5, -0.6, 82.5))
	# South-West Coastal Headland Floor (X: -137.0 to -62.0, Z: 28.0 to 46.0)
	add_f_col.call(Vector3(75.0, 1.2, 18.0), Vector3(-99.5, -0.6, 37.0))
	# Sunken Ocean Harbor Seabed Floor (Expanded open sea X: -210.0 to -62.0, Z: 46.0 to 210.0 at Y = -1.20m)
	add_f_col.call(Vector3(148.0, 1.2, 164.0), Vector3(-136.0, -1.80, 128.0))
	# Sunken Riverbed Floor (X: -137 to 137, Z: 20.0 to 28.0 at Y = -0.50m)
	add_f_col.call(Vector3(274.0, 1.2, 8.0), Vector3(0.0, -1.10, 24.0))

	# Impassable Riverbank Collision Barriers (Prevents walking on water; players must cross via the Bridges)
	# Openings at Western Wooden Bridge (X in [-19.8, -16.2]) and Central Stone Bridge (X in [-2.1, 2.1])
	add_f_col.call(Vector3(117.2, 3.5, 0.4), Vector3(-78.4, 1.5, 20.0))
	add_f_col.call(Vector3(14.1, 3.5, 0.4), Vector3(-9.15, 1.5, 20.0))
	add_f_col.call(Vector3(134.9, 3.5, 0.4), Vector3(69.55, 1.5, 20.0))
	add_f_col.call(Vector3(117.2, 3.5, 0.4), Vector3(-78.4, 1.5, 28.0))
	add_f_col.call(Vector3(14.1, 3.5, 0.4), Vector3(-9.15, 1.5, 28.0))
	add_f_col.call(Vector3(134.9, 3.5, 0.4), Vector3(69.55, 1.5, 28.0))

	# Ocean Quay Shoreline Collision Barriers (along X = -62.0 and Z = 46.0)
	# Pier 1 at Z=62 (Z in [59.6, 64.4]), Pier 2 at Z=82 (Z in [79.6, 84.4]), Harbor Sea Stairs at Z=72 (Z in [70.4, 73.6]), and Golden Beach Cove (Z in [86.5, 114.0]) are fully open for water egress!
	add_f_col.call(Vector3(75.0, 3.5, 0.4), Vector3(-99.5, 1.5, 46.0))
	add_f_col.call(Vector3(0.4, 3.5, 13.6), Vector3(-62.0, 1.5, 52.8)) # Z: 46.0 to 59.6
	add_f_col.call(Vector3(0.4, 3.5, 6.0), Vector3(-62.0, 1.5, 67.4))  # Z: 64.4 to 70.4
	# Z: 70.4 to 73.6 is the open passage for Stone Harbor Sea Stairs!
	add_f_col.call(Vector3(0.4, 3.5, 6.0), Vector3(-62.0, 1.5, 76.6))  # Z: 73.6 to 79.6
	add_f_col.call(Vector3(0.4, 3.5, 2.1), Vector3(-62.0, 1.5, 85.45)) # Z: 84.4 to 86.5
	# Z: 86.5 to 114.0 is Golden Beach Cove: completely OPEN for swimming and walking onto the sand!
	add_f_col.call(Vector3(0.4, 3.5, 23.0), Vector3(-62.0, 1.5, 125.5)) # Z: 114.0 to 137.0

	parent.add_child(floor_body)
	
	# Visual Overworld Slotted Grass Landscape (Reveals the sunken River Z in [20, 28] and Ocean Basin X < -62, Z > 46)
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.20, 0.38, 0.16) # Rich medieval pasture green
	g_mat.roughness = 0.92

	var add_grass_plane = func(p_name: String, p_size: Vector2, p_pos: Vector3):
		var g_mesh_inst = MeshInstance3D.new()
		g_mesh_inst.name = p_name
		var pm = PlaneMesh.new()
		pm.size = p_size
		g_mesh_inst.mesh = pm
		g_mesh_inst.material_override = g_mat
		g_mesh_inst.position = p_pos
		parent.add_child(g_mesh_inst)

	add_grass_plane.call("NorthBank_Grass", Vector2(274.0, 157.0), Vector3(0.0, 0.0, -58.5))
	add_grass_plane.call("SouthBank_Grass", Vector2(199.0, 109.0), Vector3(37.5, 0.0, 82.5))
	add_grass_plane.call("WestHeadland_Grass", Vector2(75.0, 18.0), Vector3(-99.5, 0.0, 37.0))
	
	# Outer world perimeter boundary collision barriers (Expanded SW naval theater)
	var wall_h = 18.0
	var thick = 4.0
	_add_static_box(parent, Vector3(0, wall_h * 0.5, -half_s - thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	# South boundary: land segment on East (X from -62 to 137), Ocean segment pushed out to Z = 210 (X from -210 to -62)
	_add_static_box(parent, Vector3(37.5, wall_h * 0.5, half_s + thick * 0.5), Vector3(199.0 + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(-136.0, wall_h * 0.5, 210.0 + thick * 0.5), Vector3(148.0 + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(half_s + thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))
	# West boundary: North segment on Land (Z from -137 to 46), Ocean segment pushed out to X = -210 (Z from 46 to 210)
	_add_static_box(parent, Vector3(-half_s - thick * 0.5, wall_h * 0.5, -45.5), Vector3(thick, wall_h, 183.0))
	_add_static_box(parent, Vector3(-210.0 - thick * 0.5, wall_h * 0.5, 128.0), Vector3(thick, wall_h, 164.0))

	# Encircling Natural Perimeter Mountain Ridges (Spaced cleanly at 20m intervals, open at SW Ocean Coast)
	for perim_idx in range(-6, 7):
		var offset_p = float(perim_idx) * 20.0
		# North Ridge
		_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(offset_p, 0.0, -half_s), Vector3.ONE * 8.5)
		# South Ridge (Only on land X > -50, leaving SW Ocean horizon open)
		if offset_p > -50.0 and abs(offset_p) > 22.0:
			_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(offset_p, 0.0, half_s), Vector3.ONE * 8.5)
		# East Ridge (mountain crags, skipping river channel Z in [14, 34])
		if offset_p < 12.0 or offset_p > 36.0:
			_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(half_s, 0.0, offset_p), Vector3.ONE * 8.5)
		# West Ridge (only North of the river Z < 14, leaving the Ocean Coast open to the sea)
		if offset_p < 14.0:
			_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(-half_s, 0.0, offset_p), Vector3.ONE * 8.5)

	# 2. Central Cobblestone Sanctuary Plaza (Spacious paved courtyard X in [-13, 13], Z in [-11, 13])
	var plaza_mesh_inst = MeshInstance3D.new()
	plaza_mesh_inst.name = "SanctuaryCobblestonePlaza"
	var p_plane = PlaneMesh.new()
	p_plane.size = Vector2(26.0, 24.0)
	var plaza_mat = StandardMaterial3D.new()
	var brick_tex = load("res://assets/village/T_UnevenBrick_BaseColor.png")
	if brick_tex:
		plaza_mat.albedo_texture = brick_tex
		plaza_mat.uv1_scale = Vector3(8.0, 7.5, 1.0)
	else:
		plaza_mat.albedo_color = Color(0.42, 0.40, 0.38)
	var brick_norm = load("res://assets/village/T_UnevenBrick_Normal.png")
	if brick_norm:
		plaza_mat.normal_enabled = true
		plaza_mat.normal_texture = brick_norm
	plaza_mat.roughness = 0.88
	plaza_mesh_inst.mesh = p_plane
	plaza_mesh_inst.material_override = plaza_mat
	plaza_mesh_inst.position = Vector3(0.0, 0.02, 1.0)
	parent.add_child(plaza_mesh_inst)

	# Decorative Carved Stone Curb Border around the Plaza
	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.32, 0.30, 0.28)
	curb_mat.roughness = 0.92
	for curb_edge in [
		{"size": Vector3(26.4, 0.08, 0.4), "pos": Vector3(0.0, 0.04, -11.0)},
		{"size": Vector3(26.4, 0.08, 0.4), "pos": Vector3(0.0, 0.04, 13.0)},
		{"size": Vector3(0.4, 0.08, 24.0), "pos": Vector3(-13.0, 0.04, 1.0)},
		{"size": Vector3(0.4, 0.08, 24.0), "pos": Vector3(13.0, 0.04, 1.0)}
	]:
		var curb = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = curb_edge["size"]
		c_mesh.material = curb_mat
		curb.mesh = c_mesh
		curb.position = curb_edge["pos"]
		parent.add_child(curb)

	# 3. North: The Ancient Crypt (Proportionate mausoleum set back at Z = -16.5 so DescentSigil at Z = -6.5 has a clear forecourt)
	var crypt = AssetLoader.load_or_generate_model("res://assets/overworld/crypt.gltf", "dungeon", "crypt")
	crypt.scale = Vector3(1.65, 1.65, 1.65)
	crypt.position = Vector3(0.0, 0.0, -16.5)
	parent.add_child(crypt)
	_add_static_box(parent, Vector3(0.0, 3.2, -16.5), Vector3(9.5, 6.5, 9.5))
	
	# Wrought-iron/stone cemetery flanking the Crypt (Well clear of the plaza)
	_place_prop(parent, "res://assets/overworld/tree_dead_medium.gltf", Vector3(-9.5, 0.0, -16.0), Vector3.ONE * 2.0)
	_place_prop(parent, "res://assets/overworld/tree_dead_medium.gltf", Vector3(9.5, 0.0, -16.0), Vector3.ONE * 2.0, 75.0)
	_place_prop(parent, "res://assets/overworld/grave_A.gltf", Vector3(-6.8, 0.0, -12.5), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/gravestone.gltf", Vector3(6.8, 0.0, -12.5), Vector3.ONE * 1.6, -15.0)
	_place_prop(parent, "res://assets/overworld/grave_A_destroyed.gltf", Vector3(-8.5, 0.0, -12.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/gravemarker_A.gltf", Vector3(8.5, 0.0, -12.5), Vector3.ONE * 1.6)

	# Circling Crows Flock above North Crypt
	var flock_crypt = CirclingFlock.new()
	flock_crypt.position = Vector3(0.0, 16.0, -16.5)
	flock_crypt.bird_count = 6
	flock_crypt.circle_radius = 9.0
	parent.add_child(flock_crypt)

	# 4. West: Master Torval's Blacksmith Forge (Set cleanly at X = -18.5, Z = -1.0, facing East toward the Plaza)
	var smith = AssetLoader.load_or_generate_model("res://assets/overworld/building_blacksmith_blue.gltf", "dungeon", "blacksmith")
	smith.scale = Vector3.ONE * 6.5
	smith.position = Vector3(-18.5, 0.0, -1.0)
	smith.rotation_degrees.y = 90.0
	parent.add_child(smith)
	_add_static_box(parent, Vector3(-18.5, 3.5, -1.0), Vector3(8.2, 7.0, 8.2))
	AmbientFX.create_chimney_smoke(parent, Vector3(-18.5, 6.8, -2.0))

	# Master Torval - Town Blacksmith NPC
	var torval = TownNPCScript.new()
	torval.npc_id = "blacksmith"
	torval.npc_name = "Master Torval"
	torval.npc_title = "Forge Master"
	torval.icon = "⚒️"
	torval.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	torval.model_scale = Vector3(0.52, 0.52, 0.52)
	torval.model_rotation_y = 90.0
	torval.dialogue_text = "Hail, warrior! The forge fires blaze with eternal embers. Deliver unto me the Soul Echoes reaped from the Ossuary depths, and I shall temper your weapons, bolster your armor, and sharpen your dash reflexes!"
	torval.position = Vector3(-12.2, 0.0, -1.0)
	parent.add_child(torval)

	# Blacksmith forge outdoor workbench props (Neatly beside the forge, clear of the plaza)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-14.0, 0.0, -4.8), Vector3.ONE * 1.4, 90.0)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-12.5, 0.0, -4.5), Vector3.ONE * 1.4, 0.0)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-13.8, 0.0, 2.8), Vector3.ONE * 1.6, 90.0)

	# 5. East: The Cathedral of Light (Set cleanly at X = 18.5, Z = -1.0, facing West toward the Plaza)
	var church = AssetLoader.load_or_generate_model("res://assets/overworld/building_church_blue.gltf", "dungeon", "church")
	church.scale = Vector3.ONE * 8.2
	church.position = Vector3(18.5, 0.0, -1.0)
	church.rotation_degrees.y = -90.0
	parent.add_child(church)
	_add_static_box(parent, Vector3(18.5, 6.0, -1.0), Vector3(8.8, 12.0, 9.5))

	# Eldress Alyssa - High Priestess NPC
	var alyssa = TownNPCScript.new()
	alyssa.npc_id = "priestess"
	alyssa.npc_name = "Eldress Alyssa"
	alyssa.npc_title = "Sanctuary Priestess"
	alyssa.icon = "✨"
	alyssa.model_path = "res://assets/characters/adventurers/Mage.glb"
	alyssa.model_scale = Vector3(0.53, 0.53, 0.53)
	alyssa.model_rotation_y = -90.0
	alyssa.dialogue_text = "May the Sacred Light guide your steps, champion. The dead stir restlessly in the Catacombs below. Inquire upon our Sanctuary Bounties—purge the wicked hordes to claim divine favour and rich reward!"
	alyssa.position = Vector3(12.2, 0.0, -1.0)
	parent.add_child(alyssa)

	# Cathedral forecourt benches (Symmetrical & aligned facing the Cathedral)
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(12.5, 0.0, -4.2), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(12.5, 0.0, 2.2), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(13.5, 0.0, -5.2), Vector3.ONE * 1.8, -90.0)

	# Cathedral Altar of Dawn Ancient Shrine
	var dawn_shrine = AncientShrine3DScript.new()
	dawn_shrine.shrine_type = AncientShrine3DScript.ShrineType.DAWN
	dawn_shrine.shrine_name = "Altar of Dawn (Cathedral)"
	dawn_shrine.position = Vector3(18.5, 0.0, -8.5)
	parent.add_child(dawn_shrine)

	# Royal Falconer Caelen - Oakhaven Huntsman NPC
	var caelen = TownNPCScript.new()
	caelen.npc_id = "royal_falconer"
	caelen.npc_name = "Caelen"
	caelen.npc_title = "Royal Falconer"
	caelen.icon = "🦅"
	caelen.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
	caelen.model_scale = Vector3(0.52, 0.52, 0.52)
	caelen.model_rotation_y = 180.0
	caelen.dialogue_text = "My hunting falcons scout the skies from the High Crags to the Weeping Fen. Strange darkness stirs within the catacombs below. Tread with vigilant eyes, warrior!"
	caelen.position = Vector3(8.5, 0.0, -4.8)
	parent.add_child(caelen)

	# 6. South: Fortified Arch Gateway (Interactive Animated Portcullis Doors with Physics)
	var OverworldGateScript = preload("res://src/world/OverworldGate.gd")
	var gate = OverworldGateScript.new()
	gate.name = "SanctuaryArchGate"
	gate.position = Vector3(0.0, 0.0, 14.0)
	parent.add_child(gate)

	# Captain Vane - Gate Sentinel NPC
	var vane = TownNPCScript.new()
	vane.npc_id = "guard"
	vane.npc_name = "Captain Vane"
	vane.npc_title = "Gate Sentinel"
	vane.icon = "🛡️"
	vane.model_path = "res://assets/characters/adventurers/Knight.glb"
	vane.model_scale = Vector3(0.55, 0.55, 0.55)
	vane.model_rotation_y = 160.0
	vane.dialogue_text = "Halt, warrior! You stand before the threshold of the Ossuary Catacombs. Beneath the north crypt lies the descent sigil. Step upon the glowing seal to plunge into the underworld. Beware the Bone Titan's wrath on the final floor!"
	vane.position = Vector3(-2.8, 0.0, 11.8)
	parent.add_child(vane)

	# Fortified Town Defensive Curtain Walls (Flanking the South Arch Gateway at Z = 14.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-6.0, 0.0, 14.0), Vector3(3.6, 3.8, 2.4))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-13.0, 0.0, 14.0), Vector3(3.6, 3.8, 2.4))
	_place_prop(parent, "res://assets/overworld/building_tower_A_blue.gltf", Vector3(-18.5, 0.0, 14.0), Vector3.ONE * 5.0)
	_add_static_box(parent, Vector3(-10.5, 3.0, 14.0), Vector3(16.0, 6.0, 2.5))

	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(6.0, 0.0, 14.0), Vector3(3.6, 3.8, 2.4))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(13.0, 0.0, 14.0), Vector3(3.6, 3.8, 2.4))
	_place_prop(parent, "res://assets/overworld/building_tower_A_blue.gltf", Vector3(18.5, 0.0, 14.0), Vector3.ONE * 5.0)
	_add_static_box(parent, Vector3(10.5, 3.0, 14.0), Vector3(16.0, 6.0, 2.5))

	# Outer Sanctuary Framing Trees (Placed along the North ridge at Z = -20 so zero canopies clip town buildings)
	var border_trees = [
		Vector3(-22.0, 0.0, -18.0), Vector3(-14.0, 0.0, -22.0), Vector3(14.0, 0.0, -22.0), Vector3(22.0, 0.0, -18.0)
	]
	var tree_paths = [
		"res://assets/overworld/tree_single_A.gltf",
		"res://assets/overworld/tree_single_B.gltf",
		"res://assets/overworld/tree_pine_orange_medium.gltf",
		"res://assets/overworld/tree_pine_yellow_medium.gltf"
	]
	for i in range(border_trees.size()):
		var t_pos = border_trees[i]
		var model_p = tree_paths[i % tree_paths.size()]
		_place_prop(parent, model_p, t_pos, Vector3.ONE * 2.0, float((i * 47) % 360))
		_add_static_cyl(parent, t_pos, 0.8, 6.0)

	# Neat Courtyard Perimeter Props (Placed along the interior wall edges at Z = 11.5, clear of walkways and pedestals)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-5.5, 0.0, 12.2), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-6.4, 0.0, 12.4), Vector3.ONE * 1.1)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(5.5, 0.0, 12.2), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(6.6, 0.0, 12.0), Vector3.ONE * 1.1)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(6.2, 0.0, 12.7), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/bench_decorated.gltf", Vector3(-8.5, 0.0, 5.5), Vector3.ONE * 1.6, 90.0)
	_place_prop(parent, "res://assets/overworld/bench_decorated.gltf", Vector3(8.5, 0.0, 5.5), Vector3.ONE * 1.6, -90.0)

	# Friendly Town Fox resting in the Courtyard Garden
	_spawn_animated_fauna(parent, "res://assets/characters/animals/Fox.glb", Vector3(-9.2, 0.0, 7.5), Vector3.ONE * 0.12, 45.0, "AnimalArmature|Idle")

	# Oakhaven Town Square Patrolling Guards (Continuous marching walk cycles)
	var guard_highway = PatrolNPCScript.new()
	guard_highway.npc_name = "Sentry Brand"
	guard_highway.position = Vector3(1.8, 0.0, 10.0)
	guard_highway.waypoints = [
		Vector3(1.8, 0.0, 11.5),
		Vector3(1.8, 0.0, 4.2),
		Vector3(-1.8, 0.0, 4.2),
		Vector3(-1.8, 0.0, 11.5)
	]
	parent.add_child(guard_highway)

	var guard_cross = PatrolNPCScript.new()
	guard_cross.npc_name = "Patrolman Kaelen"
	guard_cross.position = Vector3(-6.0, 0.0, -3.5)
	guard_cross.waypoints = [
		Vector3(-9.0, 0.0, -3.5),
		Vector3(9.0, 0.0, -3.5),
		Vector3(9.0, 0.0, -5.0),
		Vector3(-9.0, 0.0, -5.0)
	]
	parent.add_child(guard_cross)

	# Merchant Supply Caches in South-West Courtyard Corner (Destructible with loot drops)
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.CARGO_CRATE, "res://assets/overworld/crate_A_big.gltf", Vector3(-10.5, 0.0, 10.5), Vector3.ONE * 1.4, 0.0, "gold")
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.WOODEN_BARREL, "res://assets/overworld/barrel.gltf", Vector3(-9.5, 0.0, 10.8), Vector3.ONE * 1.3, 0.0, "bread")
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(-12.5, 0.0, 10.5), Vector3.ONE * 1.3)
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.CARGO_CRATE, "res://assets/overworld/crate_long_A.gltf", Vector3(-12.5, 0.0, 10.5), Vector3.ONE * 1.2, 0.0, "arrows")

	# 7. EXPANDED OPEN WORLD MEDIEVAL REALM
	_build_road_network(parent)
	_build_town_quarter(parent)
	_build_town_population(parent)
	_build_river_and_bridges(parent)
	_build_riverside_meadow_and_props(parent)
	_build_farmlands_hamlet(parent)
	_build_castle_citadel(parent)
	_build_blackwood_forest(parent)
	_build_iron_mountains(parent)
	_build_forgotten_ruins(parent)

	# NEW REGIONAL BIOMES, HARBORS & MOUNTAINS
	_build_port_blackwater_region(parent)
	_build_whisperwood_forest_region(parent)
	_build_khar_drakken_crags_region(parent)
	_build_weeping_fen_swamp_region(parent)
	_build_siege_encampment_and_battlefield(parent)
	_build_greenhollow_village_and_caravans(parent)
	_build_crossroads_and_highroads(parent)

	# 8. SUBTERRANEAN INTERIOR CHAMBERS & ENTERABLE DOORWAYS
	_build_enterable_building_doorways(parent)
	InteriorsManager.build_all_interiors(parent)

func _build_road_network(parent: Node3D) -> void:
	# 1. Main Royal Highway: Sanctuary South Gate (Z=14) -> Central Stone Bridge (Z=24) -> Castle Citadel Gate (Z=36)
	for z_step in range(14, 46, 2):
		if z_step >= 20 and z_step <= 27:
			continue # Handled by the Central Stone Bridge
		for rx in range(-1, 2):
			_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(float(rx) * 1.9, 0.02, float(z_step)), Vector3(1.1, 1.0, 1.1))
		
	# 2. West Town Market Street: runs West from Main Highway at Z = 16.5 to X = -48.0 (passing Tavern, Market & Herbalist)
	for step in range(1, 26):
		var x_pos = -float(step) * 1.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 16.5), Vector3(1.1, 1.0, 1.1))
		if x_pos >= -46.0 and x_pos <= -22.0:
			_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 14.6), Vector3(1.1, 1.0, 1.1))

	# 3. East Mill & Archery Path: runs East north of river to Watermill Yard (X = 24.5, Z = 16.5) and North-East to Archery Green
	for step in range(1, 13):
		var x_pos = float(step) * 1.95
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 16.5), Vector3(1.1, 1.0, 1.1))

	# 4. South-East Sunnydale Hamlet Road: runs East on the South Bank from Main Highway (X = 2, Z = 33.5) to Sunnydale Green & Windmill (X = 50, Z = 33.5)
	for step in range(1, 26):
		var p_x = float(step) * 1.95
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(p_x, 0.02, 33.5), Vector3(1.15, 1.0, 1.15))
		if p_x >= 26.0 and p_x <= 42.0:
			_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(p_x, 0.02, 35.4), Vector3(1.15, 1.0, 1.15))

	# 5. Mountain Trail: North-East from Cathedral toward Iron Mountains & Khar-Drakken
	for step in range(0, 14):
		var t = float(step) / 13.0
		var p = Vector3(lerp(22.0, 36.0, t), 0.02, lerp(-4.0, -22.0, t))
		_place_prop(parent, "res://assets/overworld/path_A.gltf", p, Vector3(1.2, 1.0, 1.2), -38.0)

	# 6. Ancient Ruins Trail: North-West from Blacksmith toward Forgotten Ruins & Greenhollow
	for step in range(0, 12):
		var t = float(step) / 11.0
		var p = Vector3(lerp(-22.0, -36.0, t), 0.02, lerp(-3.0, -6.0, t))
		_place_prop(parent, "res://assets/overworld/path_A.gltf", p, Vector3(1.2, 1.0, 1.2), 15.0)

func _build_town_quarter(parent: Node3D) -> void:
	# =========================================================================
	# WEST TOWN MARKET STREET (North Side of Street at Z = 8.5..9.5, facing South onto Z = 15.5)
	# =========================================================================
	# 1. The Boar's Tusk Tavern (X = -26.0, Z = 8.5, facing South 0° onto Beer Garden & Street)
	_place_prop(parent, "res://assets/overworld/building_tavern_blue.gltf", Vector3(-26.0, 0.0, 8.5), Vector3.ONE * 6.2, 0.0)
	_add_static_box(parent, Vector3(-26.0, 4.5, 8.5), Vector3(7.4, 9.0, 8.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-26.0, 8.2, 8.0))
	
	# Tavern Beer Garden Patio (In front of Tavern at Z = 13.0..14.0, clear of river & walls)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-23.0, 0.0, 12.8), Vector3.ONE * 1.5, 0.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-22.0, 0.0, 12.8), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-24.0, 0.0, 12.8), Vector3.ONE * 1.4)
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.WOODEN_BARREL, "res://assets/overworld/barrel.gltf", Vector3(-29.2, 0.0, 12.2), Vector3.ONE * 1.3, 0.0, "bread")
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.WOODEN_BARREL, "res://assets/overworld/barrel.gltf", Vector3(-28.4, 0.0, 12.5), Vector3.ONE * 1.1, 0.0, "gold")

	# NPC: Barnaby the Barkeep
	var barkeep = TownNPCScript.new()
	barkeep.npc_id = "barkeep"
	barkeep.npc_name = "Barnaby"
	barkeep.npc_title = "Tavern Keeper"
	barkeep.icon = "🍺"
	barkeep.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	barkeep.model_scale = Vector3(0.52, 0.52, 0.52)
	barkeep.model_rotation_y = 0.0
	barkeep.dialogue_text = "Rest your weary bones, adventurer! A tankard of spiced cider cures all curses. Mind the talk of shadows in the Blackwood Forest... folks say the trees have eyes!"
	barkeep.position = Vector3(-24.2, 0.0, 13.2)
	parent.add_child(barkeep)

	# NPC: Lyra the Minstrel / Realm Bard (Singing & entertaining patrons on the tavern terrace)
	var lyra = TownNPCScript.new()
	lyra.npc_id = "bard_lyra"
	lyra.npc_name = "Lyra the Minstrel"
	lyra.npc_title = "Realm Troubadour"
	lyra.icon = "🎵"
	lyra.model_path = "res://assets/characters/adventurers/Mage.glb"
	lyra.model_scale = Vector3(0.52, 0.52, 0.52)
	lyra.model_rotation_y = -90.0
	lyra.dialogue_text = "*Strums a lively lute ballad*\n'Of ossuary depths and heroes bold, who braved the dark and seized the gold!' Greetings, champion! Would you care to hear a song of the ancient high kings?"
	lyra.position = Vector3(-20.5, 0.0, 13.0)
	parent.add_child(lyra)

	# 2. Sanctuary Marketplace (Beside Tavern at X = -36.0, Z = 9.5, facing South 0° onto Street)
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-36.0, 0.0, 9.5), Vector3.ONE * 4.4, 0.0)
	_add_static_box(parent, Vector3(-36.0, 2.5, 9.5), Vector3(7.4, 5.0, 5.8))
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.CARGO_CRATE, "res://assets/overworld/crate_A_big.gltf", Vector3(-33.2, 0.0, 12.5), Vector3.ONE * 1.3, 0.0, "gold")
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.CARGO_CRATE, "res://assets/overworld/crate_open.gltf", Vector3(-38.8, 0.0, 12.5), Vector3.ONE * 1.2, 0.0, "bread")
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(-38.0, 0.0, 13.0), Vector3.ONE * 1.4)

	# Interactive Oakhaven Provisions Market Stall
	var oakhaven_stall = MarketStall3DScript.new()
	oakhaven_stall.stall_name = "Oakhaven Fresh Provisions"
	oakhaven_stall.canopy_color = "green"
	oakhaven_stall.position = Vector3(-31.5, 0.0, 10.2)
	parent.add_child(oakhaven_stall)

	# Interactive Sanctuary Waystation Campfire (Right by the southern crossroads)
	var town_campfire = CampfireRestSite3DScript.new()
	town_campfire.site_name = "Sanctuary Waystation Hearth"
	town_campfire.position = Vector3(0.0, 0.0, 8.5)
	parent.add_child(town_campfire)

	# NPC: Merchant Corin
	var merchant = TownNPCScript.new()
	merchant.npc_id = "merchant"
	merchant.npc_name = "Corin"
	merchant.npc_title = "Traveling Merchant"
	merchant.icon = "💰"
	merchant.model_path = "res://assets/characters/adventurers/Rogue.glb"
	merchant.model_scale = Vector3(0.53, 0.53, 0.53)
	merchant.model_rotation_y = 0.0
	merchant.dialogue_text = "Finest goods from across the realm! Weapons tempered in dwarven fire and draughts brewed by eastern alchemists. Bring me ancient relics from the catacombs and I will pay a handsome fortune!"
	merchant.position = Vector3(-35.5, 0.0, 13.2)
	parent.add_child(merchant)

	# 3. Apothecary & Herbalist Stall (X = -44.5, Z = 9.5, facing South 0° onto Street)
	_place_prop(parent, "res://assets/overworld/building_market_yellow.gltf", Vector3(-44.5, 0.0, 9.5), Vector3.ONE * 4.2, 0.0)
	_add_static_box(parent, Vector3(-44.5, 2.5, 9.5), Vector3(6.8, 5.0, 5.5))
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-47.5, 0.0, 12.2), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-42.0, 0.0, 12.4), Vector3.ONE * 1.2)

	var herbalist = TownNPCScript.new()
	herbalist.npc_id = "herbalist"
	herbalist.npc_name = "Elowen"
	herbalist.npc_title = "Master Apothecary & Herbalist"
	herbalist.icon = "🌿"
	herbalist.model_path = "res://assets/characters/adventurers/Mage.glb"
	herbalist.model_scale = Vector3(0.52, 0.52, 0.52)
	herbalist.model_rotation_y = 0.0
	herbalist.dialogue_text = "Greetings, wanderer! Fresh moon-sage, mountain thistle, and soothing draughts to cleanse wounds. Stay vigilant against the foul pestilence rising from the tombs!"
	herbalist.position = Vector3(-44.5, 0.0, 13.2)
	parent.add_child(herbalist)

	# 4. Guard Archery Training Yard (Dedicated East Sanctuary Green: X = 32.0, Z = 2.0, facing West -90° toward targets)
	_place_prop(parent, "res://assets/overworld/building_archeryrange_blue.gltf", Vector3(34.0, 0.0, 2.0), Vector3.ONE * 4.5, -90.0)
	_add_static_box(parent, Vector3(34.0, 3.5, 2.0), Vector3(7.0, 7.5, 7.0))
	var target_1 = InteractiveTarget3DScript.new()
	target_1.position = Vector3(26.5, 0.0, 0.5)
	target_1.rotation_degrees.y = 90.0
	parent.add_child(target_1)

	var target_2 = InteractiveTarget3DScript.new()
	target_2.position = Vector3(26.5, 0.0, 3.5)
	target_2.rotation_degrees.y = 90.0
	parent.add_child(target_2)
	_place_prop(parent, "res://assets/overworld/bucket_arrows.gltf", Vector3(29.5, 0.0, 0.8), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(29.5, 0.0, 4.2), Vector3.ONE * 1.6, 0.0)

	# NPC: Cadet Ronin - Sanctuary Marksman practicing at the target
	var archer = TownNPCScript.new()
	archer.npc_id = "archer_apprentice"
	archer.npc_name = "Cadet Ronin"
	archer.npc_title = "Sanctuary Marksman"
	archer.icon = "🎯"
	archer.model_path = "res://assets/characters/adventurers/Rogue.glb"
	archer.model_scale = Vector3(0.53, 0.53, 0.53)
	archer.model_rotation_y = -90.0
	archer.dialogue_text = "Steady breath, steady aim! Captain Vane says the outlaws in Whisperwood won't wait for us to draw. Practice makes lethal!"
	archer.position = Vector3(30.0, 0.0, 2.0)
	parent.add_child(archer)

	# 5. East Granary & Flour Mill Warehouse (X = 43.5, Z = 4.5, facing West -90°)
	_place_prop(parent, "res://assets/overworld/building_barracks_blue.gltf", Vector3(43.5, 0.0, 4.5), Vector3.ONE * 4.8, -90.0)
	_add_static_box(parent, Vector3(43.5, 3.5, 4.5), Vector3(6.5, 6.5, 6.5))
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(39.0, 0.0, 3.2), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(39.0, 0.0, 5.8), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(39.0, 0.0, 7.2), Vector3.ONE * 1.3)

	# NPC: Dennis the Miller's Apprentice
	var dennis = TownNPCScript.new()
	dennis.npc_id = "miller_apprentice"
	dennis.npc_name = "Dennis"
	dennis.npc_title = "Granary Storeman"
	dennis.icon = "🌾"
	dennis.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	dennis.model_scale = Vector3(0.52, 0.52, 0.52)
	dennis.model_rotation_y = -90.0
	dennis.dialogue_text = "Flour sacks stacked high for the royal bakehouses! Between Miller Bronn's waterwheel and Farmer Giles's harvest, Oakhaven never hungers."
	dennis.position = Vector3(38.0, 0.0, 4.5)
	parent.add_child(dennis)

	# 6. Street Lantern Posts along Thoroughfares
	_place_lantern_post(parent, Vector3(-3.2, 0.0, 15.2), 0.0)
	_place_lantern_post(parent, Vector3(3.2, 0.0, 15.2), 0.0)
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 19.8))
	_place_lantern_post(parent, Vector3(2.8, 0.0, 19.8))
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 28.2), 180.0)
	_place_lantern_post(parent, Vector3(2.8, 0.0, 28.2), 180.0)
	_place_lantern_post(parent, Vector3(-21.5, 0.0, 15.0))
	_place_lantern_post(parent, Vector3(-31.0, 0.0, 15.0))
	_place_lantern_post(parent, Vector3(-40.5, 0.0, 15.0))

# =========================================================================
# 7B. DYNAMIC TOWN POPULATION & CITIZENRY (26 Lively NPCs across 4 Districts)
# =========================================================================
func _build_town_population(parent: Node3D) -> void:
	# -------------------------------------------------------------------------
	# DISTRICT 1: GRAND MARKET SQUARE (Sanctuary Plaza Courtyard)
	# -------------------------------------------------------------------------
	var harlan = TownspersonNPCScript.new()
	harlan.citizen_name = "Harlan"
	harlan.citizen_title = "Grain Merchant"
	harlan.role = TownspersonNPCScript.NPCRole.VENDOR
	harlan.model_path = "res://assets/characters/adventurers/Rogue.glb"
	harlan.icon = "🌾"
	harlan.trade_items = [{"name": "Barley Bread", "cost": 4}, {"name": "Sack of Oats", "cost": 8}]
	harlan.speech_barks = [
		"Finest barley and rye from Greenhollow!",
		"Fresh bread for your journeys, champion!",
		"Flour sacks fresh from Miller Bronn's wheel!"
	]
	harlan.position = Vector3(-8.5, 0.0, 8.5)
	parent.add_child(harlan)

	var maeve = TownspersonNPCScript.new()
	maeve.citizen_name = "Maeve"
	maeve.citizen_title = "Sanctuary Herbalist"
	maeve.role = TownspersonNPCScript.NPCRole.VENDOR
	maeve.model_path = "res://assets/characters/adventurers/Mage.glb"
	maeve.icon = "🌿"
	maeve.trade_items = [{"name": "Mountain Herb Draught", "cost": 12}, {"name": "Bandage Bundle", "cost": 6}]
	maeve.speech_barks = [
		"Wild mountain herbs and dried lavender!",
		"A drop of elderflower for the weary traveler!",
		"Cleanse the tomb miasma with fresh feverfew!"
	]
	maeve.position = Vector3(8.5, 0.0, 8.5)
	parent.add_child(maeve)

	var cedric = TownspersonNPCScript.new()
	cedric.citizen_name = "Cedric"
	cedric.citizen_title = "Fishmonger"
	cedric.role = TownspersonNPCScript.NPCRole.VENDOR
	cedric.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	cedric.icon = "🐟"
	cedric.speech_barks = [
		"Fresh river trout and silver bream!",
		"Salted herring straight from Port Blackwater!",
		"Caught this morning at the river weir!"
	]
	cedric.position = Vector3(-6.2, 0.0, 9.5)
	parent.add_child(cedric)

	var oestred = TownspersonNPCScript.new()
	oestred.citizen_name = "Town Crier Oestred"
	oestred.citizen_title = "Voice of the Crown"
	oestred.role = TownspersonNPCScript.NPCRole.TOWN_CRIER
	oestred.model_path = "res://assets/characters/adventurers/Knight.glb"
	oestred.icon = "📢"
	oestred.speech_barks = [
		"Hear ye, hear ye! By royal decree of King Aldric IV!",
		"Beware! Red Skull Corsairs sighted in the outer shoals!",
		"All able citizens to report suspicious tomb omens!",
		"Long live the High King and the Light of Oakhaven!"
	]
	oestred.waypoints = [
		Vector3(0.0, 0.0, 6.0),
		Vector3(3.0, 0.0, 9.0),
		Vector3(-3.0, 0.0, 9.0)
	]
	oestred.position = Vector3(0.0, 0.0, 6.5)
	parent.add_child(oestred)

	var ronald = TownspersonNPCScript.new()
	ronald.citizen_name = "Ronald the Minstrel"
	ronald.citizen_title = "Wandering Troubadour"
	ronald.role = TownspersonNPCScript.NPCRole.MINSTREL
	ronald.model_path = "res://assets/characters/adventurers/Mage.glb"
	ronald.icon = "🎶"
	ronald.speech_barks = [
		"*Strums lute* In the ossuary dark, heroes leave their mark...",
		"A copper coin for a verse of the Dragon of Drakken!",
		"Sing high, sing low, wherever brave adventurers go!"
	]
	ronald.position = Vector3(10.5, 0.0, 2.5)
	parent.add_child(ronald)

	var pip = TownspersonNPCScript.new()
	pip.citizen_name = "Pip"
	pip.citizen_title = "Town Youth"
	pip.role = TownspersonNPCScript.NPCRole.CHILD
	pip.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	pip.model_scale = Vector3(0.35, 0.35, 0.35)
	pip.icon = "🏃"
	pip.speech_barks = ["Tag! You're it!", "Look at the champion's sword!", "Bet you can't catch me!"]
	pip.waypoints = [
		Vector3(-3.0, 0.0, 7.5),
		Vector3(1.0, 0.0, 10.5),
		Vector3(-2.0, 0.0, 8.5)
	]
	pip.position = Vector3(-3.0, 0.0, 7.5)
	parent.add_child(pip)

	var tommy = TownspersonNPCScript.new()
	tommy.citizen_name = "Tommy"
	tommy.citizen_title = "Town Youth"
	tommy.role = TownspersonNPCScript.NPCRole.CHILD
	tommy.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	tommy.model_scale = Vector3(0.35, 0.35, 0.35)
	tommy.icon = "🏃"
	tommy.speech_barks = ["Wait for me, Pip!", "I'm gonna be a knight one day!", "Did you see that warhorse?"]
	tommy.waypoints = [
		Vector3(2.5, 0.0, 7.5),
		Vector3(-1.5, 0.0, 10.5),
		Vector3(3.0, 0.0, 8.5)
	]
	tommy.position = Vector3(2.5, 0.0, 7.5)
	parent.add_child(tommy)

	var barnaby_beggar = TownspersonNPCScript.new()
	barnaby_beggar.citizen_name = "Old Barnaby"
	barnaby_beggar.citizen_title = "Fen War Veteran"
	barnaby_beggar.role = TownspersonNPCScript.NPCRole.BEGGAR
	barnaby_beggar.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	barnaby_beggar.icon = "🪙"
	barnaby_beggar.speech_barks = [
		"Spare a copper for an old soldier of the Fen Wars...",
		"May the Light shield you when night falls, champion.",
		"I took a spear in the shoulder so this realm could stand."
	]
	barnaby_beggar.position = Vector3(-5.5, 0.0, 8.0)
	parent.add_child(barnaby_beggar)

	var genevieve = TownspersonNPCScript.new()
	genevieve.citizen_name = "Lady Genevieve"
	genevieve.citizen_title = "Noble Patron"
	genevieve.role = TownspersonNPCScript.NPCRole.CITIZEN
	genevieve.model_path = "res://assets/characters/adventurers/Mage.glb"
	genevieve.icon = "👒"
	genevieve.speech_barks = [
		"The market looks lively today, thank the heavens.",
		"Let us hope the Citadel guards keep the roads safe.",
		"Splendid morning for a stroll across the sanctuary."
	]
	genevieve.waypoints = [
		Vector3(5.0, 0.0, 0.5),
		Vector3(5.0, 0.0, 7.5),
		Vector3(1.0, 0.0, 7.5)
	]
	genevieve.position = Vector3(5.0, 0.0, 0.5)
	parent.add_child(genevieve)

	var silas_vendor = TownspersonNPCScript.new()
	silas_vendor.citizen_name = "Silas"
	silas_vendor.citizen_title = "Tool Chandler"
	silas_vendor.role = TownspersonNPCScript.NPCRole.VENDOR
	silas_vendor.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
	silas_vendor.icon = "🔧"
	silas_vendor.trade_items = [{"name": "Iron Nails & Tacks", "cost": 3}, {"name": "Lumber Plank", "cost": 5}]
	silas_vendor.speech_barks = [
		"Sturdy nails, hempen rope, and forged tools!",
		"Everything needed to mend wagons and palisades!"
	]
	silas_vendor.position = Vector3(6.5, 0.0, 7.0)
	parent.add_child(silas_vendor)

	# -------------------------------------------------------------------------
	# DISTRICT 2: CRAFTSMAN ROW & FORGE QUARTER (West Sector)
	# -------------------------------------------------------------------------
	var bram = TownspersonNPCScript.new()
	bram.citizen_name = "Bram"
	bram.citizen_title = "Armorer"
	bram.role = TownspersonNPCScript.NPCRole.VENDOR
	bram.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	bram.icon = "🛡️"
	bram.trade_items = [{"name": "Riveted Buckler", "cost": 25}, {"name": "Reinforced Bracers", "cost": 18}]
	bram.speech_barks = [
		"Steel shields, banded mail, and iron rivets!",
		"No monster claw breaches Oakhaven iron!",
		"Master Torval forged the blades; I craft the shields!"
	]
	bram.position = Vector3(-14.5, 0.0, 1.5)
	parent.add_child(bram)

	var eamon = TownspersonNPCScript.new()
	eamon.citizen_name = "Eamon"
	eamon.citizen_title = "Forge Apprentice"
	eamon.role = TownspersonNPCScript.NPCRole.CITIZEN
	eamon.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	eamon.icon = "🔨"
	eamon.speech_barks = [
		"More charcoal for Master Torval's bellows!",
		"Watch out for the flying anvil sparks!",
		"Tempering eighty spearheads by nightfall!"
	]
	eamon.waypoints = [
		Vector3(-13.5, 0.0, -3.5),
		Vector3(-16.0, 0.0, -1.0)
	]
	eamon.position = Vector3(-13.5, 0.0, -3.5)
	parent.add_child(eamon)

	var orson = TownspersonNPCScript.new()
	orson.citizen_name = "Orson"
	orson.citizen_title = "Master Carpenter"
	orson.role = TownspersonNPCScript.NPCRole.CITIZEN
	orson.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	orson.icon = "🪓"
	orson.speech_barks = [
		"Solid oak timber for the fortress gates!",
		"Carts, wagons, and siege beams crafted true.",
		"The Blackwood timber makes the strongest hafts."
	]
	orson.position = Vector3(-15.5, 0.0, -5.5)
	parent.add_child(orson)

	var gareth = TownspersonNPCScript.new()
	gareth.citizen_name = "Gareth"
	gareth.citizen_title = "Leather Tanner"
	gareth.role = TownspersonNPCScript.NPCRole.CITIZEN
	gareth.model_path = "res://assets/characters/adventurers/Rogue.glb"
	gareth.icon = "👞"
	gareth.speech_barks = [
		"Sturdy oxhide boots and boiled leather cuirasses!",
		"Salted cured hides ready for the cobbler."
	]
	gareth.position = Vector3(-19.0, 0.0, 4.0)
	parent.add_child(gareth)

	# -------------------------------------------------------------------------
	# DISTRICT 3: CATHEDRAL PLAZA & CLOISTERS (East Sector)
	# -------------------------------------------------------------------------
	var austin = TownspersonNPCScript.new()
	austin.citizen_name = "Brother Austin"
	austin.citizen_title = "Monastic Caretaker"
	austin.role = TownspersonNPCScript.NPCRole.MONK
	austin.model_path = "res://assets/characters/adventurers/Mage.glb"
	austin.icon = "📜"
	austin.speech_barks = [
		"Peace be upon your path, child of light.",
		"The dawn shall always overcome the deep shadows.",
		"Lighting the tallow candles for those departed."
	]
	austin.waypoints = [
		Vector3(14.0, 0.0, -3.0),
		Vector3(17.0, 0.0, -6.0)
	]
	austin.position = Vector3(14.0, 0.0, -3.0)
	parent.add_child(austin)

	var beatrice = TownspersonNPCScript.new()
	beatrice.citizen_name = "Sister Beatrice"
	beatrice.citizen_title = "Sanctuary Acolyte"
	beatrice.role = TownspersonNPCScript.NPCRole.MONK
	beatrice.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	beatrice.icon = "✨"
	beatrice.speech_barks = [
		"Holy water vials blessed at the Altar of Dawn.",
		"Prayers for the valiant souls fallen in the crypts.",
		"May the sacred light preserve your heart from malice."
	]
	beatrice.position = Vector3(14.5, 0.0, 1.0)
	parent.add_child(beatrice)

	var galahad = TownspersonNPCScript.new()
	galahad.citizen_name = "Pilgrim Galahad"
	galahad.citizen_title = "Devout Traveler"
	galahad.role = TownspersonNPCScript.NPCRole.CITIZEN
	galahad.model_path = "res://assets/characters/adventurers/Knight.glb"
	galahad.icon = "🚶"
	galahad.speech_barks = [
		"I journeyed from the border marches to seek the cathedral's grace.",
		"The road was perilous, but faith carried my stride."
	]
	galahad.position = Vector3(16.5, 0.0, 5.0)
	parent.add_child(galahad)

	var matthew = TownspersonNPCScript.new()
	matthew.citizen_name = "Scholar Matthew"
	matthew.citizen_title = "Antiquarian"
	matthew.role = TownspersonNPCScript.NPCRole.CITIZEN
	matthew.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
	matthew.icon = "📖"
	matthew.speech_barks = [
		"The runic script upon the north crypt predates our realm by centuries!",
		"Ancient High Kings sealed a terrifying terror below..."
	]
	matthew.position = Vector3(15.0, 0.0, -8.0)
	parent.add_child(matthew)

	# -------------------------------------------------------------------------
	# DISTRICT 4: HARBOR QUAY & WATERFRONT PROMENADE (Port Blackwater)
	# -------------------------------------------------------------------------
	var kren = TownspersonNPCScript.new()
	kren.citizen_name = "Dockmaster Kren"
	kren.citizen_title = "Port Master"
	kren.role = TownspersonNPCScript.NPCRole.VENDOR
	kren.model_path = "res://assets/characters/adventurers/Rogue.glb"
	kren.icon = "🧭"
	kren.trade_items = [{"name": "Naval Compass", "cost": 15}, {"name": "Sea Biscuit", "cost": 2}]
	kren.speech_barks = [
		"Charts of the outer reefs and naval tides!",
		"All ship manifests must be stamped before mooring!",
		"Keep clear of the outer shoals—pirate cogs roam free!"
	]
	kren.position = Vector3(-55.0, 0.04, 60.0)
	parent.add_child(kren)

	var jax = TownspersonNPCScript.new()
	jax.citizen_name = "Sailor Jax"
	jax.citizen_title = "Able Seaman"
	jax.role = TownspersonNPCScript.NPCRole.CITIZEN
	jax.model_path = "res://assets/characters/adventurers/Adventurer.glb"
	jax.icon = "⚓"
	jax.speech_barks = [
		"Aye, the Red Skull cog was spotted off the barrier arch!",
		"Tie fast the bow hawsers before the tide turns!",
		"Nothing like salt spray in the morning to clear the head!"
	]
	jax.position = Vector3(-60.5, 0.04, 64.0)
	parent.add_child(jax)

	var boros = TownspersonNPCScript.new()
	boros.citizen_name = "Stevedore Boros"
	boros.citizen_title = "Harbor Porter"
	boros.role = TownspersonNPCScript.NPCRole.CITIZEN
	boros.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	boros.icon = "📦"
	boros.speech_barks = [
		"Heave! Another barrel of spiced rum for the tavern!",
		"Watch your boots on the slick deck timbers!",
		"Heavy cargo moving through, make way!"
	]
	boros.waypoints = [
		Vector3(-58.0, 0.04, 68.0),
		Vector3(-58.0, 0.04, 78.0)
	]
	boros.position = Vector3(-58.0, 0.04, 68.0)
	parent.add_child(boros)

	var greta = TownspersonNPCScript.new()
	greta.citizen_name = "Fishwife Greta"
	greta.citizen_title = "Fishmonger"
	greta.role = TownspersonNPCScript.NPCRole.CITIZEN
	greta.model_path = "res://assets/characters/adventurers/Mage.glb"
	greta.icon = "🐟"
	greta.speech_barks = [
		"Fresh crabs and rock cod from the deep bay!",
		"Smoked mackerel that will keep all winter!"
	]
	greta.position = Vector3(-54.5, 0.04, 80.0)
	parent.add_child(greta)

	var drake = TownspersonNPCScript.new()
	drake.citizen_name = "Watchman Drake"
	drake.citizen_title = "Harbor Guard"
	drake.role = TownspersonNPCScript.NPCRole.WATCH_PATROL
	drake.model_path = "res://assets/characters/adventurers/Knight.glb"
	drake.icon = "🛡️"
	drake.speech_barks = [
		"Keep the quay clear! Watch the outer horizon for raiders!",
		"Port Blackwater stands garrisoned and watchful!",
		"No unauthorized skiffs near the military docks!"
	]
	drake.waypoints = [
		Vector3(-60.0, 0.04, 52.0),
		Vector3(-60.0, 0.04, 84.0)
	]
	drake.position = Vector3(-60.0, 0.04, 52.0)
	parent.add_child(drake)

	var ned = TownspersonNPCScript.new()
	ned.citizen_name = "Ned"
	ned.citizen_title = "Harbor Lad"
	ned.role = TownspersonNPCScript.NPCRole.CHILD
	ned.model_path = "res://assets/characters/adventurers/Rogue.glb"
	ned.model_scale = Vector3(0.35, 0.35, 0.35)
	ned.icon = "⛵"
	ned.speech_barks = [
		"Look at the big warship with the crimson sails!",
		"I saw a sea turtle by the lighthouse rock!",
		"Can I skip stones into the ocean?"
	]
	ned.position = Vector3(-52.0, 0.04, 75.0)
	parent.add_child(ned)

	# -------------------------------------------------------------------------
	# CITY WATCH & PERIMETER SENTINELS
	# -------------------------------------------------------------------------
	var captain_ronald = TownspersonNPCScript.new()
	captain_ronald.citizen_name = "Watch Captain Ronald"
	captain_ronald.citizen_title = "West Gate Commander"
	captain_ronald.role = TownspersonNPCScript.NPCRole.WATCH_PATROL
	captain_ronald.model_path = "res://assets/characters/adventurers/Knight.glb"
	captain_ronald.icon = "⚔️"
	captain_ronald.speech_barks = [
		"All clear along West Market Street! Stay vigilant!",
		"Keep your blades sheathed in town, travelers!",
		"Citadel sentries report all quiet on the highroad."
	]
	captain_ronald.waypoints = [
		Vector3(-4.0, 0.0, 16.0),
		Vector3(-18.0, 0.0, 16.0)
	]
	captain_ronald.position = Vector3(-4.0, 0.0, 16.0)
	parent.add_child(captain_ronald)

	var sergeant_wayne = TownspersonNPCScript.new()
	sergeant_wayne.citizen_name = "Sergeant Wayne"
	sergeant_wayne.citizen_title = "East Rampart Warden"
	sergeant_wayne.role = TownspersonNPCScript.NPCRole.WATCH_PATROL
	sergeant_wayne.model_path = "res://assets/characters/adventurers/Knight.glb"
	sergeant_wayne.icon = "⚔️"
	sergeant_wayne.speech_barks = [
		"East boundary secure! Eyes peeled on the mountain crags!",
		"Patrol rotation on schedule. Stand firm!"
	]
	sergeant_wayne.waypoints = [
		Vector3(2.0, 0.0, 16.0),
		Vector3(20.0, 0.0, 16.0)
	]
	sergeant_wayne.position = Vector3(2.0, 0.0, 16.0)
	parent.add_child(sergeant_wayne)

func _place_lantern_post(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var post = _place_prop(parent, "res://assets/overworld/post_lantern.gltf", pos, Vector3.ONE * 1.1, rot_y)
	var light = OmniLight3D.new()
	light.name = "LanternLight"
	light.light_color = Color(1.0, 0.78, 0.45) # Warm medieval lantern
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position = Vector3(0.0, 3.2, 0.0)
	light.add_to_group("nocturnal_lights")
	post.add_child(light)
	return post

func _spawn_animated_fauna(parent: Node3D, model_path: String, pos: Vector3, sc: Vector3, rot_y: float, anim_name: String) -> Node3D:
	var scene = load(model_path)
	if not scene:
		return null
	var inst = scene.instantiate()
	inst.position = pos
	inst.scale = sc
	inst.rotation_degrees.y = rot_y
	parent.add_child(inst)
	var anim: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation(anim_name):
		var a_res = anim.get_animation(anim_name)
		if a_res:
			a_res.loop_mode = Animation.LOOP_LINEAR
		anim.play(anim_name)
		anim.speed_scale = randf_range(0.85, 1.15)
	return inst

func _build_riverside_meadow_and_props(parent: Node3D) -> void:
	# 1. North-West Riverside Bank (X in [-14, -4], Z in [17.5, 19.5] — open grassy bank south of Curtain Wall)
	_place_prop(parent, "res://assets/overworld/tree_single_A.gltf", Vector3(-8.5, 0.0, 18.5), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-5.2, 0.0, 19.2), Vector3.ONE * 1.5, 25.0)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(-11.8, 0.0, 19.2), Vector3.ONE * 1.6, -45.0)

	# 2. North-East Riverside Bank (X in [4, 10], Z in [17.5, 19.5])
	_place_prop(parent, "res://assets/overworld/tree_single_B.gltf", Vector3(7.5, 0.0, 18.5), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(5.2, 0.0, 19.2), Vector3.ONE * 1.4)

	# 3. South-West River Meadow (X in [-15, -5], Z in [29, 34] — open grazing glade north-west of Citadel)
	_place_prop(parent, "res://assets/overworld/tree_single_B.gltf", Vector3(-10.5, 0.0, 30.5), Vector3.ONE * 2.0)
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-7.5, 0.0, 31.5), Vector3.ONE * 1.8, 40.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-9.2, 0.0, 31.5), 60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-12.5, 0.0, 30.5), -45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-7.0, 0.0, 32.5), 110.0)

func _build_river_and_bridges(parent: Node3D) -> void:
	# 1. Sunken Riverbed Silt/Pebble Basin (Y = -0.50m) across the full 274m realm width
	var bed_mesh_inst = MeshInstance3D.new()
	bed_mesh_inst.name = "RiverbedVisual"
	var b_mesh = PlaneMesh.new()
	b_mesh.size = Vector2(274.0, 8.0)
	bed_mesh_inst.mesh = b_mesh
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.12, 0.16, 0.13) # Dark wet river silt and smooth stones
	b_mat.roughness = 0.95
	bed_mesh_inst.material_override = b_mat
	bed_mesh_inst.position = Vector3(0.0, -0.50, 24.0)
	parent.add_child(bed_mesh_inst)

	# 2. Continuous River Water Surface (Y = -0.15m, recessed below ground level)
	var river_mesh_inst = MeshInstance3D.new()
	river_mesh_inst.name = "RiverWaterSurface"
	var r_mesh = PlaneMesh.new()
	r_mesh.size = Vector2(274.0, 8.0)
	river_mesh_inst.mesh = r_mesh
	var w_mat = ShaderMaterial.new()
	w_mat.shader = load("res://shaders/river_flow.gdshader")
	river_mesh_inst.material_override = w_mat
	river_mesh_inst.position = Vector3(0.0, -0.15, 24.0)
	parent.add_child(river_mesh_inst)

	# 3. Vertical Earth/Stone Embankment Walls lining the river edges
	var bank_mat = StandardMaterial3D.new()
	bank_mat.albedo_color = Color(0.16, 0.20, 0.14)
	bank_mat.roughness = 0.92

	var n_bank = MeshInstance3D.new()
	n_bank.name = "NorthRiverbankWall"
	var nb_mesh = BoxMesh.new()
	nb_mesh.size = Vector3(274.0, 0.50, 0.12)
	n_bank.mesh = nb_mesh
	n_bank.material_override = bank_mat
	n_bank.position = Vector3(0.0, -0.25, 20.0)
	parent.add_child(n_bank)

	var s_bank = MeshInstance3D.new()
	s_bank.name = "SouthRiverbankWall"
	var sb_mesh = BoxMesh.new()
	sb_mesh.size = Vector3(274.0, 0.50, 0.12)
	s_bank.mesh = sb_mesh
	s_bank.material_override = bank_mat
	s_bank.position = Vector3(0.0, -0.25, 28.0)
	parent.add_child(s_bank)

	# 4. Natural Stone Riverbanks: spaced rocks lining North Bank (Z=19.7) and South Bank (Z=28.3)
	for rx in range(-18, 19, 3):
		var x_f = float(rx) * 2.5
		# Skip where bridges cross (X ~ 0 and X ~ -18) and watermill wheel (X ~ 24.5)
		if abs(x_f) > 4.5 and abs(x_f - (-18.0)) > 4.5 and abs(x_f - 24.5) > 5.5:
			var r_model = "res://assets/overworld/rock_single_A.gltf" if (rx % 2 == 0) else "res://assets/overworld/rock_single_B.gltf"
			_place_prop(parent, r_model, Vector3(x_f, 0.0, 19.7), Vector3(1.3, 1.0, 1.3), float((rx * 37) % 360))
			_place_prop(parent, r_model, Vector3(x_f + 1.2, 0.0, 28.3), Vector3(1.3, 1.0, 1.3), float((rx * 53) % 360))

	# Water lilies and river reeds in the water
	_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", Vector3(-8.0, -0.10, 23.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterlily_B.gltf", Vector3(6.0, -0.10, 24.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", Vector3(-5.0, -0.10, 21.2), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(10.0, 0.02, 26.8), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/waterplant_C.gltf", Vector3(-25.0, 0.02, 22.5), Vector3.ONE * 1.6)

	# Main Highway Stone Arch Bridge (Smoothly Walkable Arched Highway at X = 0.0)
	_build_walkable_stone_bridge(parent, Vector3(0.0, 0.0, 24.0), Vector3(4.0, 3.2, 7.5))

	# Western Wooden Footbridge (Smoothly Walkable Planked Footbridge at X = -18.0)
	_build_walkable_wooden_bridge(parent, Vector3(-18.0, 0.0, 24.0), Vector3(3.6, 2.8, 7.0))

	# Riverside Watermill with Rotating Wheel Submerged Directly in the Flowing River Water (X = 24.5, clear of East Sanctuary Tower at X = 18.5)
	_build_watermill_and_canal(parent, Vector3(24.5, -0.38, 20.8))

func _build_walkable_stone_bridge(parent: Node3D, pos: Vector3, sc: Vector3) -> void:
	var bridge_prop = _place_prop(parent, "res://assets/overworld/building_bridge_A.gltf", pos, sc)
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.68, 0.65, 0.62)
	stone_mat.roughness = 0.88
	var b_tex = load("res://assets/village/T_UnevenBrick_BaseColor.png")
	if b_tex:
		stone_mat.albedo_texture = b_tex
		stone_mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
	var n_tex = load("res://assets/village/T_UnevenBrick_Normal.png")
	if n_tex:
		stone_mat.normal_enabled = true
		stone_mat.normal_texture = n_tex
	var r_tex = load("res://assets/village/T_UnevenBrick_Roughness.png")
	if r_tex:
		stone_mat.roughness_texture = r_tex
	for mi in bridge_prop.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = stone_mat
	
	var sb = StaticBody3D.new()
	sb.name = "StoneBridgeRamps"
	sb.collision_layer = 1
	sb.collision_mask = 0
	
	# North Approach Ramp (Slopes up smoothly from ground level Y=0.0 to crest Y=0.52)
	var r_north_shape = BoxShape3D.new()
	r_north_shape.size = Vector3(4.2, 0.25, 4.2)
	var r_north_col = CollisionShape3D.new()
	r_north_col.shape = r_north_shape
	r_north_col.position = pos + Vector3(0.0, 0.26, -2.6)
	r_north_col.rotation_degrees.x = -8.0
	sb.add_child(r_north_col)
	
	# Center Arch Crest (Smooth flat road deck spanning across the river at Y=0.52)
	var r_center_shape = BoxShape3D.new()
	r_center_shape.size = Vector3(4.2, 0.25, 2.8)
	var r_center_col = CollisionShape3D.new()
	r_center_col.shape = r_center_shape
	r_center_col.position = pos + Vector3(0.0, 0.52, 0.0)
	sb.add_child(r_center_col)
	
	# South Approach Ramp (Slopes down smoothly from crest Y=0.52 to ground level Y=0.0)
	var r_south_shape = BoxShape3D.new()
	r_south_shape.size = Vector3(4.2, 0.25, 4.2)
	var r_south_col = CollisionShape3D.new()
	r_south_col.shape = r_south_shape
	r_south_col.position = pos + Vector3(0.0, 0.26, 2.6)
	r_south_col.rotation_degrees.x = 8.0
	sb.add_child(r_south_col)
	
	# Left Guardrail Barrier (East edge)
	var rail_l_col = CollisionShape3D.new()
	var rail_l_shape = BoxShape3D.new()
	rail_l_shape.size = Vector3(0.5, 1.8, 9.4)
	rail_l_col.shape = rail_l_shape
	rail_l_col.position = pos + Vector3(-2.3, 1.1, 0.0)
	sb.add_child(rail_l_col)
	
	# Right Guardrail Barrier (West edge)
	var rail_r_col = CollisionShape3D.new()
	var rail_r_shape = BoxShape3D.new()
	rail_r_shape.size = Vector3(0.5, 1.8, 9.4)
	rail_r_col.shape = rail_r_shape
	rail_r_col.position = pos + Vector3(2.3, 1.1, 0.0)
	sb.add_child(rail_r_col)
	
	parent.add_child(sb)

func _build_walkable_wooden_bridge(parent: Node3D, pos: Vector3, sc: Vector3) -> void:
	var bridge_prop = _place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", pos, sc)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.25, 0.16)
	wood_mat.roughness = 0.86
	for mi in bridge_prop.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = wood_mat
	
	var sb = StaticBody3D.new()
	sb.name = "WoodBridgeRamps"
	sb.collision_layer = 1
	sb.collision_mask = 0
	
	var r_north_shape = BoxShape3D.new()
	r_north_shape.size = Vector3(3.6, 0.25, 3.6)
	var r_north_col = CollisionShape3D.new()
	r_north_col.shape = r_north_shape
	r_north_col.position = pos + Vector3(0.0, 0.22, -2.4)
	r_north_col.rotation_degrees.x = -7.5
	sb.add_child(r_north_col)
	
	var r_center_shape = BoxShape3D.new()
	r_center_shape.size = Vector3(3.6, 0.25, 2.6)
	var r_center_col = CollisionShape3D.new()
	r_center_col.shape = r_center_shape
	r_center_col.position = pos + Vector3(0.0, 0.44, 0.0)
	sb.add_child(r_center_col)
	
	var r_south_shape = BoxShape3D.new()
	r_south_shape.size = Vector3(3.6, 0.25, 3.6)
	var r_south_col = CollisionShape3D.new()
	r_south_col.shape = r_south_shape
	r_south_col.position = pos + Vector3(0.0, 0.22, 2.4)
	r_south_col.rotation_degrees.x = 7.5
	sb.add_child(r_south_col)
	
	var rail_l_col = CollisionShape3D.new()
	var rail_l_shape = BoxShape3D.new()
	rail_l_shape.size = Vector3(0.4, 1.5, 8.6)
	rail_l_col.shape = rail_l_shape
	rail_l_col.position = pos + Vector3(-2.0, 1.0, 0.0)
	sb.add_child(rail_l_col)
	
	var rail_r_col = CollisionShape3D.new()
	var rail_r_shape = BoxShape3D.new()
	rail_r_shape.size = Vector3(0.4, 1.5, 8.6)
	rail_r_col.shape = rail_r_shape
	rail_r_col.position = pos + Vector3(2.0, 1.0, 0.0)
	sb.add_child(rail_r_col)
	
	parent.add_child(sb)

func _build_watermill_and_canal(parent: Node3D, pos: Vector3) -> void:
	# 1. Riverside Watermill building rotated 180° so the house sits on the North grass bank (Z in [15.6, 20.0])
	#    while the giant wooden waterwheel extends South directly out into the River (Z in [20.0, 22.4])
	#    and pos.y = -0.38 submerges the lower wheel paddles beneath the river surface (Y = -0.15).
	var watermill = _place_prop(parent, "res://assets/overworld/building_watermill_blue.gltf", pos, Vector3.ONE * 6.0, 180.0)
	_add_static_box(parent, Vector3(pos.x, 3.5, 17.8), Vector3(6.2, 7.0, 4.8))
	var wm_rot = RotatingProp.new()
	wm_rot.target_node_name = "building_watermill_wheel_blue"
	wm_rot.rotation_axis = Vector3(0, 0, 1)
	wm_rot.rpm = 12.0
	watermill.add_child(wm_rot)

	# 2. Active Churning Water Spray & Foam Particles where the wheel paddles plunge into the river
	var splashes = CPUParticles3D.new()
	splashes.name = "WaterWheelSplashes"
	splashes.position = Vector3(pos.x, -0.08, 21.4)
	splashes.amount = 36
	splashes.lifetime = 0.45
	splashes.explosiveness = 0.15
	splashes.direction = Vector3(1.0, 0.6, 0.0)
	splashes.spread = 50.0
	splashes.initial_velocity_min = 2.5
	splashes.initial_velocity_max = 4.4
	splashes.gravity = Vector3(0.0, -9.8, 0.0)
	splashes.scale_amount_min = 0.8
	splashes.scale_amount_max = 1.6
	
	var drop_mesh = SphereMesh.new()
	drop_mesh.radius = 0.06
	drop_mesh.height = 0.12
	var drop_mat = StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.8)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.emission_enabled = true
	drop_mat.emission = Color(0.6, 0.85, 1.0)
	drop_mat.emission_energy_multiplier = 0.8
	drop_mesh.material = drop_mat
	splashes.mesh = drop_mesh
	parent.add_child(splashes)

	# 3. Riverside Mill Flour Sack Storage on the North Bank (cleanly outside building footprint)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(pos.x - 5.2, 0.0, 17.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(pos.x - 5.2, 0.0, 16.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(pos.x - 3.8, 0.0, 15.8), Vector3.ONE * 1.4)

	# NPC: Miller Bronn
	var bronn = TownNPCScript.new()
	bronn.npc_id = "miller"
	bronn.npc_name = "Miller Bronn"
	bronn.npc_title = "River Grain Master"
	bronn.icon = "⚙️"
	bronn.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	bronn.model_scale = Vector3(0.54, 0.54, 0.54)
	bronn.model_rotation_y = 0.0
	bronn.dialogue_text = "Hear the rumble of the wheel! The river current powers the millstones day and night, grinding Giles's wheat into fine golden flour for the capital."
	bronn.position = Vector3(pos.x - 5.0, 0.0, 14.2)
	parent.add_child(bronn)

func _build_farmlands_hamlet(parent: Node3D) -> void:
	# =========================================================================
	# SUNNYDALE FARMING HAMLET (South-East Bank: X in [26, 56], Z in [29, 53])
	# Organized logically along the Sunnydale Farm Lane (Z = 35.0):
	#  - North side of lane (Z = 29.5): Giles's Cottage, Farmhouse & Wheat/Pumpkin Garden
	#  - Village Green (Z = 34.5): Stone Well & Farmer Giles
	#  - East Knoll (X = 52.0, Z = 40.0): Grand Windmill overlooking the fields (OUTSIDE the pasture!)
	#  - South of lane (X in [26, 44], Z in [39, 53]): Fenced Livestock Pasture & Stable Master Barnaby
	# =========================================================================
	# 1. Giles's Thatched Cottage (Faces South 0° onto the Farm Lane)
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(30.0, 0.0, 29.5), Vector3.ONE * 6.8, 0.0)
	_add_static_box(parent, Vector3(30.0, 3.5, 29.5), Vector3(6.0, 6.5, 6.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(30.0, 6.8, 29.5))

	# 2. Sunnydale Dairy Shed & Apiary (West Farm Lane: X = 20.0, Z = 29.5, facing South 0°)
	_place_prop(parent, "res://assets/overworld/building_home_B_yellow.gltf", Vector3(20.0, 0.0, 29.5), Vector3.ONE * 5.6, 0.0)
	_add_static_box(parent, Vector3(20.0, 3.5, 29.5), Vector3(6.0, 6.5, 6.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(20.0, 6.8, 29.5))
	_place_prop(parent, "res://assets/overworld/bucket_water.gltf", Vector3(17.2, 0.0, 33.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/crate_A_small.gltf", Vector3(22.8, 0.0, 33.0), Vector3.ONE * 1.6)

	# NPC: Rosalind the Dairy Maid & Beekeeper
	var rosalind = TownNPCScript.new()
	rosalind.npc_id = "beekeeper_rosalind"
	rosalind.npc_name = "Rosalind"
	rosalind.npc_title = "Dairy Maid & Beekeeper"
	rosalind.icon = "🍯"
	rosalind.model_path = "res://assets/characters/adventurers/Mage.glb"
	rosalind.model_scale = Vector3(0.52, 0.52, 0.52)
	rosalind.model_rotation_y = 0.0
	rosalind.dialogue_text = "Golden clover honey and fresh creamy milk! Sunnydale's meadows bloom bright in the summer sun. Keep the wolves at bay and our hives produce sweet comb all year round!"
	rosalind.position = Vector3(20.0, 0.0, 33.5)
	parent.add_child(rosalind)

	# 3. Second Sunnydale Farmhouse (Faces South 0° onto the Farm Lane)
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(40.0, 0.0, 29.5), Vector3.ONE * 6.5, 0.0)
	_add_static_box(parent, Vector3(40.0, 4.0, 29.5), Vector3(6.2, 7.0, 7.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(40.0, 8.2, 29.5))

	# 3. Village Stone Well & Farmer Giles on the Village Green
	_place_prop(parent, "res://assets/overworld/building_well_blue.gltf", Vector3(35.0, 0.0, 33.2), Vector3.ONE * 2.5)
	_add_static_cyl(parent, Vector3(35.0, 0.0, 33.2), 1.3, 3.2)

	var giles = TownNPCScript.new()
	giles.npc_id = "farmer"
	giles.npc_name = "Farmer Giles"
	giles.npc_title = "Hamlet Elder"
	giles.icon = "🌾"
	giles.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	giles.model_scale = Vector3(0.56, 0.56, 0.56)
	giles.model_rotation_y = -20.0
	giles.dialogue_text = "Good day, traveler! Welcome to Sunnydale Hamlet. Our windmill grinds the harvest on the eastern knoll while our cattle graze safely in the fenced southern pasture. Deliver raw meat or fine hides from the wild beasts, and we shall reward you richly in coin!"
	giles.position = Vector3(31.8, 0.0, 33.5)
	parent.add_child(giles)

	# 4. Cultivated Loam Soil Farm Bed, Wheat Crops & Pumpkin Patch (East of Farmhouse: X in [46, 53], Z in [28, 34])
	var soil_bed = MeshInstance3D.new()
	soil_bed.name = "FarmlandLoamSoil"
	var soil_mesh = PlaneMesh.new()
	soil_mesh.size = Vector2(8.8, 6.4)
	var soil_mat = StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.24, 0.17, 0.11) # Rich dark tilled loam
	soil_mat.roughness = 0.95
	soil_bed.mesh = soil_mesh
	soil_bed.position = Vector3(49.2, 0.02, 31.0)
	parent.add_child(soil_bed)

	# Split-rail timber fences framing the crop field
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(49.2, 0.0, 27.8), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(45.0, 0.0, 31.0), Vector3.ONE * 1.8, 0.0)
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(53.4, 0.0, 31.0), Vector3.ONE * 1.8, 0.0)

	# Golden harvest wheat sheaves, grain sacks and pumpkins
	for wx in [47.0, 49.0, 51.2]:
		for wz in [29.2, 30.8]:
			_place_prop(parent, "res://assets/overworld/trees_A_cut.gltf", Vector3(wx, 0.0, wz), Vector3(0.9, 1.4, 0.9), randf_range(0.0, 180.0))
	for px in [46.8, 48.6, 50.4, 52.0]:
		for pz in [32.4, 33.6]:
			_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(px, 0.0, pz), Vector3.ONE * randf_range(0.38, 0.46), randf_range(0.0, 360.0))
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(46.0, 0.0, 28.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/crate_A_small.gltf", Vector3(46.2, 0.0, 29.6), Vector3.ONE * 1.2)

	# 5. Grand Windmill on the Eastern Knoll (Cleanly OUTSIDE the fenced animal pasture!)
	var windmill = _place_prop(parent, "res://assets/overworld/building_windmill_blue.gltf", Vector3(52.0, 0.0, 40.0), Vector3.ONE * 9.5, -35.0)
	_add_static_cyl(parent, Vector3(52.0, 0.0, 40.0), 3.4, 11.5)
	var fan_rot = RotatingProp.new()
	fan_rot.target_node_name = "building_windmill_top_fan_blue"
	fan_rot.rotation_axis = Vector3(0, 0, 1)
	fan_rot.rpm = 7.5
	windmill.add_child(fan_rot)

	# Farm Storage beside the Windmill
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(47.0, 0.0, 38.0), Vector3.ONE * 1.5, 35.0)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(47.0, 0.0, 41.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(47.0, 0.0, 43.2), Vector3.ONE * 1.3)

	# Distant Rolling Hill east of the Windmill
	_place_prop(parent, "res://assets/overworld/hill_single_A.gltf", Vector3(66.0, 0.0, 36.0), Vector3.ONE * 7.0)

	# =========================================================================
	# 6. ENCLOSED LIVESTOCK PASTURE (South of Farm Lane: X in [26, 44], Z in [39, 53])
	# =========================================================================
	var p_x1 = 26.0
	var p_x2 = 44.0
	var p_z1 = 39.0
	var p_z2 = 53.0

	# North fence line (Z = 39.0, with entrance gate at X = 35.0)
	for fx in [27.5, 31.0, 35.0, 39.0, 42.5]:
		if abs(fx - 35.0) < 0.5:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight_gate.gltf", Vector3(fx, 0.0, p_z1), Vector3.ONE * 1.8, 90.0)
		else:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(fx, 0.0, p_z1), Vector3.ONE * 1.8, 90.0)

	# South fence line (Z = 53.0)
	for fx in [27.5, 31.0, 35.0, 39.0, 42.5]:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(fx, 0.0, p_z2), Vector3.ONE * 1.8, 90.0)

	# West fence line (X = 26.0) & East fence line (X = 44.0)
	for fz in [40.8, 44.2, 47.8, 51.2]:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x1, 0.0, fz), Vector3.ONE * 1.8, 0.0)
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x2, 0.0, fz), Vector3.ONE * 1.8, 0.0)

	# Pasture Perimeter Collision (Keeps livestock inside the corral)
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z1), Vector3(p_x2 - p_x1, 1.6, 0.4))
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z2), Vector3(p_x2 - p_x1, 1.6, 0.4))
	_add_static_box(parent, Vector3(p_x2, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1))
	_add_static_box(parent, Vector3(p_x1, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1))

	# Pasture Livestock Water Troughs & Hay Sacks (Cleanly spaced inside the fence)
	_place_prop(parent, "res://assets/overworld/bucket_water.gltf", Vector3(28.0, 0.0, 41.0), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(28.0, 0.0, 43.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(50.0, 0.0, 49.0), Vector3.ONE * 1.5, -20.0)

	# Grazing Animals inside the open, unobstructed fenced pasture
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(30.0, 0.0, 44.0), 45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(38.0, 0.0, 46.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(33.0, 0.0, 50.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.BULL, Vector3(36.0, 0.0, 43.0), 120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(29.5, 0.0, 49.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(41.0, 0.0, 49.0), -85.0)

	# NPC: Barnaby the Stable Master (Stationed outside the North Pasture Gate)
	var stablemaster = TownNPCScript.new()
	stablemaster.npc_id = "stablemaster"
	stablemaster.npc_name = "Barnaby"
	stablemaster.npc_title = "Royal Ostler & Stable Master"
	stablemaster.icon = "🐎"
	stablemaster.model_path = "res://assets/characters/adventurers/Knight.glb"
	stablemaster.model_scale = Vector3(0.55, 0.55, 0.55)
	stablemaster.model_rotation_y = 180.0
	stablemaster.position = Vector3(37.5, 0.0, 37.2)
	parent.add_child(stablemaster)

	# NPC: Silas the Herdsman (Tending cattle & warsteeds inside the pasture)
	var silas = TownNPCScript.new()
	silas.npc_id = "herdsman_silas"
	silas.npc_name = "Silas"
	silas.npc_title = "Pasture Herdsman"
	silas.icon = "🌾"
	silas.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	silas.model_scale = Vector3(0.54, 0.54, 0.54)
	silas.model_rotation_y = -90.0
	silas.dialogue_text = "Sunnydale pastures are lush and green this season! Our cattle thrive, and the royal warsteeds graze in safety away from the northern bandits."
	silas.position = Vector3(34.0, 0.0, 48.0)
	parent.add_child(silas)

func _build_castle_citadel(parent: Node3D) -> void:
	# =========================================================================
	# IMPERIAL CITADEL COURTYARD & FORTRESS (X in [-20, 20], Z in [35, 56])
	# Designed with a true fortified outer gatehouse at Z = 36.0, a spacious Royal
	# Courtyard from Z = 37.0 to Z = 43.0, flanking Barracks & Quartermaster on the
	# east/west walls, and the towering Castle Keep anchoring the south at Z = 49.0.
	# =========================================================================
	# 1. Grand Citadel Arched Gateway (Aligned with the Royal Highway at X = 0.0, Z = 36.0)
	var citadel_arch = _place_prop(parent, "res://assets/overworld/arch.gltf", Vector3(0.0, 0.0, 36.0), Vector3(2.5, 3.8, 2.5))
	_place_prop(citadel_arch, "res://assets/overworld/flag_blue.gltf", Vector3(0.0, 4.0, 0.0), Vector3.ONE * 2.0)

	# 2. Stone Curtain Walls flanking the Arch (Z = 36.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-7.0, 0.0, 36.0), Vector3(3.4, 4.5, 2.8))
	_add_static_box(parent, Vector3(-7.0, 3.5, 36.0), Vector3(6.2, 7.5, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(7.0, 0.0, 36.0), Vector3(3.4, 4.5, 2.8))
	_add_static_box(parent, Vector3(7.0, 3.5, 36.0), Vector3(6.2, 7.5, 2.5))

	# 3. Left & Right Citadel Catapult Watchtowers (Anchoring the corners at X = ±14.5, Z = 36.0)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-14.5, 0.0, 36.0), Vector3.ONE * 9.0)
	_add_static_box(parent, Vector3(-14.5, 7.0, 36.0), Vector3(4.5, 14.0, 4.5))
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(14.5, 0.0, 36.0), Vector3.ONE * 9.0)
	_add_static_box(parent, Vector3(14.5, 7.0, 36.0), Vector3(4.5, 14.0, 4.5))

	# 4. Royal Castle Keep (Set back at Z = 49.0 so its front entrance opens onto Z = 42.5)
	_place_prop(parent, "res://assets/overworld/building_castle_blue.gltf", Vector3(0.0, 0.0, 49.0), Vector3.ONE * 6.2)
	_add_static_box(parent, Vector3(0.0, 8.0, 49.0), Vector3(12.4, 16.0, 13.5))

	# 5. Garrison Barracks (West Courtyard Wing at X = -15.5, Z = 46.0, facing East 90°)
	_place_prop(parent, "res://assets/overworld/building_barracks_blue.gltf", Vector3(-15.5, 0.0, 46.0), Vector3.ONE * 5.2, 90.0)
	_add_static_box(parent, Vector3(-15.5, 4.5, 46.0), Vector3(7.5, 7.0, 8.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-15.5, 8.5, 46.0))

	# 6. Military Quartermaster Outpost (East Courtyard Wing at X = 15.5, Z = 46.0, facing West -90°)
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(15.5, 0.0, 46.0), Vector3.ONE * 3.6, -90.0)
	_add_static_box(parent, Vector3(15.5, 2.5, 46.0), Vector3(5.5, 5.0, 6.0))

	# 7. NPC: Commander Drake (Guarding the Royal Courtyard)
	var drake = TownNPCScript.new()
	drake.npc_id = "commander"
	drake.npc_name = "Commander Drake"
	drake.npc_title = "Citadel Commander"
	drake.icon = "🛡️"
	drake.model_path = "res://assets/characters/adventurers/Knight.glb"
	drake.model_scale = Vector3(0.58, 0.58, 0.58)
	drake.model_rotation_y = 155.0
	drake.dialogue_text = "Stand firm, warrior! The Imperial Citadel stands vigil against the abyss. Our scouts report arcane crystals gleaming in the north-eastern crags, and sacred relics lost in the western ruins. Check your royal bounties and bring glory to the realm!"
	drake.position = Vector3(-3.5, 0.0, 39.5)
	parent.add_child(drake)

	# 8. Royal Courtyard Pavilion: King Aldric IV & Queen Seraphina Reviewing the Realm
	var king_overworld = TownNPCScript.new()
	king_overworld.npc_id = "king_aldric"
	king_overworld.npc_name = "King Aldric IV"
	king_overworld.npc_title = "Sovereign of the Realm"
	king_overworld.icon = "👑"
	king_overworld.model_path = "res://assets/characters/adventurers/Knight.glb"
	king_overworld.model_scale = Vector3(0.60, 0.60, 0.60)
	king_overworld.model_rotation_y = -155.0
	king_overworld.dialogue_text = "Hail, champion of Oakhaven! Look to the south where our siege trebuchets hurl fire against the encroaching warlords, and to the east where the Weeping Fen festers. Unite the Seals of our kingdom and victory shall be ours!"
	king_overworld.position = Vector3(2.4, 0.0, 39.5)
	parent.add_child(king_overworld)

	var queen_overworld = TownNPCScript.new()
	queen_overworld.npc_id = "queen_seraphina"
	queen_overworld.npc_name = "Queen Seraphina"
	queen_overworld.npc_title = "Queen Consort"
	queen_overworld.icon = "👑"
	queen_overworld.model_path = "res://assets/characters/adventurers/Mage.glb"
	queen_overworld.model_scale = Vector3(0.56, 0.56, 0.56)
	queen_overworld.model_rotation_y = -155.0
	queen_overworld.dialogue_text = "Blessings of the Silvervein upon you, noble knight. Speak with me whenever your wounds weigh heavy, and the Crown's grace shall restore your strength."
	queen_overworld.position = Vector3(4.2, 0.0, 39.5)
	parent.add_child(queen_overworld)

	# 9. Citadel Battlement Archers (Stationed atop the Curtain Walls & Ramparts)
	for archer_idx in range(2):
		var wall_archer = TownNPCScript.new()
		wall_archer.npc_id = "archer_battlement_%d" % archer_idx
		wall_archer.npc_name = "Citadel Longbowman" if archer_idx == 0 else "Royal Crossbowman"
		wall_archer.npc_title = "Rampart Marksman"
		wall_archer.icon = "🏹"
		wall_archer.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
		wall_archer.model_scale = Vector3(0.54, 0.54, 0.54)
		wall_archer.model_rotation_y = 180.0
		wall_archer.dialogue_text = "Eyes on the horizon! Not a single goblin, corsair, or siege raider breaches these ramparts while our quivers are full!"
		wall_archer.position = Vector3(-7.0 if archer_idx == 0 else 7.0, 4.3, 35.8)
		parent.add_child(wall_archer)

	# Courtyard Armories & Props
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-9.5, 0.0, 41.0), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(9.5, 0.0, 41.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/tent.gltf", Vector3(-13.0, 0.0, 42.0), Vector3.ONE * 2.4, 90.0)
	_place_prop(parent, "res://assets/overworld/bucket_arrows.gltf", Vector3(-10.5, 0.0, 43.5), Vector3.ONE * 1.6)

	# Interactive Citadel Training Target
	var citadel_target = InteractiveTarget3DScript.new()
	citadel_target.target_name = "Citadel Practice Target"
	citadel_target.position = Vector3(-10.0, 0.0, 44.0)
	citadel_target.rotation_degrees.y = -90.0
	parent.add_child(citadel_target)

	# Circling Hawks Flock high above Castle Keep in the upper sky
	var flock_castle = CirclingFlock.new()
	flock_castle.position = Vector3(0.0, 34.0, 49.0)
	flock_castle.bird_count = 5
	flock_castle.circle_radius = 16.0
	flock_castle.flight_height = 34.0
	parent.add_child(flock_castle)

func _build_blackwood_forest(parent: Node3D) -> void:
	# South-West Timber Yard & Lumbermill (Cleanly west of the Castle Citadel on the South-West Bank: X = -32.0, Z = 35.0)
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-32.0, 0.0, 35.0), Vector3.ONE * 5.8, 90.0)
	_add_static_box(parent, Vector3(-32.0, 4.5, 35.0), Vector3(7.5, 7.0, 7.5))

	# Glowing Forest Fireflies
	AmbientFX.create_forest_fireflies(parent, Vector3(-38.0, 1.8, 34.0), 9.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(-44.0, 1.8, 40.0), 9.0)

	# Well-spaced Woodland Trees on the South-West Bank (Zero trees on the North Bank Town Street!)
	var forest_locs = [
		Vector3(-26.0, 0.0, 44.0), Vector3(-38.0, 0.0, 45.0),
		Vector3(-44.0, 0.0, 36.0), Vector3(-44.0, 0.0, 29.5),
		Vector3(-54.0, 0.0, 33.0), Vector3(-56.0, 0.0, 42.0)
	]
	var f_trees = [
		"res://assets/overworld/tree_pine_orange_medium.gltf",
		"res://assets/overworld/tree_single_A.gltf",
		"res://assets/overworld/tree_single_B.gltf",
		"res://assets/overworld/tree_pine_yellow_medium.gltf"
	]
	for i in range(forest_locs.size()):
		var lp = forest_locs[i]
		var tm = f_trees[i % f_trees.size()]
		_place_choppable_tree(parent, tm, lp, Vector3.ONE * 2.2, float((i * 53) % 360))

	# Boulders
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-28.0, 0.0, 30.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/rock_single_D.gltf", Vector3(-40.0, 0.0, 32.0), Vector3.ONE * 2.0)

	# Forest Wildlife (Grazing in the South-West Timber Glade)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-36.0, 0.0, 40.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-48.0, 0.0, 38.0), -45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-30.0, 0.0, 41.0), 110.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-42.0, 0.0, 41.0), -120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(-34.0, 0.0, 42.0), 75.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-50.0, 0.0, 32.0), 160.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-50.0, 0.0, 42.0), -30.0)

	# Special Quest Timber Nodes
	_spawn_material_node(parent, "heartwood_timber", "Heartwood Timber", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-35.0, 0.0, 29.5), Color(0.8, 0.5, 0.2), 20, 15, Vector3(2.2, 2.2, 2.2))
	_spawn_material_node(parent, "ironwood_logs", "Ironwood Logs", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-25.5, 0.0, 35.0), Color(0.7, 0.4, 0.2), 25, 20, Vector3(2.2, 2.2, 2.2))

func _build_iron_mountains(parent: Node3D) -> void:
	# North-East Foothill Peaks (Spaced around the Mine Amphitheater so peaks don't collide)
	var mtns = [
		{"pos": Vector3(28.0, 0.0, -38.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 8.0},
		{"pos": Vector3(46.0, 0.0, -34.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 8.0},
		{"pos": Vector3(48.0, 0.0, -14.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 7.5},
		{"pos": Vector3(16.0, 0.0, -32.0), "path": "res://assets/overworld/hills_A.gltf", "scale": 6.0}
	]
	for m in mtns:
		_place_prop(parent, m["path"], m["pos"], Vector3.ONE * m["scale"])
		_add_static_box(parent, m["pos"] + Vector3(0, 6.0, 0), Vector3(m["scale"] * 1.8, 12.0, m["scale"] * 1.8))

	# Foothill Mine Entrance (Faces South-West toward the trail)
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(34.0, 0.0, -22.0), Vector3.ONE * 5.5, -90.0)
	_add_static_box(parent, Vector3(34.0, 3.5, -22.0), Vector3(7.0, 6.0, 7.0))

	# Mountain Wolf Guard
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(28.0, 0.0, -24.0), 45.0)

	# Special Quest Mineral Nodes (Mineable crystals and gold ingots in the quarry yard)
	_spawn_material_node(parent, "arcane_crystal", "Arcane Cyan Crystal", "💎", "res://assets/items/quest_materials/Crystal1.glb", Vector3(26.0, 0.0, -18.0), Color(0.2, 0.8, 1.0), 30, 25, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "emerald_crystal", "Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(36.0, 0.0, -30.0), Color(0.2, 1.0, 0.4), 35, 30, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "gold_vein", "Mountain Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(24.0, 0.0, -28.0), Color(1.0, 0.85, 0.2), 40, 35, Vector3(1.5, 1.5, 1.5))
	_spawn_material_node(parent, "iron_ore", "Highland Iron Ore", "⛏️", "res://assets/overworld/resource_stone.gltf", Vector3(30.0, 0.0, -14.0), Color(0.6, 0.65, 0.7), 25, 20, Vector3(2.2, 2.2, 2.2))

func _build_forgotten_ruins(parent: Node3D) -> void:
	# Ancient Stone Sanctuary Ruins (West of the Cathedral at X in [-38, -28], Z in [-10, 2])
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-34.0, 0.0, -6.0), Vector3.ONE * 2.6)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-30.0, 0.0, -9.0), Vector3(1.5, 2.4, 1.5))
	_add_static_cyl(parent, Vector3(-30.0, 0.0, -9.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-38.0, 0.0, -9.0), Vector3(1.5, 2.4, 1.5))
	_add_static_cyl(parent, Vector3(-38.0, 0.0, -9.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-38.0, 0.0, -1.0), Vector3.ONE * 2.4, 90.0)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(-31.5, 0.0, -6.0), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/bone_A.gltf", Vector3(-35.5, 0.0, -2.5), Vector3.ONE * 1.6)

	# NPC: Hermit Morvath
	var hermit = TownNPCScript.new()
	hermit.npc_id = "hermit"
	hermit.npc_name = "Hermit Morvath"
	hermit.npc_title = "Keeper of the Forgotten"
	hermit.icon = "🔮"
	hermit.model_path = "res://assets/characters/adventurers/Mage.glb"
	hermit.model_scale = Vector3(0.53, 0.53, 0.53)
	hermit.model_rotation_y = 25.0
	hermit.dialogue_text = "Tread lightly, warrior. The stones here remember an empire older than memory. The Sacred Chalice and the Ancient Codex are scattered among these cracked pedestals. Channel the Soul Echoes you reap to unlock arcane boons!"
	hermit.position = Vector3(-33.5, 0.0, -2.0)
	parent.add_child(hermit)

	# Sacred Relic Material Nodes
	_spawn_material_node(parent, "sacred_chalice", "Sacred Chalice of the First Kings", "🏆", "res://assets/items/quest_materials/Chalice.glb", Vector3(-36.5, 0.0, -5.5), Color(1.0, 0.8, 0.2), 50, 50, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "ossuary_codex", "Forgotten Ossuary Codex", "📜", "res://assets/items/quest_materials/Scroll.glb", Vector3(-30.0, 0.0, -1.5), Color(0.9, 0.85, 0.6), 40, 40, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "smugglers_chest", "Sunken Smuggler's Chest", "📦", "res://assets/items/quest_materials/Chest_Ingots.glb", Vector3(-26.0, 0.0, -12.0), Color(0.95, 0.75, 0.2), 60, 45, Vector3(1.5, 1.5, 1.5))

func _spawn_animal(parent: Node3D, type: int, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var animal = AnimalAIScript.new()
	animal.animal_type = type
	animal.position = pos
	if rot_y != 0.0:
		animal.rotation_degrees.y = rot_y
	parent.add_child(animal)
	return animal

func _spawn_material_node(parent: Node3D, mat_id: String, d_name: String, icon_s: String, m_path: String, pos: Vector3, col: Color, gold: int, echoes: int, m_scale: Vector3 = Vector3(1.4, 1.4, 1.4)) -> Node3D:
	var node = QuestMaterialNodeScript.new()
	node.material_id = mat_id
	node.display_name = d_name
	node.icon = icon_s
	node.model_path = m_path
	node.model_scale = m_scale
	node.glow_color = col
	node.gold_reward = gold
	node.echo_reward = echoes
	node.position = pos
	parent.add_child(node)
	return node

func _place_prop(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0) -> Node3D:
	var prop = AssetLoader.load_or_generate_model(path, "dungeon", "prop")
	prop.position = pos
	prop.scale = sc
	if rot_y_deg != 0.0:
		prop.rotation_degrees.y = rot_y_deg
	parent.add_child(prop)
	
	if "flag" in path:
		_apply_flag_shader(prop, path)
		
	return prop

func _place_destructible_prop(parent: Node3D, p_type: int, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0, loot: String = "random") -> Node3D:
	var prop = DestructibleProp3DScript.new()
	prop.prop_type = p_type
	prop.drop_loot = loot
	prop.position = pos
	if rot_y_deg != 0.0:
		prop.rotation_degrees.y = rot_y_deg

	var vis = AssetLoader.load_or_generate_model(path, "dungeon", "destructible")
	vis.scale = sc
	prop.add_child(vis)
	prop.visual_node = vis

	if p_type == DestructibleProp3DScript.PropType.WOODEN_FENCE:
		prop.collider_size = Vector3(2.4 * sc.x, 1.2 * sc.y, 0.4 * sc.z)
		prop.max_health = 30.0
	elif p_type == DestructibleProp3DScript.PropType.CARGO_CRATE:
		prop.collider_size = Vector3(1.2 * sc.x, 1.2 * sc.y, 1.2 * sc.z)
		prop.max_health = 25.0
	elif p_type == DestructibleProp3DScript.PropType.WOODEN_BARREL:
		prop.collider_size = Vector3(0.9 * sc.x, 1.2 * sc.y, 0.9 * sc.z)
		prop.max_health = 20.0
	elif p_type == DestructibleProp3DScript.PropType.SIEGE_BARRICADE:
		prop.collider_size = Vector3(2.5 * sc.x, 1.5 * sc.y, 0.8 * sc.z)
		prop.max_health = 45.0

	parent.add_child(prop)
	return prop

func _place_choppable_tree(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0) -> Node3D:
	var tree = ChoppableTree3DScript.new()
	tree.position = pos
	if rot_y_deg != 0.0:
		tree.rotation_degrees.y = rot_y_deg

	var vis = AssetLoader.load_or_generate_model(path, "dungeon", "tree")
	vis.scale = sc
	tree.add_child(vis)

	parent.add_child(tree)
	return tree

func _apply_flag_shader(node: Node3D, path: String = "") -> void:
	var flag_shader = load("res://shaders/waving_flag.gdshader")
	if flag_shader:
		var flag_mat = ShaderMaterial.new()
		flag_mat.shader = flag_shader
		var f_col = Color(0.18, 0.42, 0.82)
		if "red" in path:
			f_col = Color(0.82, 0.18, 0.18)
		elif "green" in path:
			f_col = Color(0.20, 0.68, 0.30)
		elif "yellow" in path:
			f_col = Color(0.88, 0.72, 0.18)
		flag_mat.set_shader_parameter("flag_color", f_col)
		for child in node.find_children("*", "MeshInstance3D", true, false):
			var mi = child as MeshInstance3D
			if mi:
				mi.material_override = flag_mat

func _add_static_box(parent: Node3D, pos: Vector3, sz: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = sz
	col.shape = box
	col.position = pos
	body.add_child(col)
	parent.add_child(body)
	return body

func _add_static_cyl(parent: Node3D, pos: Vector3, radius: float, height: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	col.position = pos + Vector3(0, height * 0.5, 0)
	body.add_child(col)
	parent.add_child(body)
	return body

func _build_enterable_building_doorways(parent: Node3D) -> void:
	# 1. Castle Grand Throne Room Doorway (Front entrance of Castle Keep at Z = 43.0)
	var castle_door = BuildingDoorway.new()
	castle_door.door_id = "castle_entrance"
	castle_door.prompt_text = "Enter Castle Grand Hall"
	castle_door.target_position = Vector3(0.0, -99.8, 10.0)
	castle_door.target_rotation_y = 180.0
	castle_door.target_cam_distance = 12.0
	castle_door.target_cam_pitch = 40.0
	castle_door.target_bgm_key = "bgm_castle"
	castle_door.position = Vector3(0.0, 0.0, 43.0)
	parent.add_child(castle_door)

	# 2. The Boar's Tusk Tavern Doorway (Front entrance on West Town Street at X = -26.0, Z = 12.2)
	var tavern_door = BuildingDoorway.new()
	tavern_door.door_id = "tavern_entrance"
	tavern_door.prompt_text = "Enter The Boar's Tusk Tavern"
	tavern_door.target_position = Vector3(60.0, -99.8, 4.8)
	tavern_door.target_rotation_y = 0.0
	tavern_door.target_cam_distance = 11.0
	tavern_door.target_cam_pitch = 40.0
	tavern_door.target_bgm_key = "bgm_tavern"
	tavern_door.position = Vector3(-26.0, 0.0, 12.2)
	parent.add_child(tavern_door)

	# 3. Master Torval's Forge Doorway (Front entrance on Sanctuary West Plaza at X = -14.5, Z = -1.0)
	var forge_door = BuildingDoorway.new()
	forge_door.door_id = "forge_entrance"
	forge_door.prompt_text = "Enter Master Torval's Forge"
	forge_door.target_position = Vector3(120.0, -99.8, 4.0)
	forge_door.target_rotation_y = 0.0
	forge_door.target_cam_distance = 10.0
	forge_door.target_cam_pitch = 40.0
	forge_door.target_bgm_key = "bgm_forge"
	forge_door.position = Vector3(-14.5, 0.0, -1.0)
	parent.add_child(forge_door)

	# 4. Giles's Thatched Cottage Doorway (Front entrance on Sunnydale Farm Lane at X = 30.0, Z = 32.5)
	var cottage_door = BuildingDoorway.new()
	cottage_door.door_id = "cottage_entrance"
	cottage_door.prompt_text = "Enter Giles's Thatched Cottage"
	cottage_door.target_position = Vector3(180.0, -99.8, 3.0)
	cottage_door.target_rotation_y = 0.0
	cottage_door.target_cam_distance = 10.0
	cottage_door.target_cam_pitch = 40.0
	cottage_door.target_bgm_key = "bgm_overworld"
	cottage_door.position = Vector3(30.0, 0.0, 32.5)
	parent.add_child(cottage_door)

	# 5. Port Blackwater: The Rusty Anchor Tavern Doorway (Front entrance facing Harbor Promenade at X = -51.8, Z = 72.0)
	var rusty_door = BuildingDoorway.new()
	rusty_door.door_id = "rusty_anchor_entrance"
	rusty_door.prompt_text = "Enter The Rusty Anchor Tavern"
	rusty_door.target_position = Vector3(240.0, -99.8, 4.5)
	rusty_door.target_rotation_y = 0.0
	rusty_door.target_cam_distance = 11.0
	rusty_door.target_cam_pitch = 40.0
	rusty_door.target_bgm_key = "bgm_tavern"
	rusty_door.position = Vector3(-51.8, 0.0, 72.0)
	parent.add_child(rusty_door)

	# 6. Khar-Drakken: Stonegate Smelting Foundry Doorway (Front entrance at X = 74.0, Z = -52.0)
	var stonegate_door = BuildingDoorway.new()
	stonegate_door.door_id = "stonegate_forge_entrance"
	stonegate_door.prompt_text = "Enter Stonegate Smelting Hall"
	stonegate_door.target_position = Vector3(300.0, -99.8, 4.5)
	stonegate_door.target_rotation_y = 0.0
	stonegate_door.target_cam_distance = 11.0
	stonegate_door.target_cam_pitch = 40.0
	stonegate_door.target_bgm_key = "bgm_forge"
	stonegate_door.position = Vector3(74.0, 0.0, -52.0)
	parent.add_child(stonegate_door)

func _spawn_enemy(parent: Node3D, type: int, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var enemy = EnemyAIScript.new()
	enemy.enemy_type = type
	enemy.position = pos
	if rot_y != 0.0:
		enemy.rotation_degrees.y = rot_y
	parent.add_child(enemy)
	return enemy

# =========================================================================
# REGION 1: PORT BLACKWATER & THE SOUTH-WEST OCEAN COAST
# =========================================================================
func _build_port_blackwater_region(parent: Node3D) -> void:
	# 1. Sunken Ocean Harbor Basin & Seabed (Expanded open sea X in [-210, -62], Z in [46, 210])
	#    Uncovered by the SouthBank_Grass cutout so true ocean water is 100% visible!
	var seabed_inst = MeshInstance3D.new()
	seabed_inst.name = "OceanSeabedVisual"
	var sb_mesh = PlaneMesh.new()
	sb_mesh.size = Vector2(148.0, 164.0)
	seabed_inst.mesh = sb_mesh
	var sb_mat = StandardMaterial3D.new()
	sb_mat.albedo_color = Color(0.08, 0.14, 0.18) # Deep ocean sand & silt
	sb_mat.roughness = 0.95
	seabed_inst.material_override = sb_mat
	seabed_inst.position = Vector3(-136.0, -1.20, 128.0)
	parent.add_child(seabed_inst)

	# Shallow Seabed Safety Collider so amphibious enemies or players wading off the beach don't fall into the void
	var seabed_col_body = StaticBody3D.new()
	seabed_col_body.name = "OceanSeabedCollider"
	seabed_col_body.collision_layer = 1
	var seabed_col = CollisionShape3D.new()
	var seabed_box = BoxShape3D.new()
	seabed_box.size = Vector3(148.0, 0.5, 164.0)
	seabed_col.shape = seabed_box
	seabed_col.position = Vector3(-136.0, -0.60, 128.0)
	seabed_col_body.add_child(seabed_col)
	parent.add_child(seabed_col_body)

	# 2. Open Ocean Water Surface (Y = -0.15m, X in [-210, -62], Z in [46, 210])
	var ocean_basin = MeshInstance3D.new()
	ocean_basin.name = "OceanWaterSurface"
	var oc_mesh = PlaneMesh.new()
	oc_mesh.size = Vector2(148.0, 164.0)
	ocean_basin.mesh = oc_mesh
	var ocean_mat = ShaderMaterial.new()
	ocean_mat.shader = load("res://shaders/river_flow.gdshader")
	ocean_basin.material_override = ocean_mat
	ocean_basin.position = Vector3(-136.0, -0.15, 128.0)
	parent.add_child(ocean_basin)

	# 3. Stone Harbor Quay Wall & Paved Waterfront Promenade (X in [-62, -46], Z in [46, 86])
	var quay_mat = StandardMaterial3D.new()
	quay_mat.albedo_color = Color(0.32, 0.33, 0.35)
	quay_mat.roughness = 0.88

	var east_quay = MeshInstance3D.new()
	east_quay.name = "HarborQuayWallEast"
	var eq_mesh = BoxMesh.new()
	eq_mesh.size = Vector3(1.2, 1.35, 42.0)
	east_quay.mesh = eq_mesh
	east_quay.material_override = quay_mat
	east_quay.position = Vector3(-61.8, -0.42, 67.0)
	parent.add_child(east_quay)

	var north_quay = MeshInstance3D.new()
	north_quay.name = "HarborQuayWallNorth"
	var nq_mesh = BoxMesh.new()
	nq_mesh.size = Vector3(32.0, 1.35, 1.2)
	north_quay.mesh = nq_mesh
	north_quay.material_override = quay_mat
	north_quay.position = Vector3(-77.5, -0.42, 46.2)
	parent.add_child(north_quay)

	var prom_mat = StandardMaterial3D.new()
	prom_mat.albedo_color = Color(0.42, 0.40, 0.37) # Weathered harbor flagstones
	prom_mat.roughness = 0.90
	var prom_inst = MeshInstance3D.new()
	prom_inst.name = "HarborPromenadeVisual"
	var prom_mesh = BoxMesh.new()
	prom_mesh.size = Vector3(15.5, 0.04, 38.0)
	prom_inst.mesh = prom_mesh
	prom_inst.material_override = prom_mat
	prom_inst.position = Vector3(-53.8, 0.02, 67.0)
	parent.add_child(prom_inst)

	# Golden Sandy Beach Cove south of the stone quay (X in [-62, -46], Z in [86, 114])
	var sand_mesh_inst = MeshInstance3D.new()
	sand_mesh_inst.name = "CoastalSandVisual"
	var s_mesh = PlaneMesh.new()
	s_mesh.size = Vector2(16.0, 28.0)
	sand_mesh_inst.mesh = s_mesh
	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.76, 0.68, 0.48)
	sand_mat.roughness = 0.94
	sand_mesh_inst.material_override = sand_mat
	sand_mesh_inst.position = Vector3(-54.0, 0.015, 100.0)
	parent.add_child(sand_mesh_inst)

	# Smooth Beach Shoreline Walkout Ramp (Connects submerged seabed Y = -0.35m directly to dry sand Y = 0.02m)
	# Guarantees swimming players can smoothly walk out of the ocean anywhere along the beach cove!
	var beach_ramp_body = StaticBody3D.new()
	beach_ramp_body.name = "BeachShorelineRamp"
	beach_ramp_body.collision_layer = 1
	var br_col = CollisionShape3D.new()
	var br_box = BoxShape3D.new()
	br_box.size = Vector3(3.2, 0.20, 27.5)
	br_col.shape = br_box
	br_col.position = Vector3(-61.6, -0.17, 100.0)
	br_col.rotation_degrees.z = -8.0
	beach_ramp_body.add_child(br_col)
	parent.add_child(beach_ramp_body)

	# Wet Sand Visual Slope transitioning into the water
	var wet_sand_inst = MeshInstance3D.new()
	wet_sand_inst.name = "WetSandVisual"
	var ws_mesh = PlaneMesh.new()
	ws_mesh.size = Vector2(3.6, 27.5)
	wet_sand_inst.mesh = ws_mesh
	var wet_sand_mat = StandardMaterial3D.new()
	wet_sand_mat.albedo_color = Color(0.55, 0.47, 0.32) # Dark glistening wet sand
	wet_sand_mat.roughness = 0.55
	wet_sand_inst.material_override = wet_sand_mat
	wet_sand_inst.position = Vector3(-61.6, -0.12, 100.0)
	wet_sand_inst.rotation_degrees.z = -8.0
	parent.add_child(wet_sand_inst)

	# 3B. Stone Harbor Sea Stairs (X = -61.8, Z = 72.0)
	# Carved directly into the Stone Quay in front of The Rusty Anchor Tavern
	# 4 broad stone treads descending from the promenade (Y = 0.02m) down into the sea (Y = -0.30m)
	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.35, 0.36, 0.38) # Weathered seaside granite
	stair_mat.roughness = 0.85
	
	var stair_steps_data = [
		Vector3(-63.3, -0.28, 72.0), # Step 1: Submerged in sea
		Vector3(-62.7, -0.18, 72.0), # Step 2: At water line
		Vector3(-62.1, -0.08, 72.0), # Step 3: Above water line
		Vector3(-61.5,  0.02, 72.0)  # Step 4: Flush with promenade
	]
	for step_idx in range(stair_steps_data.size()):
		var step = MeshInstance3D.new()
		step.name = "SeaStairStep_%d" % step_idx
		var st_mesh = BoxMesh.new()
		st_mesh.size = Vector3(0.68, 0.14, 3.2)
		step.mesh = st_mesh
		step.material_override = stair_mat
		step.position = stair_steps_data[step_idx]
		parent.add_child(step)

	# Walkable Incline Collider for Sea Stairs
	var sea_stairs_body = StaticBody3D.new()
	sea_stairs_body.name = "SeaStairsCollider"
	sea_stairs_body.collision_layer = 1
	var ssc_col = CollisionShape3D.new()
	var ssc_box = BoxShape3D.new()
	ssc_box.size = Vector3(2.6, 0.18, 3.2)
	ssc_col.shape = ssc_box
	ssc_col.position = Vector3(-62.4, -0.13, 72.0)
	ssc_col.rotation_degrees.z = -7.5
	sea_stairs_body.add_child(ssc_col)
	parent.add_child(sea_stairs_body)

	# Stone balustrade posts with warm navigational lanterns flanking the stairs
	_place_lantern_post(parent, Vector3(-61.5, 0.04, 70.3), 0.0)
	_place_lantern_post(parent, Vector3(-61.5, 0.04, 73.7), 0.0)

	# Quay Wall Boarding Ladder (North Quay section at X = -61.4, Z = 54.0)
	var quay_ladder = HarborLadder3DScript.new()
	quay_ladder.name = "QuayBoardingLadder"
	quay_ladder.position = Vector3(-61.4, -0.05, 54.0)
	quay_ladder.rotation_degrees.y = 90.0
	quay_ladder.target_deck_position = Vector3(-60.2, 0.05, 54.0)
	parent.add_child(quay_ladder)

	# 4. Flat Walkable Timber Harbor Piers extending West over the Ocean Water
	# North Main Pier at Z = 62.0 (X from -61.5 out to -90.5)
	_build_wooden_harbor_pier(parent, "NorthMainPier", -61.5, -90.5, 62.0, 4.2)
	# South Corsair Pier at Z = 82.0 (X from -61.5 out to -86.5)
	_build_wooden_harbor_pier(parent, "SouthCorsairPier", -61.5, -86.5, 82.0, 4.2)

	# Harbor Watchman Patrol along the North Main Pier
	var harbor_guard = PatrolNPCScript.new()
	harbor_guard.npc_name = "Boatswain Finn"
	harbor_guard.npc_title = "Pier Watchman"
	harbor_guard.position = Vector3(-63.0, 0.25, 62.0)
	harbor_guard.waypoints = [
		Vector3(-63.0, 0.25, 62.0),
		Vector3(-86.0, 0.25, 62.0),
		Vector3(-86.0, 0.25, 62.0),
		Vector3(-63.0, 0.25, 62.0)
	]
	parent.add_child(harbor_guard)

	# 5. Port Blackwater Settlement Buildings (Aligned along the Harbor Promenade facing West toward the Sea)
	# Harbormaster Watchtower (North end of Promenade at X = -52.0, Z = 48.0)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-52.0, 0.0, 48.0), Vector3.ONE * 8.0)
	_add_static_box(parent, Vector3(-52.0, 6.0, 48.0), Vector3(4.5, 12.0, 4.5))

	# Smuggler's Headland Boathouse (On the dry North Headland overlooking the harbor at X = -70.0, Z = 38.0)
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(-70.0, 0.0, 38.0), Vector3.ONE * 6.5, 0.0)
	_add_static_box(parent, Vector3(-70.0, 3.5, 38.0), Vector3(6.0, 6.5, 6.0))

	# Harbor Fish Market Stalls (Facing West -90° onto the Promenade at X = -48.0, Z = 60.0)
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-48.0, 0.0, 60.0), Vector3.ONE * 4.0, -90.0)
	_add_static_box(parent, Vector3(-48.0, 2.5, 60.0), Vector3(5.5, 5.0, 6.0))

	# The Rusty Anchor Harbor Tavern (Facing West -90° onto the Promenade at X = -47.5, Z = 72.0; doorway at X = -51.8, Z = 72.0)
	_place_prop(parent, "res://assets/overworld/building_tavern_blue.gltf", Vector3(-47.5, 0.0, 72.0), Vector3.ONE * 6.2, -90.0)
	_add_static_box(parent, Vector3(-47.5, 4.5, 72.0), Vector3(7.5, 9.0, 8.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-47.5, 8.2, 72.0))

	# Port Blackwater Customs House & Shipwright Workshop (South Promenade: X = -47.5, Z = 84.0, facing West -90°)
	_place_prop(parent, "res://assets/overworld/building_home_A_yellow.gltf", Vector3(-47.5, 0.0, 84.0), Vector3.ONE * 5.8, -90.0)
	_add_static_box(parent, Vector3(-47.5, 3.5, 84.0), Vector3(6.5, 7.0, 6.5))
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-51.5, 0.04, 82.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-51.5, 0.04, 86.0), Vector3.ONE * 1.4)

	# NPC: Master Owen the Shipwright
	var owen = TownNPCScript.new()
	owen.npc_id = "shipwright_owen"
	owen.npc_name = "Master Owen"
	owen.npc_title = "Port Shipwright"
	owen.icon = "🔨"
	owen.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	owen.model_scale = Vector3(0.53, 0.53, 0.53)
	owen.model_rotation_y = -90.0
	owen.dialogue_text = "Good oak timber and pitch keep our cogs afloat against the sea swells. If your vessel needs a stout gangplank or sturdy oars, my workshop has the finest craftsmen in Blackwater!"
	owen.position = Vector3(-52.5, 0.04, 84.0)
	parent.add_child(owen)

	# Interactive Harbor Market Stall (Smuggler's Fish & Provisions)
	var harbor_stall = MarketStall3DScript.new()
	harbor_stall.stall_name = "Blackwater Smuggler's Fish & Provisions"
	harbor_stall.canopy_color = "red"
	harbor_stall.position = Vector3(-54.0, 0.0, 68.0)
	harbor_stall.rotation_degrees.y = -90.0
	parent.add_child(harbor_stall)

	# Dockside Cargo Barrels, Pallets & Storage Piles
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(-58.0, 0.04, 64.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_long_A.gltf", Vector3(-58.0, 0.04, 64.5), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-57.2, 0.04, 65.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/post_lantern.gltf", Vector3(-61.2, 0.04, 64.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/post_lantern.gltf", Vector3(-61.2, 0.04, 80.0), Vector3.ONE * 1.8)

	# Harbor Cargo Stacks (Spaced neatly along the Quay Wall)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-59.5, 0.04, 57.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-59.5, 0.04, 55.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(-59.5, 0.04, 75.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(-59.5, 0.04, 77.5), Vector3.ONE * 1.4)

	# Offshore Reef Rocks & Sea Reeds in the Ocean Basin
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-68.0, -0.35, 49.0), Vector3.ONE * 2.8, 35.0)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(-76.0, -0.35, 52.0), Vector3.ONE * 3.0, -45.0)
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-92.0, -0.40, 74.0), Vector3.ONE * 3.5, 60.0)
	_place_prop(parent, "res://assets/overworld/waterplant_A.gltf", Vector3(-65.0, -0.15, 55.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(-65.0, -0.15, 76.0), Vector3.ONE * 1.8)

	# 6. Naval Harbor Fleet: Moored Medieval Cogs & Rowboats Floating in the Ocean Basin!
	#    Rotated 90° so their hulls lie parallel to the piers in deep water (X in [-86, -66])
	#    and their starboard boarding gangplanks rest directly on the pier decks!
	var flagship = MedievalShip3DScript.new()
	flagship.ship_name = "The Sea Sovereign"
	flagship.sail_color = Color(0.90, 0.84, 0.70)
	flagship.has_gangplank = true
	flagship.position = Vector3(-76.0, -0.22, 67.6)
	flagship.rotation_degrees.y = 90.0
	parent.add_child(flagship)

	var corsair_cog = MedievalShip3DScript.new()
	corsair_cog.ship_name = "The Crimson Kraken"
	corsair_cog.sail_color = Color(0.78, 0.22, 0.18)
	corsair_cog.has_gangplank = true
	corsair_cog.position = Vector3(-74.0, -0.22, 87.6)
	corsair_cog.rotation_degrees.y = 90.0
	parent.add_child(corsair_cog)

	var rowboat_1 = MedievalShip3DScript.new()
	rowboat_1.ship_name = "Harbor Skiff"
	rowboat_1.is_rowboat = true
	rowboat_1.has_gangplank = false
	rowboat_1.position = Vector3(-68.0, -0.15, 54.0)
	rowboat_1.rotation_degrees.y = 65.0
	parent.add_child(rowboat_1)

	var rowboat_2 = MedievalShip3DScript.new()
	rowboat_2.ship_name = "Fisherman's Dory"
	rowboat_2.is_rowboat = true
	rowboat_2.has_gangplank = false
	rowboat_2.position = Vector3(-68.0, -0.15, 74.0)
	rowboat_2.rotation_degrees.y = -75.0
	parent.add_child(rowboat_2)

	# 7. Colony of Coastal Harbor Seals basking on offshore reef rocks & sandy beach
	var seal_locs = [
		{"pos": Vector3(-68.0, 0.25, 49.0), "rot": 60.0, "name": "Basking Harbor Seal"},
		{"pos": Vector3(-76.0, 0.30, 52.0), "rot": 110.0, "name": "Spotted Reef Seal"},
		{"pos": Vector3(-60.5, 0.05, 92.0), "rot": 85.0, "name": "Silvervein Harbor Seal"},
		{"pos": Vector3(-58.5, 0.05, 96.0), "rot": 45.0, "name": "Shoreline Seal Pup"}
	]
	for sl in seal_locs:
		var seal = HarborSeal3DScript.new()
		seal.seal_name = sl["name"]
		seal.position = sl["pos"]
		seal.rotation_degrees.y = sl["rot"]
		parent.add_child(seal)

	# 8. Port Blackwater NPCs
	var fishmonger = TownNPCScript.new()
	fishmonger.npc_id = "fishmonger_greta"
	fishmonger.npc_name = "Greta"
	fishmonger.npc_title = "Harbor Fishmonger"
	fishmonger.icon = "🐟"
	fishmonger.model_path = "res://assets/characters/adventurers/Mage.glb"
	fishmonger.model_scale = Vector3(0.52, 0.52, 0.52)
	fishmonger.model_rotation_y = -90.0
	fishmonger.dialogue_text = "Fresh silver-herring, salted cod, and smoked eels straight from the morning nets! Watch the harbor seals out on the rocks—they always bark before a storm rolls in!"
	fishmonger.position = Vector3(-52.5, 0.04, 60.0)
	parent.add_child(fishmonger)

	var marlo = TownNPCScript.new()
	marlo.npc_id = "captain_marlo"
	marlo.npc_name = "Captain Marlo"
	marlo.npc_title = "Corsair Captain"
	marlo.icon = "⚓"
	marlo.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
	marlo.model_scale = Vector3(0.55, 0.55, 0.55)
	marlo.model_rotation_y = -90.0
	marlo.dialogue_text = "Ahoy, landlubber! Welcome to Port Blackwater. Look out at our cogs moored in the harbor basin! The Deep Sea Creeps have infested the southern cove and stolen the Tidecaller's Compass—bring it back to claim the corsair fortune!"
	marlo.position = Vector3(-56.0, 0.04, 68.5)
	parent.add_child(marlo)

	var corin = TownNPCScript.new()
	corin.npc_id = "harbormaster"
	corin.npc_name = "Harbormaster Corin"
	corin.npc_title = "Port Warden"
	corin.icon = "🧭"
	corin.model_path = "res://assets/characters/adventurers/Knight.glb"
	corin.model_scale = Vector3(0.56, 0.56, 0.56)
	corin.model_rotation_y = 180.0
	corin.dialogue_text = "Welcome to Port Blackwater. Keep your weapons ready—corsairs brawl on the southern beach, and strange abominations crawl from the seabed. Check the harbor bounties to keep our port safe!"
	corin.position = Vector3(-55.0, 0.04, 52.0)
	parent.add_child(corin)

	# First Mate Kaelen (Standing on the main weather deck of The Sea Sovereign)
	var kaelen = TownNPCScript.new()
	kaelen.npc_id = "first_mate_kaelen"
	kaelen.npc_name = "First Mate Kaelen"
	kaelen.npc_title = "High-Seas Voyager"
	kaelen.icon = "⚓"
	kaelen.model_path = "res://assets/characters/adventurers/Rogue.glb"
	kaelen.model_scale = Vector3(0.53, 0.53, 0.53)
	kaelen.model_rotation_y = 90.0
	kaelen.dialogue_text = "Ahoy! The Sea Sovereign weathered a fierce gale past the Kraken Shoals. The tides run deep, but our timber hull holds firm. Walk up the gangplank to inspect our decks!"
	kaelen.position = Vector3(-73.5, 1.85, 68.0)
	parent.add_child(kaelen)

	# Quartermaster Thaddeus (Stationed along the North Main Pier overseeing ship manifests)
	var thaddeus = TownNPCScript.new()
	thaddeus.npc_id = "quartermaster_thaddeus"
	thaddeus.npc_name = "Quartermaster Thaddeus"
	thaddeus.npc_title = "Harbor Manifest Officer"
	thaddeus.icon = "📜"
	thaddeus.model_path = "res://assets/characters/adventurers/Knight.glb"
	thaddeus.model_scale = Vector3(0.52, 0.52, 0.52)
	thaddeus.model_rotation_y = 180.0
	thaddeus.dialogue_text = "Cargo manifests, iron ingots, and dried rations—all trade entering Port Blackwater passes my inspection. Watch your step along the wooden dock pilings!"
	thaddeus.position = Vector3(-65.0, 0.04, 62.0)
	parent.add_child(thaddeus)

	# 9. Interactive World Restoration Station: Harbor Cargo Crane (On the Quay at X = -59.5, Z = 66.5)
	var crane_station = WorldRepairStationScript.new()
	crane_station.repair_id = "port_crane"
	crane_station.station_name = "Harbor Cargo Crane"
	crane_station.required_materials = {"lumber": 1, "iron_ore": 1}
	crane_station.target_story_act = 2
	crane_station.gold_reward = 150
	crane_station.echo_reward = 50
	crane_station.position = Vector3(-59.5, 0.04, 66.5)
	var ruined_crane = _place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(-59.5, 0.04, 66.5), Vector3.ONE * 1.5, 0.0)
	var restored_crane = _place_prop(parent, "res://assets/overworld/building_scaffolding.gltf", Vector3(-59.5, 0.04, 66.5), Vector3(1.8, 2.4, 1.8), 0.0)
	_place_prop(restored_crane, "res://assets/overworld/crate_A_big.gltf", Vector3(0.0, 0.0, 0.0), Vector3.ONE * 0.7)
	crane_station.ruined_node = ruined_crane
	crane_station.restored_node = restored_crane
	parent.add_child(crane_station)

	# 10. Enemies & Quest Relics (Placed along the South Corsair Pier & Sandy Beach Cove)
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-72.0, 0.25, 82.0), 90.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-56.0, 0.02, 92.0), 30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-52.0, 0.02, 98.0), 110.0)

	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(-58.0, 0.02, 105.0), 45.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(-52.0, 0.02, 110.0), -120.0)

	# The Tidecaller's Compass & Sunken Corsair Chest
	_spawn_material_node(parent, "tidecaller_compass", "The Tidecaller's Compass", "🧭", "res://assets/items/quest_materials/Chalice.glb", Vector3(-56.0, 0.05, 108.0), Color(0.18, 0.75, 0.95), 80, 60, Vector3(2.2, 2.2, 2.2))
	_spawn_material_node(parent, "smugglers_chest", "Sunken Corsair Chest", "📦", "res://assets/items/quest_materials/Chest_Ingots.glb", Vector3(-84.0, 0.25, 82.0), Color(0.95, 0.8, 0.2), 60, 45, Vector3(1.6, 1.6, 1.6))

	# 11. Harbor Coastal Defenses: Artillery Watchtower & Bronze Alarm Bell
	var defense_tower = HarborDefenseTower3DScript.new()
	defense_tower.position = Vector3(-66.0, 0.0, 43.5)
	parent.add_child(defense_tower)

	var alarm_bell = HarborAlarmBell3DScript.new()
	alarm_bell.position = Vector3(-51.5, 0.04, 66.0)
	parent.add_child(alarm_bell)

	# Harbor Pier Swivel Cannons (Coastal battery at the ends of North & South piers)
	var swivel_scene = load("res://assets/ships/cannon-mobile.glb")
	if not swivel_scene:
		swivel_scene = load("res://assets/ships/cannon.glb")
	if swivel_scene:
		var sw1 = swivel_scene.instantiate()
		sw1.scale = Vector3.ONE * 1.5
		sw1.position = Vector3(-89.0, 0.25, 62.0)
		sw1.rotation_degrees.y = -90.0 # Facing open ocean
		parent.add_child(sw1)

		var sw2 = swivel_scene.instantiate()
		sw2.scale = Vector3.ONE * 1.5
		sw2.position = Vector3(-85.0, 0.25, 82.0)
		sw2.rotation_degrees.y = -90.0
		parent.add_child(sw2)

	# Floating Harbor Defense Buoys (Channel markers)
	var buoy_scene = load("res://assets/ships/buoy-flag.glb")
	if buoy_scene:
		var b1 = buoy_scene.instantiate()
		b1.scale = Vector3.ONE * 1.4
		b1.position = Vector3(-96.0, -0.15, 52.0)
		parent.add_child(b1)

		var b2 = buoy_scene.instantiate()
		b2.scale = Vector3.ONE * 1.4
		b2.position = Vector3(-96.0, -0.15, 92.0)
		parent.add_child(b2)

	# 12. Enemy Corsair Invasion Warship (Patrolling offshore in the ocean basin)
	var enemy_corsair = EnemyNavalShip3DScript.new()
	enemy_corsair.ship_name = "The Blood Moon"
	enemy_corsair.position = Vector3(-120.0, -0.22, 70.0)
	enemy_corsair.rotation_degrees.y = -90.0
	parent.add_child(enemy_corsair)

	# 13. Port Blackwater & Ships Expansion: Lighthouse, Shipwreck Cove, Drydock, Tavern Terrace, Fishing Spot & Stevedores
	var lighthouse = HarborLighthouse3DScript.new()
	lighthouse.position = Vector3(-84.0, 0.0, 38.0)
	parent.add_child(lighthouse)

	var shipwreck = ShipwreckCove3DScript.new()
	shipwreck.position = Vector3(-118.0, -0.3, 114.0)
	parent.add_child(shipwreck)

	var drydock = ShipwrightDrydock3DScript.new()
	drydock.position = Vector3(-60.0, 0.0, 50.0)
	parent.add_child(drydock)

	var terrace = HarborTavernTerrace3DScript.new()
	terrace.position = Vector3(-54.0, 0.04, 73.0)
	parent.add_child(terrace)

	var fishing_spot = HarborFishingSpot3DScript.new()
	fishing_spot.position = Vector3(-84.0, 0.25, 84.0)
	parent.add_child(fishing_spot)

	var dockworker = DockworkerNPCScript.new()
	dockworker.position = Vector3(-58.0, 0.04, 76.0)
	parent.add_child(dockworker)

	# 14. Corsair Archipelago & Red Skull Bastion Offshore Fortress
	# Barrier rocky islets and natural sea crags in open ocean
	_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(-150.0, -0.6, 75.0), Vector3(6.5, 4.0, 6.5))
	_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(-170.0, -0.4, 135.0), Vector3(8.5, 5.0, 8.5))
	_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(-135.0, -0.6, 175.0), Vector3(7.0, 4.5, 7.0))

	# Red Skull Bastion offshore fort on the largest islet
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_red.gltf", Vector3(-170.0, 1.8, 135.0), Vector3.ONE * 5.5)
	_add_static_box(parent, Vector3(-170.0, 4.5, 135.0), Vector3(5.0, 9.0, 5.0))
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-166.0, 1.8, 134.0), Vector3.ONE * 1.8)

	# 15. Autonomous Hostile Pirate Warships (EnemyShipAI3D) with broadside cannons, ramming & loot drops
	var corsair_cog_1 = EnemyShipAI3DScript.new()
	corsair_cog_1.ship_name = "Crimson Skull Cog"
	corsair_cog_1.position = Vector3(-145.0, -0.22, 110.0)
	corsair_cog_1.patrol_waypoints = [
		Vector3(-145.0, -0.22, 110.0),
		Vector3(-165.0, -0.22, 85.0),
		Vector3(-140.0, -0.22, 60.0),
		Vector3(-125.0, -0.22, 95.0)
	]
	parent.add_child(corsair_cog_1)

	var corsair_cog_2 = EnemyShipAI3DScript.new()
	corsair_cog_2.ship_name = "Dread Serpent Cog"
	corsair_cog_2.position = Vector3(-150.0, -0.22, 160.0)
	corsair_cog_2.patrol_waypoints = [
		Vector3(-150.0, -0.22, 160.0),
		Vector3(-175.0, -0.22, 140.0),
		Vector3(-160.0, -0.22, 175.0),
		Vector3(-130.0, -0.22, 180.0)
	]
	parent.add_child(corsair_cog_2)

func _build_wooden_harbor_pier(parent: Node3D, pier_name: String, x_start: float, x_end: float, z_center: float, width: float) -> void:
	var pier_root = Node3D.new()
	pier_root.name = pier_name
	parent.add_child(pier_root)

	var length = abs(x_start - x_end)
	var x_mid = (x_start + x_end) * 0.5

	var wood_deck_mat = StandardMaterial3D.new()
	wood_deck_mat.albedo_color = Color(0.38, 0.25, 0.14)
	wood_deck_mat.roughness = 0.88

	var wood_beam_mat = StandardMaterial3D.new()
	wood_beam_mat.albedo_color = Color(0.26, 0.17, 0.09)
	wood_beam_mat.roughness = 0.92

	# Continuous Timber Stringer Beams
	for side in [-1.0, 1.0]:
		var beam = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(length, 0.22, 0.26)
		beam.mesh = b_mesh
		beam.material_override = wood_beam_mat
		beam.position = Vector3(x_mid, 0.10, z_center + side * (width * 0.5 - 0.15))
		pier_root.add_child(beam)

	# Transverse Wooden Deck Planks
	var plank_step = 0.65
	var x_cursor = x_end + 0.4
	while x_cursor <= x_start - 0.2:
		var plank = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(0.55, 0.08, width)
		plank.mesh = p_mesh
		plank.material_override = wood_deck_mat
		plank.position = Vector3(x_cursor, 0.22, z_center)
		pier_root.add_child(plank)
		x_cursor += plank_step

	# Heavy Timber Pilings driven deep into the Ocean Seabed (Y = -1.25 to +0.65)
	var piling_x = x_start - 1.5
	var piling_idx = 0
	while piling_x >= x_end + 0.5:
		for side in [-1.0, 1.0]:
			var piling = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.20
			cyl.bottom_radius = 0.22
			cyl.height = 1.95
			piling.mesh = cyl
			piling.material_override = wood_beam_mat
			piling.position = Vector3(piling_x, -0.30, z_center + side * (width * 0.5 + 0.10))
			pier_root.add_child(piling)
		if piling_idx % 2 == 1:
			_place_lantern_post(pier_root, Vector3(piling_x, 0.24, z_center - width * 0.42), 90.0)
		piling_x -= 4.5
		piling_idx += 1

	# Walkable Pier Deck Collider & Smooth Approach Ramp from the Quay
	var sb = StaticBody3D.new()
	sb.name = pier_name + "_Collider"
	sb.collision_layer = 1
	var deck_col = CollisionShape3D.new()
	var deck_box = BoxShape3D.new()
	deck_box.size = Vector3(length + 1.0, 0.26, width)
	deck_col.shape = deck_box
	deck_col.position = Vector3(x_mid, 0.13, z_center)
	sb.add_child(deck_col)

	var ramp_col = CollisionShape3D.new()
	var ramp_box = BoxShape3D.new()
	ramp_box.size = Vector3(2.2, 0.20, width)
	ramp_col.shape = ramp_box
	ramp_col.position = Vector3(x_start + 0.8, 0.10, z_center)
	ramp_col.rotation_degrees.z = -7.0
	sb.add_child(ramp_col)

	# Low-Water Boat Landing Platform & Incline Gangway Ramp (Water Egress)
	# Sits at Y = -0.10m (just 5cm above water) so any swimming player can climb/walk up effortlessly
	var low_landing = MeshInstance3D.new()
	low_landing.name = pier_name + "_LowLandingVisual"
	var ll_mesh = BoxMesh.new()
	ll_mesh.size = Vector3(4.6, 0.14, 2.0)
	low_landing.mesh = ll_mesh
	low_landing.material_override = wood_deck_mat
	low_landing.position = Vector3(-75.0, -0.10, z_center - width * 0.5 - 1.0)
	pier_root.add_child(low_landing)

	var landing_col = CollisionShape3D.new()
	var l_box = BoxShape3D.new()
	l_box.size = Vector3(4.6, 0.20, 2.0)
	landing_col.shape = l_box
	landing_col.position = Vector3(-75.0, -0.10, z_center - width * 0.5 - 1.0)
	sb.add_child(landing_col)

	# Inclined Wooden Gangway connecting low landing (Y = -0.10m) up to pier deck (Y = 0.24m)
	var gangway = MeshInstance3D.new()
	gangway.name = pier_name + "_GangwayVisual"
	var gw_mesh = BoxMesh.new()
	gw_mesh.size = Vector3(1.6, 0.10, 1.8)
	gangway.mesh = gw_mesh
	gangway.material_override = wood_deck_mat
	gangway.position = Vector3(-73.5, 0.07, z_center - width * 0.5 - 0.2)
	gangway.rotation_degrees.x = -13.0
	pier_root.add_child(gangway)

	var gw_col = CollisionShape3D.new()
	var gw_box = BoxShape3D.new()
	gw_box.size = Vector3(1.6, 0.16, 1.8)
	gw_col.shape = gw_box
	gw_col.position = Vector3(-73.5, 0.07, z_center - width * 0.5 - 0.2)
	gw_col.rotation_degrees.x = -13.0
	sb.add_child(gw_col)

	pier_root.add_child(sb)

	# Interactive Boarding Ladders dipping into the sea along pier flanks
	# South Ladder
	var lad_south = HarborLadder3DScript.new()
	lad_south.name = pier_name + "_LadderSouth"
	lad_south.position = Vector3(-71.0, 0.0, z_center - width * 0.5 - 0.06)
	lad_south.rotation_degrees.y = 0.0
	lad_south.target_deck_position = Vector3(-71.0, 0.26, z_center)
	pier_root.add_child(lad_south)

	# North Ladder
	var lad_north = HarborLadder3DScript.new()
	lad_north.name = pier_name + "_LadderNorth"
	lad_north.position = Vector3(-82.0, 0.0, z_center + width * 0.5 + 0.06)
	lad_north.rotation_degrees.y = 180.0
	lad_north.target_deck_position = Vector3(-82.0, 0.26, z_center)
	pier_root.add_child(lad_north)

# =========================================================================
# REGION 2: WHISPERWOOD FOREST & SYLVA'S REST
# =========================================================================
func _build_whisperwood_forest_region(parent: Node3D) -> void:
	# 1. Sylva's Rest Woodland Glade (Centered at X = -76, Z = -64)
	#    Surrounded by a natural perimeter of tall pines (outside the glade so zero trees clip buildings!)
	var f_trees = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/trees_B_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	var forest_coords = [
		Vector3(-42.0, 0.0, -44.0), Vector3(-68.0, 0.0, -38.0), Vector3(-82.0, 0.0, -42.0),
		Vector3(-94.0, 0.0, -42.0), Vector3(-106.0, 0.0, -48.0), Vector3(-98.0, 0.0, -58.0),
		Vector3(-108.0, 0.0, -68.0), Vector3(-98.0, 0.0, -76.0), Vector3(-108.0, 0.0, -86.0),
		Vector3(-92.0, 0.0, -90.0), Vector3(-78.0, 0.0, -92.0), Vector3(-64.0, 0.0, -88.0),
		Vector3(-54.0, 0.0, -74.0), Vector3(-54.0, 0.0, -58.0), Vector3(-86.0, 0.0, -104.0),
		Vector3(-102.0, 0.0, -102.0)
	]
	for i in range(forest_coords.size()):
		var f_pos = forest_coords[i]
		var t_model = f_trees[i % f_trees.size()]
		_place_prop(parent, t_model, f_pos, Vector3.ONE * 2.3, float((i * 43) % 360))
		_add_static_cyl(parent, f_pos, 1.0, 7.5)

	# Forest Fireflies & Atmospheric Spores
	AmbientFX.create_forest_fireflies(parent, Vector3(-76.0, 2.0, -64.0), 12.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(-90.0, 2.0, -78.0), 14.0)

	# 2. Sylva's Rest Enclave Buildings (Arranged around the Open Glade)
	# Elder Druid's Stone Circle Shrine (West side of Glade at X = -84.0, Z = -64.0)
	var hunt_shrine = AncientShrine3DScript.new()
	hunt_shrine.shrine_type = AncientShrine3DScript.ShrineType.HUNT
	hunt_shrine.shrine_name = "Ancient Waystone of the Wild Hunt"
	hunt_shrine.position = Vector3(-84.0, 0.0, -64.0)
	hunt_shrine.rotation_degrees.y = 90.0
	parent.add_child(hunt_shrine)

	# Whisperwood Ranger Campfire Rest Site in the Glade center
	var forest_campfire = CampfireRestSite3DScript.new()
	forest_campfire.site_name = "Sylva's Rest Woodland Hearth"
	forest_campfire.position = Vector3(-74.0, 0.0, -64.0)
	parent.add_child(forest_campfire)

	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-86.0, 0.0, -59.5), Vector3(1.5, 2.5, 1.5))
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-86.0, 0.0, -68.5), Vector3(1.5, 2.5, 1.5))
	_add_static_cyl(parent, Vector3(-86.0, 0.0, -59.5), 0.9, 7.5)
	_add_static_cyl(parent, Vector3(-86.0, 0.0, -68.5), 0.9, 7.5)

	# Ranger Outpost Cottage (East side of Glade at X = -64.0, Z = -60.0, facing West -90°)
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(-64.0, 0.0, -60.0), Vector3.ONE * 6.2, -90.0)
	_add_static_box(parent, Vector3(-64.0, 3.5, -60.0), Vector3(6.2, 6.8, 7.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-64.0, 7.8, -60.0))

	# Woodland Sawmill (North side of Glade at X = -74.0, Z = -76.0, facing South 0°)
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-74.0, 0.0, -76.0), Vector3.ONE * 5.2, 0.0)
	_add_static_box(parent, Vector3(-74.0, 4.0, -76.0), Vector3(7.0, 6.5, 7.0))

	# Whisperwood Herbalist & Apothecary Cottage (South edge of Glade: X = -74.0, Z = -52.0, facing North 180°)
	_place_prop(parent, "res://assets/overworld/building_home_A_green.gltf", Vector3(-74.0, 0.0, -52.0), Vector3.ONE * 5.6, 180.0)
	_add_static_box(parent, Vector3(-74.0, 3.5, -52.0), Vector3(6.5, 6.5, 6.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(-74.0, 7.2, -52.0))
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-70.5, 0.0, -55.5), Vector3.ONE * 2.0, 45.0)

	# NPC: Sylas the Apprentice Herbalist
	var sylas = TownNPCScript.new()
	sylas.npc_id = "herbalist_sylas"
	sylas.npc_name = "Sylas"
	sylas.npc_title = "Forest Herbalist"
	sylas.icon = "🌱"
	sylas.model_path = "res://assets/characters/adventurers/Mage.glb"
	sylas.model_scale = Vector3(0.52, 0.52, 0.52)
	sylas.model_rotation_y = 180.0
	sylas.dialogue_text = "The forest canopy whispers ancient secrets to those who listen. I brew restorative teas from golden chanterelles and pine needles. May your steps through Whisperwood be peaceful!"
	sylas.position = Vector3(-74.0, 0.0, -56.5)
	parent.add_child(sylas)

	# 3. NPCs
	var thorne = TownNPCScript.new()
	thorne.npc_id = "druid_thorne"
	thorne.npc_name = "Elder Thorne"
	thorne.npc_title = "Circle Druid"
	thorne.icon = "🌿"
	thorne.model_path = "res://assets/characters/adventurers/Mage.glb"
	thorne.model_scale = Vector3(0.54, 0.54, 0.54)
	thorne.model_rotation_y = 90.0
	thorne.dialogue_text = "Peace be upon your spirit, traveler. Whisperwood Forest suffers under bandit outlaws who felled the sacred grove and severed the Living Heartwood. Drive back the highwaymen, return the Heartwood to the shrine, and receive nature's eternal rejuvenation!"
	thorne.position = Vector3(-80.0, 0.0, -64.0)
	parent.add_child(thorne)

	var elora = TownNPCScript.new()
	elora.npc_id = "ranger_elora"
	elora.npc_name = "Ranger Elora"
	elora.npc_title = "Woodland Scout"
	elora.icon = "🏹"
	elora.model_path = "res://assets/characters/adventurers/Rogue.glb"
	elora.model_scale = Vector3(0.53, 0.53, 0.53)
	elora.model_rotation_y = -90.0
	elora.dialogue_text = "Tread lightly. Bandit outlaws and hungry timber wolves stalk the shadows of the pines. Clear the woods and our scouts will ensure your safe passage across the realm!"
	elora.position = Vector3(-68.5, 0.0, -58.5)
	parent.add_child(elora)

	# Interactive World Restoration Station: Druidic Sun Altar
	var altar_station = WorldRepairStationScript.new()
	altar_station.repair_id = "druid_altar"
	altar_station.station_name = "Whisperwood Sun Altar"
	altar_station.required_materials = {"arcane_crystal": 1, "emerald_crystal": 1}
	altar_station.target_story_act = 3
	altar_station.gold_reward = 150
	altar_station.echo_reward = 50
	altar_station.position = Vector3(-76.0, 0.0, -68.0)
	var ruined_altar = _place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-76.0, 0.0, -68.0), Vector3.ONE * 2.0, 0.0)
	var restored_altar = _place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-76.0, 0.0, -68.0), Vector3.ONE * 2.4, 0.0)
	var a_light = OmniLight3D.new()
	a_light.light_color = Color(0.2, 1.0, 0.4)
	a_light.light_energy = 2.2
	a_light.omni_range = 8.0
	a_light.position.y = 1.8
	restored_altar.add_child(a_light)
	altar_station.ruined_node = ruined_altar
	altar_station.restored_node = restored_altar
	parent.add_child(altar_station)

	# 4. Enemies, Wildlife & Quest Relics
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-90.0, 0.0, -52.0), 60.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-96.0, 0.0, -66.0), -30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-86.0, 0.0, -82.0), 140.0)

	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-94.0, 0.0, -80.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-102.0, 0.0, -88.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-74.0, 0.0, -48.0), 90.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-78.0, 0.0, -51.0), -45.0)

	_spawn_material_node(parent, "living_heartwood", "The Living Heartwood", "🌱", "res://assets/overworld/resource_lumber.gltf", Vector3(-88.0, 0.0, -74.0), Color(0.25, 0.88, 0.35), 80, 60, Vector3(2.6, 2.6, 2.6))
	_spawn_material_node(parent, "heartwood_timber", "Ancient Ironwood", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-92.0, 0.0, -56.0), Color(0.8, 0.5, 0.2), 30, 20, Vector3(2.2, 2.2, 2.2))

# =========================================================================
# REGION 3: KHAR-DRAKKEN CRAGS & ORC BASTION
# =========================================================================
func _build_khar_drakken_crags_region(parent: Node3D) -> void:
	# 1. Horseshoe Mountain Massifs framing Stonegate Valley & the Upper Orc Bastion
	#    Spaced >= 24m apart so peaks form a dramatic canyon without intersecting each other
	var crag_peaks = [
		{"pos": Vector3(68.0, 0.0, -32.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 9.0},
		{"pos": Vector3(92.0, 0.0, -42.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 9.5},
		{"pos": Vector3(54.0, 0.0, -74.0), "path": "res://assets/overworld/mountain_A_grass.gltf", "scale": 9.0},
		{"pos": Vector3(78.0, 0.0, -82.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 9.5},
		{"pos": Vector3(106.0, 0.0, -66.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 9.5},
		{"pos": Vector3(116.0, 0.0, -92.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 10.0},
		{"pos": Vector3(88.0, 0.0, -114.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 10.0},
		{"pos": Vector3(112.0, 0.0, -114.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 10.0}
	]
	for cp in crag_peaks:
		_place_prop(parent, cp["path"], cp["pos"], Vector3.ONE * cp["scale"])
		_add_static_box(parent, cp["pos"] + Vector3(0, 7.0, 0), Vector3(cp["scale"] * 1.9, 14.0, cp["scale"] * 1.9))

	# 2. Stonegate Dwarven Mining Settlement (Valley Floor: X in [58, 82], Z in [-66, -44])
	# Ancestral Deep Mine Shaft (East wall of valley at X = 78.0, Z = -52.0, facing West -90°; doorway at X = 74.0, Z = -52.0)
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(78.0, 0.0, -52.0), Vector3.ONE * 5.8, -90.0)
	_add_static_box(parent, Vector3(78.0, 3.5, -52.0), Vector3(7.5, 6.5, 7.5))

	# Dwarven Smelting Foundry Building (North side of valley at X = 66.0, Z = -62.0, facing South 0°)
	_place_prop(parent, "res://assets/overworld/building_blacksmith_red.gltf", Vector3(66.0, 0.0, -62.0), Vector3.ONE * 5.5, 0.0)
	_add_static_box(parent, Vector3(66.0, 3.5, -62.0), Vector3(6.8, 6.5, 6.8))
	AmbientFX.create_chimney_smoke(parent, Vector3(66.0, 7.2, -62.0))

	# Mountain Watchtower guarding the Southwest Pass (X = 56.0, Z = -44.0)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(56.0, 0.0, -44.0), Vector3.ONE * 8.0)
	_add_static_box(parent, Vector3(56.0, 6.0, -44.0), Vector3(4.5, 12.0, 4.5))

	# Dwarven Ore Assay Depot & Mining Supply House (Valley Center: X = 65.0, Z = -46.0, facing South 0°)
	_place_prop(parent, "res://assets/overworld/building_home_A_red.gltf", Vector3(65.0, 0.0, -46.0), Vector3.ONE * 5.4, 0.0)
	_add_static_box(parent, Vector3(65.0, 3.5, -46.0), Vector3(6.2, 6.5, 6.2))
	AmbientFX.create_chimney_smoke(parent, Vector3(65.0, 6.8, -46.0))
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(61.5, 0.0, -42.0), Vector3.ONE * 1.4, 25.0)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(68.5, 0.0, -42.5), Vector3.ONE * 1.3)

	# NPC: Thordin the Highland Prospector
	var thordin = TownNPCScript.new()
	thordin.npc_id = "prospector_thordin"
	thordin.npc_name = "Thordin"
	thordin.npc_title = "Dwarven Prospector"
	thordin.icon = "💎"
	thordin.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	thordin.model_scale = Vector3(0.52, 0.52, 0.52)
	thordin.model_rotation_y = 0.0
	thordin.dialogue_text = "Gold veins run deep through the granite beneath Khar-Drakken! Keep your eyes keen for raw mineral crystals in the crags—ancient treasures lie hidden where the earth breaks open!"
	thordin.position = Vector3(65.0, 0.0, -41.5)
	parent.add_child(thordin)

	# Armory Rack beside the Foundry
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(60.5, 0.0, -58.0), Vector3.ONE * 1.8, 45.0)

	# Dwarven Runeforge Ancient Shrine & Miner's Campfire
	var forge_shrine = AncientShrine3DScript.new()
	forge_shrine.shrine_type = AncientShrine3DScript.ShrineType.FORGE
	forge_shrine.shrine_name = "Sacred Runeforge Waystone (Khar-Drakken)"
	forge_shrine.position = Vector3(72.0, 0.0, -64.0)
	parent.add_child(forge_shrine)

	var crags_campfire = CampfireRestSite3DScript.new()
	crags_campfire.site_name = "Stonegate Smelter Campfire"
	crags_campfire.position = Vector3(60.0, 0.0, -48.0)
	parent.add_child(crags_campfire)

	# Mining Scaffolding & Rock Rubble
	_place_prop(parent, "res://assets/overworld/building_scaffolding.gltf", Vector3(74.0, 0.0, -56.0), Vector3.ONE * 1.8, -90.0)
	_place_prop(parent, "res://assets/overworld/ingot_stacked.gltf", Vector3(62.0, 0.0, -58.5), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(68.0, 0.0, -66.0), Vector3.ONE * 2.5)

	# 3. The Orc Stronghold & Bastion (Upper Plateau: X in [92, 110], Z in [-88, -108])
	var OverworldGateScript = preload("res://src/world/OverworldGate.gd")
	var orc_gate = OverworldGateScript.new()
	orc_gate.position = Vector3(94.0, 0.0, -88.0)
	orc_gate.rotation_degrees.y = 45.0
	parent.add_child(orc_gate)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(88.0, 0.0, -84.0), Vector3(3.2, 4.0, 2.5), 45.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(100.0, 0.0, -92.0), Vector3(3.2, 4.0, 2.5), 45.0)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(91.5, 0.0, -85.5), Vector3.ONE * 2.0)

	# 4. NPCs & Restoration Station
	var torv = TownNPCScript.new()
	torv.npc_id = "runesmith_torvald"
	torv.npc_name = "Torvald Ironbreaker"
	torv.npc_title = "Highland Runesmith"
	torv.icon = "⛏️"
	torv.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torv.model_scale = Vector3(0.40, 0.40, 0.40)
	torv.model_rotation_y = 20.0
	torv.dialogue_text = "By the thunder of stone! The Orc Warlords have seized our upper stronghold and stolen the Runebound Mountain Core! Cleave through their ranks, return the Core, and I shall temper your weapons with ancient dwarven runes!"
	torv.position = Vector3(66.0, 0.0, -55.5)
	parent.add_child(torv)

	# Dwarven Smelter Durin (Tending the blast furnace and smelter bellows)
	var durin = TownNPCScript.new()
	durin.npc_id = "smelter_durin"
	durin.npc_name = "Master Durin"
	durin.npc_title = "Deep Mine Smelter"
	durin.icon = "🔥"
	durin.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	durin.model_scale = Vector3(0.38, 0.38, 0.38)
	durin.model_rotation_y = 90.0
	durin.dialogue_text = "Raw mountain ore makes the strongest steel in the realm! Stoke the coals and keep the slag channels clear. The King's army relies on our iron!"
	durin.position = Vector3(74.5, 0.0, -56.5)
	parent.add_child(durin)

	# Interactive World Restoration Station: Smelter Blast Bellows
	var bellows_station = WorldRepairStationScript.new()
	bellows_station.repair_id = "smelter_bellows"
	bellows_station.station_name = "Smelter Blast Bellows"
	bellows_station.required_materials = {"gold_vein": 1, "iron_ore": 1}
	bellows_station.target_story_act = 4
	bellows_station.gold_reward = 180
	bellows_station.echo_reward = 60
	bellows_station.position = Vector3(71.5, 0.0, -58.0)
	var ruined_bellows = _place_prop(parent, "res://assets/overworld/building_scaffolding.gltf", Vector3(71.5, 0.0, -58.0), Vector3.ONE * 1.5, -30.0)
	var restored_bellows = _place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(71.5, 0.0, -58.0), Vector3.ONE * 2.4, -30.0)
	var f_light = OmniLight3D.new()
	f_light.light_color = Color(1.0, 0.5, 0.15)
	f_light.light_energy = 2.5
	f_light.omni_range = 9.0
	f_light.position.y = 1.6
	restored_bellows.add_child(f_light)
	AmbientFX.create_chimney_smoke(restored_bellows, Vector3(0.0, 3.2, 0.0))
	bellows_station.ruined_node = ruined_bellows
	bellows_station.restored_node = restored_bellows
	parent.add_child(bellows_station)

	# 5. Enemies & Quest Relics
	_spawn_enemy(parent, EnemyAI.EnemyType.ORC, Vector3(98.0, 0.0, -95.0), -45.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.ORC, Vector3(104.0, 0.0, -103.0), 120.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.DEMON, Vector3(90.0, 0.0, -96.0), 30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.DEMON, Vector3(104.0, 0.0, -88.0), -110.0)

	_spawn_material_node(parent, "runebound_core", "Runebound Mountain Core", "⛰️", "res://assets/items/quest_materials/Crystal1.glb", Vector3(105.0, 0.0, -106.0), Color(1.0, 0.55, 0.15), 100, 75, Vector3(2.2, 2.2, 2.2))
	_spawn_material_node(parent, "gold_vein", "High Crag Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(76.0, 0.0, -66.0), Color(1.0, 0.85, 0.2), 40, 35, Vector3(1.5, 1.5, 1.5))
	_spawn_material_node(parent, "emerald_crystal", "Mountain Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(84.0, 0.0, -72.0), Color(0.2, 1.0, 0.4), 35, 30, Vector3(1.8, 1.8, 1.8))

# =========================================================================
# CROSSROADS, HIGHROADS & WAYSTONE NETWORK
# =========================================================================
func _build_crossroads_and_highroads(parent: Node3D) -> void:
	# 1. Central Crossroads Waystone Signpost (At West Town Street & Bridge Junction: X = -12.0, Z = 12.0)
	var sign_cross = TownNPCScript.new()
	sign_cross.npc_id = "signpost_crossroads"
	sign_cross.npc_name = "Kingdom Crossroads Waystone"
	sign_cross.npc_title = "Fast Travel & Directions"
	sign_cross.icon = "🪧"
	sign_cross.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_cross.model_scale = Vector3.ONE * 1.2
	sign_cross.dialogue_text = "Kingdom Crossroad Waystone:\n• South-West: Port Blackwater (Harbor, Ships & Ocean)\n• North-West: Whisperwood Forest (Druidic Enclave)\n• North-East: Khar-Drakken Crags (Dwarven Mines & Orcs)\n• Central: Oakhaven Town (Castle & Catacombs)"
	sign_cross.position = Vector3(-12.0, 0.0, 12.0)
	parent.add_child(sign_cross)

	# 2. Port Blackwater Waystone Signpost (North entrance of Harbor Promenade)
	var sign_port = TownNPCScript.new()
	sign_port.npc_id = "signpost_port"
	sign_port.npc_name = "Port Blackwater Waystone"
	sign_port.npc_title = "Fast Travel & Directions"
	sign_port.icon = "⚓"
	sign_port.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_port.model_scale = Vector3.ONE * 1.2
	sign_port.dialogue_text = "Port Blackwater Harbor Waystone.\nFast Travel to other unlocked settlements in the realm."
	sign_port.position = Vector3(-48.5, 0.04, 53.0)
	parent.add_child(sign_port)

	# 3. Whisperwood Waystone Signpost
	var sign_wood = TownNPCScript.new()
	sign_wood.npc_id = "signpost_forest"
	sign_wood.npc_name = "Whisperwood Waystone"
	sign_wood.npc_title = "Fast Travel & Directions"
	sign_wood.icon = "🌲"
	sign_wood.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_wood.model_scale = Vector3.ONE * 1.2
	sign_wood.dialogue_text = "Whisperwood Forest Waystone (Sylva's Rest).\nFast Travel to other unlocked settlements in the realm."
	sign_wood.position = Vector3(-66.0, 0.0, -52.0)
	parent.add_child(sign_wood)

	# 4. Khar-Drakken Waystone Signpost
	var sign_crag = TownNPCScript.new()
	sign_crag.npc_id = "signpost_crags"
	sign_crag.npc_name = "Khar-Drakken Waystone"
	sign_crag.npc_title = "Fast Travel & Directions"
	sign_crag.icon = "⛰️"
	sign_crag.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_crag.model_scale = Vector3.ONE * 1.2
	sign_crag.dialogue_text = "Khar-Drakken Mountain Waystone (Stonegate Outpost).\nFast Travel to other unlocked settlements in the realm."
	sign_crag.position = Vector3(60.0, 0.0, -48.0)
	parent.add_child(sign_crag)

	# 5. Cobblestone Regional Highroads (Spaced 4.5m apart so stones form a natural trail without overlapping)
	var p_models = [
		"res://assets/overworld/path_A.gltf",
		"res://assets/overworld/path_B.gltf",
		"res://assets/overworld/path_C.gltf"
	]
	# South-West Coastal Highroad (From South end of Western Wooden Bridge at (-18, 29) to Port Blackwater (-50, 52))
	for step in range(0, 9):
		var alpha = float(step) / 8.0
		var rx = lerp(-18.0, -50.0, alpha)
		var rz = lerp(29.5, 52.0, alpha)
		_place_prop(parent, p_models[step % 3], Vector3(rx, 0.02, rz), Vector3(1.15, 1.0, 1.15), -52.0)

	# North-West Woodland Trail (From West Town / Ruins (-34, -10) through Greenhollow (-48, -21) to Whisperwood (-66, -50))
	for step in range(0, 11):
		var alpha = float(step) / 10.0
		var rx = lerp(-34.0, -66.0, alpha)
		var rz = lerp(-10.0, -50.0, alpha)
		_place_prop(parent, p_models[step % 3], Vector3(rx, 0.02, rz), Vector3(1.15, 1.0, 1.15), 38.0)

	# North-East Mountain Pass (From Foothill Mine (26, -16) to Khar-Drakken Waystone (60, -48))
	for step in range(0, 10):
		var alpha = float(step) / 9.0
		var rx = lerp(26.0, 60.0, alpha)
		var rz = lerp(-16.0, -48.0, alpha)
		_place_prop(parent, p_models[step % 3], Vector3(rx, 0.02, rz), Vector3(1.15, 1.0, 1.15), -45.0)

	# South-East Swamp Causeway (From Sunnydale Windmill Knoll (48, 46) to Weeping Fen Boardwalk (56, 74))
	for step in range(0, 7):
		var alpha = float(step) / 6.0
		var rx = lerp(48.0, 56.0, alpha)
		var rz = lerp(46.0, 74.0, alpha)
		_place_prop(parent, p_models[step % 3], Vector3(rx, 0.02, rz), Vector3(1.15, 1.0, 1.15), 18.0)

# =========================================================================
# REGION 4: THE WEEPING FEN SWAMP & MURKY WETLANDS (X in [50, 120], Z in [58, 120])
# =========================================================================
func _build_weeping_fen_swamp_region(parent: Node3D) -> void:
	# 1. Murky Olive-Brown Wetland Water Basin (Y = 0.03m shallow bog water)
	var swamp_basin = MeshInstance3D.new()
	swamp_basin.name = "SwampWaterSurface"
	var sw_mesh = PlaneMesh.new()
	sw_mesh.size = Vector2(68.0, 62.0)
	swamp_basin.mesh = sw_mesh
	var sw_mat = StandardMaterial3D.new()
	sw_mat.albedo_color = Color(0.14, 0.22, 0.11, 0.90) # Fetid peat-green bog water
	sw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sw_mat.roughness = 0.18
	sw_mat.metallic = 0.25
	swamp_basin.material_override = sw_mat
	swamp_basin.position = Vector3(84.0, 0.03, 88.0)
	parent.add_child(swamp_basin)

	# 2. Flat Raised Rotting Wooden Boardwalks spanning the Bog (Replaces sideways arched bridges!)
	_build_swamp_boardwalk(parent, Vector3(54.0, 0.12, 76.0), Vector3(84.0, 0.12, 76.0), 2.8)
	_build_swamp_boardwalk(parent, Vector3(84.0, 0.12, 76.0), Vector3(84.0, 0.12, 102.0), 2.8)

	# 3. Dead Twisted Swamp Trees, Cattail Reeds & Water Lilies (Well-spaced around the bog)
	var dead_trees = [
		Vector3(58.0, 0.0, 62.0), Vector3(70.0, 0.0, 62.0), Vector3(82.0, 0.0, 64.0),
		Vector3(96.0, 0.0, 64.0), Vector3(108.0, 0.0, 70.0), Vector3(60.0, 0.0, 86.0),
		Vector3(72.0, 0.0, 92.0), Vector3(98.0, 0.0, 84.0), Vector3(110.0, 0.0, 92.0),
		Vector3(64.0, 0.0, 104.0), Vector3(76.0, 0.0, 110.0), Vector3(102.0, 0.0, 106.0)
	]
	for i in range(dead_trees.size()):
		var dt_pos = dead_trees[i]
		var dt_model = "res://assets/overworld/tree_dead_large_decorated.gltf" if (i % 2 == 0) else "res://assets/overworld/tree_dead_large.gltf"
		_place_prop(parent, dt_model, dt_pos, Vector3.ONE * 2.4, float((i * 67) % 360))
		_add_static_cyl(parent, dt_pos, 0.9, 7.0)

	# Lily pads, cattail reeds & sunken skeletal ribcages (Spaced cleanly)
	for r_pos in [Vector3(65.0, 0.04, 70.0), Vector3(75.0, 0.04, 81.0), Vector3(90.0, 0.04, 80.0), Vector3(94.0, 0.04, 94.0), Vector3(77.0, 0.04, 98.0)]:
		_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", r_pos, Vector3.ONE * 1.8)
		_place_prop(parent, "res://assets/overworld/waterplant_C.gltf", r_pos + Vector3(3.2, 0.0, 2.0), Vector3.ONE * 2.0)
	_place_prop(parent, "res://assets/overworld/ribcage.gltf", Vector3(68.0, 0.0, 84.0), Vector3.ONE * 2.0, 35.0)
	_place_prop(parent, "res://assets/overworld/coffin_decorated.gltf", Vector3(94.0, 0.0, 101.0), Vector3.ONE * 1.8, -25.0)

	# Ominous Swamp Skull Warning Totems & Flickering Candles along the Boardwalk
	_place_prop(parent, "res://assets/overworld/post_skull.gltf", Vector3(56.0, 0.0, 74.0), Vector3.ONE * 1.6, 25.0)
	_place_prop(parent, "res://assets/overworld/post_skull.gltf", Vector3(82.0, 0.0, 74.0), Vector3.ONE * 1.6, -20.0)
	_place_prop(parent, "res://assets/overworld/post_skull.gltf", Vector3(86.5, 0.0, 96.0), Vector3.ONE * 1.6, 110.0)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(85.5, 0.12, 82.0), Vector3.ONE * 1.5, 45.0)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(82.5, 0.12, 94.0), Vector3.ONE * 1.5, -60.0)

	# Eerie Swamp Mist & Will-o'-the-Wisp Spores
	AmbientFX.create_forest_fireflies(parent, Vector3(76.0, 1.5, 80.0), 16.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(88.0, 1.5, 96.0), 16.0)

	# 4. Bog Witch Morrigan's Stilted Hut & Alchemical Shrine (At the southern end of the boardwalk: X = 88.0, Z = 106.0)
	_place_prop(parent, "res://assets/overworld/building_home_A_green.gltf", Vector3(88.0, 0.2, 106.0), Vector3.ONE * 6.2, 180.0)
	_add_static_box(parent, Vector3(88.0, 3.5, 106.0), Vector3(6.0, 6.5, 6.0))
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(80.0, 0.1, 104.0), Vector3.ONE * 2.4, 45.0)

	var morrigan = TownNPCScript.new()
	morrigan.npc_id = "bog_witch"
	morrigan.npc_name = "Seeress Morrigan"
	morrigan.npc_title = "Keeper of the Weeping Fen"
	morrigan.icon = "🐸"
	morrigan.model_path = "res://assets/characters/adventurers/Mage.glb"
	morrigan.model_scale = Vector3(0.54, 0.54, 0.54)
	morrigan.model_rotation_y = 180.0
	morrigan.dialogue_text = "Step not off the rotting planks, wanderer... The Weeping Fen swallows the careless whole. Bog Creeps and hollow dead guard the Sunken Fen Seal in the mire. Reclaim it and channel the ancient echoes!"
	morrigan.position = Vector3(84.0, 0.2, 100.5)
	parent.add_child(morrigan)

	# Swamp Alchemist Agnes (Gathering weeping willow moss and brewing bog draughts)
	var agnes = TownNPCScript.new()
	agnes.npc_id = "alchemist_agnes"
	agnes.npc_name = "Agnes"
	agnes.npc_title = "Bog Alchemist"
	agnes.icon = "🧪"
	agnes.model_path = "res://assets/characters/adventurers/Mage.glb"
	agnes.model_scale = Vector3(0.52, 0.52, 0.52)
	agnes.model_rotation_y = 90.0
	agnes.dialogue_text = "Grave-moss, willow-bark, and weeping lotus... the fen yields potent reagents for those brave enough to harvest them. Stay upon the boardwalk timbers, wanderer!"
	agnes.position = Vector3(82.0, 0.2, 88.0)
	parent.add_child(agnes)

	# 5. Swamp Monsters & Sunken Fen Relic
	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(72.0, 0.0, 70.0), 45.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(95.0, 0.0, 88.0), -90.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.MINION, Vector3(78.0, 0.0, 94.0), 15.0)
	_spawn_material_node(parent, "fen_seal_relic", "Ancient Seal of the Weeping Fen", "🐸", "res://assets/items/quest_materials/Crystal3.glb", Vector3(92.0, 0.1, 95.0), Color(0.35, 0.95, 0.45), 90, 65, Vector3(2.2, 2.2, 2.2))

func _build_swamp_boardwalk(parent: Node3D, start_pos: Vector3, end_pos: Vector3, width: float) -> void:
	var bw_root = Node3D.new()
	bw_root.name = "SwampBoardwalk"
	parent.add_child(bw_root)

	var plank_mat = StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.28, 0.22, 0.15)
	plank_mat.roughness = 0.94

	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.20, 0.15, 0.10)
	post_mat.roughness = 0.95

	var diff = end_pos - start_pos
	var total_len = Vector2(diff.x, diff.z).length()
	var is_x_axis = abs(diff.x) >= abs(diff.z)
	var steps = int(total_len / 0.70)

	for i in range(steps + 1):
		var t = float(i) / float(max(1, steps))
		var p = start_pos.lerp(end_pos, t)
		var plank = MeshInstance3D.new()
		var pm = BoxMesh.new()
		pm.size = Vector3(0.58, 0.07, width) if is_x_axis else Vector3(width, 0.07, 0.58)
		plank.mesh = pm
		plank.material_override = plank_mat
		plank.position = p
		bw_root.add_child(plank)

		if i % 5 == 0:
			for side in [-1.0, 1.0]:
				var post = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.12
				cyl.bottom_radius = 0.14
				cyl.height = 0.65
				post.mesh = cyl
				post.material_override = post_mat
				post.position = p + (Vector3(0.0, -0.10, side * width * 0.46) if is_x_axis else Vector3(side * width * 0.46, -0.10, 0.0))
				bw_root.add_child(post)

# =========================================================================
# REGION 5: CRIMSON SIEGE ENCAMPMENT, TREBUCHETS & MARCHING ARMIES (Z in [58, 105])
# =========================================================================
func _build_siege_encampment_and_battlefield(parent: Node3D) -> void:
	# 1. Counterweight Trebuchet Battery (Articulated & Actively Hurling Boulders South Out of the Village)
	var treb_west = SiegeTrebuchet3DScript.new()
	treb_west.trebuchet_name = "Goliath Counterweight Trebuchet"
	treb_west.position = Vector3(-14.0, 0.0, 74.0)
	treb_west.rotation_degrees.y = 180.0
	parent.add_child(treb_west)

	var treb_east = SiegeTrebuchet3DScript.new()
	treb_east.trebuchet_name = "Dreadhammer Siege Trebuchet"
	treb_east.position = Vector3(14.0, 0.0, 74.0)
	treb_east.rotation_degrees.y = 180.0
	parent.add_child(treb_east)

	# 2. Siege Towers, Crimson Command Pavilions, Stake Barricades & Ammunition Wagons
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_red.gltf", Vector3(-25.0, 0.0, 78.0), Vector3.ONE * 8.0, 180.0)
	_add_static_box(parent, Vector3(-25.0, 6.0, 78.0), Vector3(4.5, 12.0, 4.5))
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_red.gltf", Vector3(25.0, 0.0, 78.0), Vector3.ONE * 8.0, 180.0)
	_add_static_box(parent, Vector3(25.0, 6.0, 78.0), Vector3(4.5, 12.0, 4.5))

	_place_prop(parent, "res://assets/overworld/building_barracks_red.gltf", Vector3(-16.0, 0.0, 88.0), Vector3.ONE * 4.8, 180.0)
	_add_static_box(parent, Vector3(-16.0, 4.0, 88.0), Vector3(7.0, 7.0, 7.5))
	_place_prop(parent, "res://assets/overworld/building_market_red.gltf", Vector3(-5.5, 0.0, 88.0), Vector3.ONE * 3.8, 180.0)
	_place_prop(parent, "res://assets/overworld/building_market_red.gltf", Vector3(5.5, 0.0, 88.0), Vector3.ONE * 3.8, 180.0)
	_place_prop(parent, "res://assets/overworld/building_barracks_red.gltf", Vector3(16.0, 0.0, 88.0), Vector3.ONE * 4.8, 180.0)
	_add_static_box(parent, Vector3(16.0, 4.0, 88.0), Vector3(7.0, 7.0, 7.5))

	# Dirt earthwork grounds beneath battery positions
	for ep in [Vector3(-14.0, 0.01, 74.0), Vector3(14.0, 0.01, 74.0), Vector3(0.0, 0.01, 74.0), Vector3(0.0, 0.01, 84.0)]:
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", ep, Vector3(3.4, 1.0, 3.4))

	# Crimson Vanguard Military Pavilions & Command Tents
	_place_prop(parent, "res://assets/overworld/tent.gltf", Vector3(-8.2, 0.0, 77.0), Vector3.ONE * 2.2, 35.0)
	_place_prop(parent, "res://assets/overworld/tent.gltf", Vector3(8.2, 0.0, 77.0), Vector3.ONE * 2.2, -35.0)

	# Supply Munition Wagons and Ammunition Stacks
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(-8.5, 0.0, 81.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-8.5, 0.0, 81.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-7.2, 0.0, 82.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(8.5, 0.0, 80.5), Vector3.ONE * 1.4, -45.0)

	# Defensive Wooden Barricade Line (X from -16 to +16 at Z = 65, Destructible props!)
	for bar_x in [-16.0, -10.5, -5.0, 5.0, 10.5, 16.0]:
		_place_destructible_prop(parent, DestructibleProp3DScript.PropType.WOODEN_FENCE, "res://assets/overworld/fence_wood_straight.gltf", Vector3(bar_x, 0.0, 65.0), Vector3.ONE * 2.0, 90.0, "arrows")
	_place_destructible_prop(parent, DestructibleProp3DScript.PropType.CARGO_CRATE, "res://assets/overworld/crate_A_big.gltf", Vector3(-6.0, 0.0, 79.0), Vector3.ONE * 1.5, 0.0, "arrows")
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-10.5, 0.0, 71.0), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(10.5, 0.0, 71.0), Vector3.ONE * 1.8, -90.0)

	# Crimson War Banners
	for fx in [-19.0, -6.5, 6.5, 19.0]:
		_place_prop(parent, "res://assets/overworld/flag_red.gltf", Vector3(fx, 0.0, 65.5), Vector3.ONE * 2.2)

	# Encampment Soldier Hearth & Rest Site
	var siege_campfire = CampfireRestSite3DScript.new()
	siege_campfire.hearth_name = "Siege Vanguard Campfire"
	siege_campfire.position = Vector3(0.0, 0.0, 84.0)
	parent.add_child(siege_campfire)

	# Siege Archery Training Target for Vanguard Archers
	var siege_target = InteractiveTarget3DScript.new()
	siege_target.target_name = "Siege Battery Practice Target"
	siege_target.position = Vector3(10.5, 0.0, 82.0)
	siege_target.rotation_degrees.y = -45.0
	parent.add_child(siege_target)

	# Staging Pallets & Ammunition Reserves outside Trebuchet battery
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(-19.5, 0.0, 76.8), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(19.5, 0.0, 76.8), Vector3.ONE * 1.4)

	# NPC: Siege Master Vargos
	var vargos = TownNPCScript.new()
	vargos.npc_id = "siege_captain"
	vargos.npc_name = "Siege Marshal Vargos"
	vargos.npc_title = "Royal Artillery Commander"
	vargos.icon = "☄️"
	vargos.model_path = "res://assets/characters/adventurers/Knight.glb"
	vargos.model_scale = Vector3(0.58, 0.58, 0.58)
	vargos.model_rotation_y = 0.0
	vargos.dialogue_text = "Behold our counterweight trebuchets! We captured this siege battery from the Crimson Warlords and turned their own artillery against their southern vanguard. Interact with either trebuchet to loose a flaming boulder volley!"
	vargos.position = Vector3(0.0, 0.0, 70.0)
	parent.add_child(vargos)

	# 3. Marching Army Formations (Marching across the open battlefield south of the Castle Keep)
	var royal_army = ArmyFormation3DScript.new()
	royal_army.regiment_name = "King's 1st Heavy Vanguard"
	royal_army.faction_color = "blue"
	royal_army.position = Vector3(0.0, 0.0, 58.0)
	royal_army.waypoints = [
		Vector3(-10.0, 0.0, 58.0),
		Vector3(10.0, 0.0, 58.0),
		Vector3(10.0, 0.0, 62.0),
		Vector3(-10.0, 0.0, 62.0)
	]
	parent.add_child(royal_army)

	var crimson_army = ArmyFormation3DScript.new()
	crimson_army.regiment_name = "Redcrest Iron Company"
	crimson_army.faction_color = "red"
	crimson_army.position = Vector3(-28.0, 0.0, 56.0)
	crimson_army.waypoints = [
		Vector3(-26.0, 0.0, 54.0),
		Vector3(-38.0, 0.0, 60.0),
		Vector3(-26.0, 0.0, 66.0)
	]
	parent.add_child(crimson_army)

# =========================================================================
# REGION 6: GREENHOLLOW WOODLAND VILLAGE & MOVING CARAVAN WAGONS
# =========================================================================
func _build_greenhollow_village_and_caravans(parent: Node3D) -> void:
	# 1. Greenhollow Woodland Village (Organized around a Village Green at X = -50.0, Z = -20.0)
	# Greenhollow Chapel on the North side facing South (0°) onto the Village Green
	_place_prop(parent, "res://assets/overworld/building_church_green.gltf", Vector3(-50.0, 0.0, -28.5), Vector3.ONE * 5.5, 0.0)
	_add_static_box(parent, Vector3(-50.0, 4.5, -28.5), Vector3(7.0, 8.5, 8.0))

	# West Greenhollow Cottage facing East (90°) onto the Village Green
	_place_prop(parent, "res://assets/overworld/building_home_B_green.gltf", Vector3(-59.0, 0.0, -20.0), Vector3.ONE * 6.0, 90.0)
	_add_static_box(parent, Vector3(-59.0, 3.5, -20.0), Vector3(6.0, 6.5, 6.0))

	# East Greenhollow Cottage facing West (-90°) onto the Village Green
	_place_prop(parent, "res://assets/overworld/building_home_A_green.gltf", Vector3(-41.0, 0.0, -20.0), Vector3.ONE * 6.0, -90.0)
	_add_static_box(parent, Vector3(-41.0, 3.5, -20.0), Vector3(6.0, 6.5, 6.0))

	# Village Stone Well in the center of the Green & Logging Stack to the North-East
	_place_prop(parent, "res://assets/overworld/building_well_green.gltf", Vector3(-50.0, 0.0, -19.5), Vector3.ONE * 2.4)
	_place_prop(parent, "res://assets/overworld/trees_A_cut.gltf", Vector3(-40.0, 0.0, -28.0), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/resource_lumber.gltf", Vector3(-36.0, 0.0, -28.0), Vector3.ONE * 2.0)

	var woodcutter = TownNPCScript.new()
	woodcutter.npc_id = "woodcutter_hal"
	woodcutter.npc_name = "Forester Hal"
	woodcutter.npc_title = "Greenhollow Elder"
	woodcutter.icon = "🪓"
	woodcutter.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	woodcutter.model_scale = Vector3(0.55, 0.55, 0.55)
	woodcutter.model_rotation_y = 180.0
	woodcutter.dialogue_text = "Welcome to Greenhollow Village! Our timberwrights fell the stoutest oaks for Port Blackwater's ships and the King's siege engines."
	woodcutter.position = Vector3(-47.0, 0.0, -22.0)
	parent.add_child(woodcutter)

	# Greenhollow Village Hearth Rest Site
	var greenhollow_hearth = CampfireRestSite3DScript.new()
	greenhollow_hearth.hearth_name = "Greenhollow Village Hearth"
	greenhollow_hearth.position = Vector3(-53.0, 0.0, -22.5)
	parent.add_child(greenhollow_hearth)

	# Greenhollow Village Archery Range Target
	var greenhollow_target = InteractiveTarget3DScript.new()
	greenhollow_target.target_name = "Greenhollow Forester Target"
	greenhollow_target.position = Vector3(-44.0, 0.0, -17.0)
	greenhollow_target.rotation_degrees.y = -60.0
	parent.add_child(greenhollow_target)

	# 2. Moving Horse-Drawn Trade Caravan Wagons on the Dry Realm Highways
	var caravan_east = CaravanWagon3DScript.new()
	caravan_east.caravan_name = "Sunnydale Grain Caravan"
	caravan_east.position = Vector3(8.0, 0.0, 14.5)
	caravan_east.waypoints = [
		Vector3(5.0, 0.0, 14.5),
		Vector3(24.0, 0.0, 14.5)
	]
	parent.add_child(caravan_east)

	var caravan_west = CaravanWagon3DScript.new()
	caravan_west.caravan_name = "Blackwater Spice Caravan"
	caravan_west.position = Vector3(-35.0, 0.0, 38.0)
	caravan_west.waypoints = [
		Vector3(-28.0, 0.0, 36.0),
		Vector3(-55.0, 0.0, 48.0)
	]
	parent.add_child(caravan_west)

	# 3. Roaming Wildlife in Greenhollow & Weeping Fen Outskirts
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-42.0, 0.0, -12.0), 45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-54.0, 0.0, -12.0), -30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(-56.0, 0.0, -27.0), 80.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(64.0, 0.0, 62.0), 120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(68.0, 0.0, 82.0), -45.0)
