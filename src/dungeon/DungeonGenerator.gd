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
	
	# 1. Slotted Floor Static Collision & Safety Void Safeguard (River & Canal cutouts)
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
	# South Bank Floor (X: -137 to 137, Z: 28.0 to 137.0)
	add_f_col.call(Vector3(274.0, 1.2, 109.0), Vector3(0.0, -0.6, 82.5))
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

	parent.add_child(floor_body)
	
	# Visual Overworld Slotted Grass Landscape (Reveals the sunken River channel Z in [20.0, 28.0])
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.24, 0.44, 0.18) # Lush stylized medieval grass
	g_mat.roughness = 0.88

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
	add_grass_plane.call("SouthBank_Grass", Vector2(274.0, 109.0), Vector3(0.0, 0.0, 82.5))
	
	# Outer world perimeter boundary collision barriers (North, South, East, West at +-130m)
	var wall_h = 18.0
	var thick = 4.0
	_add_static_box(parent, Vector3(0, wall_h * 0.5, -half_s - thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(0, wall_h * 0.5, half_s + thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(half_s + thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))
	_add_static_box(parent, Vector3(-half_s - thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))

	# Encircling Natural Perimeter Mountain Ridges & Trees (prevents open voids)
	for perim_idx in range(-12, 13):
		var offset_p = float(perim_idx) * 11.0
		# North Ridge
		_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(offset_p, 0.0, -half_s), Vector3.ONE * 9.0)
		# South Ridge
		if abs(offset_p) > 20.0:
			_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(offset_p, 0.0, half_s), Vector3.ONE * 9.0)
		# East Ridge (mountain crags)
		_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(half_s, 0.0, offset_p), Vector3.ONE * 9.0)
		# West Ridge (forest & coast)
		if offset_p < 30.0:
			_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(-half_s, 0.0, offset_p), Vector3.ONE * 9.0)

	# 2. Central Cobblestone Plaza (Courtyard floor for hero pedestals)
	for px in range(-5, 6):
		for pz in range(-4, 6):
			var stone = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
			stone.scale = Vector3(0.5, 1.0, 0.5)
			stone.position = Vector3(px * 2.0, 0.02, pz * 2.0)
			parent.add_child(stone)

	# 3. North: The Ancient Crypt (Grand stone mausoleum entrance to catacombs)
	var crypt = AssetLoader.load_or_generate_model("res://assets/overworld/crypt.gltf", "dungeon", "crypt")
	crypt.scale = Vector3(2.8, 2.8, 2.8)
	crypt.position = Vector3(0, 0, -14.0)
	parent.add_child(crypt)
	_add_static_box(parent, Vector3(0, 3.2, -14.5), Vector3(8.5, 6.5, 7.5))
	
	# Dead cemetery trees and gravestones
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(-6.5, 0, -12.5), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(6.5, 0, -12.5), Vector3.ONE * 2.2, 75.0)
	_place_prop(parent, "res://assets/overworld/grave_A.gltf", Vector3(-4.5, 0, -10.5), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/gravestone.gltf", Vector3(4.5, 0, -10.5), Vector3.ONE * 1.8, -25.0)
	_place_prop(parent, "res://assets/overworld/grave_A_destroyed.gltf", Vector3(-6.2, 0, -9.8), Vector3.ONE * 1.6)

	# 4. West: The Blacksmith's Forge (Proportionate 7.1m tall shop)
	var smith = AssetLoader.load_or_generate_model("res://assets/overworld/building_blacksmith_blue.gltf", "dungeon", "blacksmith")
	smith.scale = Vector3.ONE * 7.2
	smith.position = Vector3(-15.0, 0, 0.0)
	smith.rotation_degrees.y = 90.0
	parent.add_child(smith)
	_add_static_box(parent, Vector3(-15.0, 3.5, 0.0), Vector3(9.2, 7.0, 9.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-15.0, 7.2, -1.2))

	# Circling Crows Flock above North Crypt
	var flock_crypt = CirclingFlock.new()
	flock_crypt.position = Vector3(0.0, 16.0, -14.0)
	flock_crypt.bird_count = 6
	flock_crypt.circle_radius = 9.0
	parent.add_child(flock_crypt)

	# Master Torval - Town Blacksmith NPC (Stout Dwarf proportions ~1.44m tall)
	var torval = TownNPCScript.new()
	torval.npc_id = "blacksmith"
	torval.npc_name = "Master Torval"
	torval.npc_title = "Forge Master"
	torval.icon = "⚒️"
	torval.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torval.model_scale = Vector3(0.38, 0.38, 0.38)
	torval.model_rotation_y = 90.0
	torval.dialogue_text = "Hail, warrior! The forge fires blaze with eternal embers. Deliver unto me the Soul Echoes reaped from the Ossuary depths, and I shall temper your weapons, bolster your armor, and sharpen your dash reflexes!"
	torval.position = Vector3(-9.5, 0, 0.0)
	parent.add_child(torval)

	# Blacksmith forge props
	_place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(-11.5, 0, -2.8), Vector3.ONE * 2.0, 90.0)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-9.5, 0, -2.5), Vector3.ONE * 1.5, 0.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-8.5, 0, -2.5), Vector3.ONE * 1.5)

	# 5. East: The Ruined Cathedral (Towering 15.7m cathedral)
	var church = AssetLoader.load_or_generate_model("res://assets/overworld/building_church_blue.gltf", "dungeon", "church")
	church.scale = Vector3.ONE * 9.5
	church.position = Vector3(16.0, 0, 0.0)
	church.rotation_degrees.y = -90.0
	parent.add_child(church)
	_add_static_box(parent, Vector3(16.0, 6.0, 0.0), Vector3(9.8, 12.0, 11.0))
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(8.5, 0, 3.0), Vector3.ONE * 2.0, -45.0)

	# Eldress Alyssa - High Priestess NPC (Proportionate ~1.78m human height)
	var alyssa = TownNPCScript.new()
	alyssa.npc_id = "priestess"
	alyssa.npc_name = "Eldress Alyssa"
	alyssa.npc_title = "Sanctuary Priestess"
	alyssa.icon = "✨"
	alyssa.model_path = "res://assets/characters/adventurers/Mage.glb"
	alyssa.model_scale = Vector3(0.53, 0.53, 0.53)
	alyssa.model_rotation_y = -90.0
	alyssa.dialogue_text = "May the Sacred Light guide your steps, champion. The dead stir restlessly in the Catacombs below. Inquire upon our Sanctuary Bounties—purge the wicked hordes to claim divine favour and rich reward!"
	alyssa.position = Vector3(9.5, 0, 0.0)
	parent.add_child(alyssa)

	# Cathedral props
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(8.5, 0, -3.0), Vector3.ONE * 2.0, -45.0)
	_place_prop(parent, "res://assets/furniture/cabinet_small_decorated.gltf", Vector3(11.5, 0, -3.2), Vector3.ONE * 1.8, -90.0)

	# 6. South: Fortified Arch Gateway (Interactive Animated Portcullis Doors with Physics)
	var OverworldGateScript = preload("res://src/world/OverworldGate.gd")
	var gate = OverworldGateScript.new()
	gate.name = "SanctuaryArchGate"
	gate.position = Vector3(0, 0, 14.0)
	parent.add_child(gate)

	# Captain Vane - Gate Sentinel NPC (Guarding beside the gateway pillar)
	var vane = TownNPCScript.new()
	vane.npc_id = "guard"
	vane.npc_name = "Captain Vane"
	vane.npc_title = "Gate Sentinel"
	vane.icon = "🛡️"
	vane.model_path = "res://assets/characters/adventurers/Knight.glb"
	vane.model_scale = Vector3(0.55, 0.55, 0.55)
	vane.model_rotation_y = 160.0
	vane.dialogue_text = "Halt, warrior! You stand before the threshold of the Ossuary Catacombs. Beneath the north crypt lies the descent sigil. Step upon the glowing seal to plunge into the underworld. Beware the Bone Titan's wrath on the final floor!"
	vane.position = Vector3(-2.4, 0.0, 12.2)
	parent.add_child(vane)

	# Fortified Town Defensive Curtain Walls (Flanking the South Arch Gateway with zero gaps)
	# Left Curtain Wall: connects Gate Left Pillar (X = -2.4) continuously to West Corner Bastion (X = -14.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-5.2, 0.0, 14.0), Vector3(3.5, 4.0, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-9.5, 0.0, 14.0), Vector3(3.5, 4.0, 2.5))
	_place_prop(parent, "res://assets/overworld/fence_stone_straight.gltf", Vector3(-13.0, 0.0, 14.0), Vector3.ONE * 2.2, 90.0)
	_add_static_box(parent, Vector3(-8.2, 3.0, 14.0), Vector3(11.6, 6.0, 2.5))

	# Right Curtain Wall: connects Gate Right Pillar (X = +2.4) continuously to East Corner Bastion (X = +14.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(5.2, 0.0, 14.0), Vector3(3.5, 4.0, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(9.5, 0.0, 14.0), Vector3(3.5, 4.0, 2.5))
	_place_prop(parent, "res://assets/overworld/fence_stone_straight.gltf", Vector3(13.0, 0.0, 14.0), Vector3.ONE * 2.2, 90.0)
	_add_static_box(parent, Vector3(8.2, 3.0, 14.0), Vector3(11.6, 6.0, 2.5))

	# Courtyard Perimeter Trees (Scaled 2.8x - 3.4x -> 9m - 12m tall trees)
	var border_trees = [
		Vector3(-12.0, 0, -12.0), Vector3(-8.5, 0, -12.5), Vector3(8.5, 0, -12.5), Vector3(12.0, 0, -12.0),
		Vector3(-14.5, 0, -7.0), Vector3(-14.5, 0, 7.0), Vector3(14.5, 0, -7.0), Vector3(14.5, 0, 7.0)
	]
	var tree_paths = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/tree_single_A.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	for i in range(border_trees.size()):
		var t_pos = border_trees[i]
		var model_p = tree_paths[i % tree_paths.size()]
		_place_prop(parent, model_p, t_pos, Vector3.ONE * 3.0, float((i * 47) % 360))
		_add_static_cyl(parent, t_pos, 1.0, 7.0)

	# Decorative Courtyard Props & Market Stalls
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-2.8, 0, 12.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-2.1, 0, 12.5), Vector3.ONE * 1.1)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(2.8, 0, 12.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(3.5, 0, 11.5), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(3.2, 0, 12.8), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(-4.5, 0, 10.5), Vector3.ONE * 1.6, 35.0)
	_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(-3.8, 0, 11.2), Vector3.ONE * 0.4)
	_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(-3.5, 0, 11.5), Vector3.ONE * 0.35)
	_place_prop(parent, "res://assets/overworld/bench_decorated.gltf", Vector3(-5.5, 0, 4.0), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/bench_decorated.gltf", Vector3(5.5, 0, 4.0), Vector3.ONE * 1.8, -90.0)

	# Friendly Town Fox resting in the Courtyard Garden
	_spawn_animated_fauna(parent, "res://assets/characters/animals/Fox.glb", Vector3(-6.2, 0.0, 5.5), Vector3.ONE * 0.12, 45.0, "AnimalArmature|Idle")

	# Oakhaven Town Square Patrolling Guards (Continuous marching walk cycles)
	var guard_highway = PatrolNPCScript.new()
	guard_highway.npc_name = "Sentry Brand"
	guard_highway.position = Vector3(1.8, 0.0, 10.0)
	guard_highway.waypoints = [
		Vector3(1.8, 0.0, 11.5),
		Vector3(1.8, 0.0, 1.0),
		Vector3(-1.8, 0.0, 1.0),
		Vector3(-1.8, 0.0, 11.5)
	]
	parent.add_child(guard_highway)

	var guard_cross = PatrolNPCScript.new()
	guard_cross.npc_name = "Patrolman Kaelen"
	guard_cross.position = Vector3(-6.0, 0.0, 2.0)
	guard_cross.waypoints = [
		Vector3(-8.0, 0.0, 2.0),
		Vector3(8.0, 0.0, 2.0),
		Vector3(8.0, 0.0, -2.0),
		Vector3(-8.0, 0.0, -2.0)
	]
	parent.add_child(guard_cross)

	# Merchant Supply Wagon & Pallets in Plaza
	_place_prop(parent, "res://assets/village/Prop_Wagon.gltf", Vector3(-5.0, 0.0, 8.5), Vector3.ONE * 1.6, 25.0)
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(-6.2, 0.0, 7.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/crate_long_A.gltf", Vector3(-6.2, 0.0, 7.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_long_B.gltf", Vector3(-6.0, 0.0, 9.2), Vector3.ONE * 1.3, 90.0)

	# 7. EXPANDED OPEN WORLD MEDIEVAL REALM
	_build_road_network(parent)
	_build_town_quarter(parent)
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
	_build_crossroads_and_highroads(parent)

	# 8. SUBTERRANEAN INTERIOR CHAMBERS & ENTERABLE DOORWAYS
	_build_enterable_building_doorways(parent)
	InteriorsManager.build_all_interiors(parent)

func _build_road_network(parent: Node3D) -> void:
	# Main Highway: Sanctuary South Gate (Z=14) -> Stone Bridge (Z=24) -> Castle Keep (Z=44)
	for z_step in range(14, 45, 2):
		if z_step >= 20 and z_step <= 27:
			continue # Handled by the Stone Bridge
		for rx in range(-1, 2):
			_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(float(rx) * 1.9, 0.02, float(z_step)), Vector3(1.1, 1.0, 1.1))
		
	# East Village Road: leaves Main Highway north of the river at Z = 14.5 (clear of Watermill)
	for step in range(1, 14):
		var x_pos = float(step) * 1.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 14.5), Vector3(1.1, 1.0, 1.1))
		
	# West Town Market Road: leads to Tavern (X = -10) and Market (X = -18)
	for step in range(1, 11):
		var x_pos = -float(step) * 1.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 16.5), Vector3(1.1, 1.0, 1.1))

	# South-East Pasture & Windmill Path: leaves Main Highway smoothly at Z = 32.0 towards Pasture Gate (X = 23, Z = 37)
	for step in range(1, 10):
		var p_x = float(step) * 2.1
		var p_z = 32.0 + float(step) * 0.6
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(p_x, 0.02, p_z), Vector3(1.1, 1.0, 1.1))

	# Mountain Trail: North-East from Cathedral into High Crags
	var mtn_path = [
		Vector3(14.0, 0.02, -4.0), Vector3(18.0, 0.02, -8.0), Vector3(22.0, 0.02, -12.0),
		Vector3(26.0, 0.02, -16.0), Vector3(30.0, 0.02, -20.0), Vector3(34.0, 0.02, -22.0)
	]
	for p in mtn_path:
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", p, Vector3(2.0, 1.0, 2.0))

	# Ancient Path: North-West from Blacksmith into Forgotten Ruins
	var ruins_path = [
		Vector3(-14.0, 0.02, -3.0), Vector3(-18.0, 0.02, -5.0), Vector3(-22.0, 0.02, -6.0),
		Vector3(-26.0, 0.02, -6.0), Vector3(-30.0, 0.02, -5.0), Vector3(-34.0, 0.02, -4.0)
	]
	for p in ruins_path:
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", p, Vector3(2.0, 1.0, 2.0))

func _build_town_quarter(parent: Node3D) -> void:
	# 1. The Boar's Tusk Tavern (West of South Highway: X = -10.0, Z = 17.5)
	var tavern = _place_prop(parent, "res://assets/overworld/building_tavern_blue.gltf", Vector3(-10.0, 0.0, 17.5), Vector3.ONE * 6.5, 45.0)
	_add_static_box(parent, Vector3(-10.0, 4.5, 17.5), Vector3(7.5, 9.0, 8.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(-10.0, 8.5, 16.5))
	
	# Tavern Patio: Outdoor tables, stools, and ale barrels
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-6.5, 0.0, 17.5), Vector3.ONE * 1.6, 90.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-6.5, 0.0, 16.4), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-6.5, 0.0, 18.6), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-8.2, 0.0, 19.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-7.5, 0.0, 19.8), Vector3.ONE * 1.1)

	# NPC: Barnaby the Barkeep
	var barkeep = TownNPCScript.new()
	barkeep.npc_id = "barkeep"
	barkeep.npc_name = "Barnaby"
	barkeep.npc_title = "Tavern Keeper"
	barkeep.icon = "🍺"
	barkeep.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	barkeep.model_scale = Vector3(0.52, 0.52, 0.52)
	barkeep.model_rotation_y = 120.0
	barkeep.dialogue_text = "Rest your weary bones, adventurer! A tankard of spiced cider cures all curses. Mind the talk of shadows in the Blackwood Forest... folks say the trees have eyes!"
	barkeep.position = Vector3(-6.2, 0.0, 17.5)
	parent.add_child(barkeep)

	# 2. Sanctuary Marketplace (West flank: X = -18.0, Z = 16.5)
	var market = _place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-18.0, 0.0, 16.5), Vector3.ONE * 4.5, -30.0)
	_add_static_box(parent, Vector3(-18.0, 2.5, 16.5), Vector3(7.5, 5.0, 6.0))
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-14.8, 0.0, 15.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(-15.2, 0.0, 17.2), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(-14.2, 0.0, 16.8), Vector3.ONE * 1.5)

	# NPC: Merchant Corin
	var merchant = TownNPCScript.new()
	merchant.npc_id = "merchant"
	merchant.npc_name = "Corin"
	merchant.npc_title = "Traveling Merchant"
	merchant.icon = "💰"
	merchant.model_path = "res://assets/characters/adventurers/Rogue.glb"
	merchant.model_scale = Vector3(0.53, 0.53, 0.53)
	merchant.model_rotation_y = 60.0
	merchant.dialogue_text = "Finest goods from across the realm! Weapons tempered in dwarven fire and draughts brewed by eastern alchemists. Bring me ancient relics from the catacombs and I will pay a handsome fortune!"
	merchant.position = Vector3(-14.5, 0.0, 16.0)
	parent.add_child(merchant)

	# Herbalist Stall & Elowen
	_place_prop(parent, "res://assets/overworld/building_market_yellow.gltf", Vector3(-22.0, 0.0, 14.5), Vector3.ONE * 4.2, 15.0)
	_add_static_box(parent, Vector3(-22.0, 2.5, 14.5), Vector3(6.5, 5.0, 5.5))
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-24.5, 0.0, 13.8), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-24.0, 0.0, 15.2), Vector3.ONE * 1.2)

	var herbalist = TownNPCScript.new()
	herbalist.npc_id = "herbalist"
	herbalist.npc_name = "Elowen"
	herbalist.npc_title = "Master Apothecary & Herbalist"
	herbalist.icon = "🌿"
	herbalist.model_path = "res://assets/characters/adventurers/Mage.glb"
	herbalist.model_scale = Vector3(0.52, 0.52, 0.52)
	herbalist.model_rotation_y = 45.0
	herbalist.dialogue_text = "Greetings, wanderer! Fresh moon-sage, mountain thistle, and soothing draughts to cleanse wounds. Stay vigilant against the foul pestilence rising from the tombs!"
	herbalist.position = Vector3(-20.5, 0.0, 14.2)
	parent.add_child(herbalist)

	# 3. Guard Archery Training Yard (East Sanctuary Green: X = 28.0, Z = 3.0 — clear of Riverside Watermill)
	var range_bldg = _place_prop(parent, "res://assets/overworld/building_archeryrange_blue.gltf", Vector3(28.0, 0.0, 3.0), Vector3.ONE * 4.5, -45.0)
	_add_static_box(parent, Vector3(28.0, 3.5, 3.0), Vector3(7.0, 7.5, 7.0))
	_place_prop(parent, "res://assets/overworld/target.gltf", Vector3(22.5, 0.0, 2.0), Vector3.ONE * 3.5, 90.0)
	_place_prop(parent, "res://assets/overworld/target.gltf", Vector3(22.5, 0.0, 4.2), Vector3.ONE * 3.5, 90.0)
	_place_prop(parent, "res://assets/overworld/bucket_arrows.gltf", Vector3(24.5, 0.0, 2.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(24.5, 0.0, 4.5), Vector3.ONE * 1.8, 90.0)

	# NPC: Cadet Ronin - Sanctuary Marksman practicing at the target
	var archer = TownNPCScript.new()
	archer.npc_id = "archer_apprentice"
	archer.npc_name = "Cadet Ronin"
	archer.npc_title = "Sanctuary Marksman"
	archer.icon = "🎯"
	archer.model_path = "res://assets/characters/adventurers/Rogue.glb"
	archer.model_scale = Vector3(0.53, 0.53, 0.53)
	archer.model_rotation_y = 90.0
	archer.dialogue_text = "Steady breath, steady aim! Captain Vane says the outlaws in Whisperwood won't wait for us to draw. Practice makes lethal!"
	archer.position = Vector3(26.2, 0.0, 3.1)
	parent.add_child(archer)

	# 4. Street Lantern Posts along Thoroughfares
	_place_lantern_post(parent, Vector3(-5.0, 0.0, 15.0), 45.0)
	_place_lantern_post(parent, Vector3(5.0, 0.0, 15.0), -45.0)
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 20.5))
	_place_lantern_post(parent, Vector3(2.8, 0.0, 20.5))
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 27.5), 180.0)
	_place_lantern_post(parent, Vector3(2.8, 0.0, 27.5), 180.0)
	_place_lantern_post(parent, Vector3(-3.5, 0.0, 37.5))
	_place_lantern_post(parent, Vector3(3.5, 0.0, 37.5))

func _place_lantern_post(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var post = _place_prop(parent, "res://assets/overworld/post_lantern.gltf", pos, Vector3.ONE * 1.1, rot_y)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.45) # Warm medieval lantern
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position = Vector3(0.0, 3.2, 0.0)
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
	# 1. North-West Riverside Garden & Tavern Green (X in [-7, -2], Z in [15, 20])
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(-4.5, 0.0, 16.0), Vector3.ONE * 2.0, 90.0)
	_place_prop(parent, "res://assets/overworld/fence_broken.gltf", Vector3(-4.5, 0.0, 18.2), Vector3.ONE * 2.0, 90.0)
	_place_prop(parent, "res://assets/overworld/tree_single_A.gltf", Vector3(-5.2, 0.0, 19.2), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-3.8, 0.0, 19.5), Vector3.ONE * 1.6, 25.0)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(-6.8, 0.0, 19.8), Vector3.ONE * 1.8, -45.0)

	# 2. North-East Riverside Grove (X in [3, 9], Z in [15, 20])
	_place_prop(parent, "res://assets/overworld/tree_pine_orange_small.gltf", Vector3(6.5, 0.0, 16.5), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/trees_A_small.gltf", Vector3(8.5, 0.0, 17.5), Vector3.ONE * 2.4)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(4.2, 0.0, 17.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(4.8, 0.0, 17.2), Vector3.ONE * 1.2)

	# 3. South River Meadows & Grazing Pasture (Z in [28, 42])
	# West Meadow - Shaded forest border with grazing deer & noble stag
	_place_prop(parent, "res://assets/overworld/tree_single_B.gltf", Vector3(-8.5, 0.0, 31.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/tree_pine_yellow_small.gltf", Vector3(-14.0, 0.0, 34.0), Vector3.ONE * 3.2)
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-6.5, 0.0, 33.0), Vector3.ONE * 2.4, 40.0)
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-11.5, 0.0, 36.0), Vector3.ONE * 2.0, -30.0)
	_spawn_animated_fauna(parent, "res://assets/characters/animals/Deer.glb", Vector3(-9.2, 0.0, 33.5), Vector3.ONE * 0.55, 60.0, "AnimalArmature|Eating")
	_spawn_animated_fauna(parent, "res://assets/characters/animals/Deer.glb", Vector3(-12.5, 0.0, 31.0), Vector3.ONE * 0.52, -45.0, "AnimalArmature|Idle_2")
	_spawn_animated_fauna(parent, "res://assets/characters/animals/Stag.glb", Vector3(-7.0, 0.0, 36.5), Vector3.ONE * 0.60, 110.0, "AnimalArmature|Idle")

	# East Meadow - Farm approach with wooden fences, birch trees, hay & barrel clutter
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(4.8, 0.0, 30.0), Vector3.ONE * 2.0, -25.0)
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(6.5, 0.0, 32.0), Vector3.ONE * 2.0, -25.0)
	_place_prop(parent, "res://assets/overworld/fence_broken.gltf", Vector3(8.2, 0.0, 34.0), Vector3.ONE * 2.0, -25.0)
	_place_prop(parent, "res://assets/overworld/trees_A_medium.gltf", Vector3(12.0, 0.0, 31.5), Vector3.ONE * 2.8)
	_place_prop(parent, "res://assets/overworld/tree_pine_orange_small.gltf", Vector3(15.5, 0.0, 34.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(9.2, 0.0, 35.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(9.8, 0.0, 35.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(10.5, 0.0, 29.5), Vector3.ONE * 2.2, 70.0)

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

	# 4. Natural Stone Riverbanks: lining North Bank (Z=19.8) and South Bank (Z=28.2)
	for rx in range(-24, 25, 2):
		var x_f = float(rx) * 2.2
		# Skip where bridges cross (X ~ 0 and X ~ -18) and watermill wheel (X ~ 13.5)
		if abs(x_f) > 3.2 and abs(x_f - (-18.0)) > 3.2 and abs(x_f - 13.5) > 3.8:
			var r_model = "res://assets/overworld/rock_single_A.gltf" if (rx % 4 == 0) else "res://assets/overworld/rock_single_B.gltf"
			_place_prop(parent, r_model, Vector3(x_f, 0.0, 19.8), Vector3(2.0, 1.4, 2.0), float((rx * 37) % 360))
			_place_prop(parent, r_model, Vector3(x_f + 0.8, 0.0, 28.2), Vector3(2.0, 1.4, 2.0), float((rx * 53) % 360))

	# Water lilies and river reeds in the water
	_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", Vector3(-8.0, -0.10, 23.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterlily_B.gltf", Vector3(6.0, -0.10, 24.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterplant_A.gltf", Vector3(-5.0, -0.12, 21.2), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(14.0, -0.12, 26.8), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/waterplant_C.gltf", Vector3(-24.0, -0.12, 22.5), Vector3.ONE * 1.8)

	# Main Highway Stone Arch Bridge (Smoothly Walkable Arched Highway)
	_build_walkable_stone_bridge(parent, Vector3(0.0, 0.0, 24.0), Vector3(4.0, 3.2, 7.5))

	# Western Wooden Footbridge (Smoothly Walkable Planked Footbridge)
	_build_walkable_wooden_bridge(parent, Vector3(-18.0, 0.0, 24.0), Vector3(3.6, 2.8, 7.0))

	# Riverside Watermill with Rotating Wheel Submerged Directly in the Flowing River Water
	_build_watermill_and_canal(parent, Vector3(13.5, -0.38, 20.8))

func _build_walkable_stone_bridge(parent: Node3D, pos: Vector3, sc: Vector3) -> void:
	_place_prop(parent, "res://assets/overworld/building_bridge_A.gltf", pos, sc)
	
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
	_place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", pos, sc)
	
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

	# 3. Riverside Mill Embankment Rocks & Flour Sack Storage on the North Bank
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(pos.x - 3.4, 0.0, 19.6), Vector3(1.6, 1.2, 1.6), 40.0)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(pos.x + 3.4, 0.0, 19.6), Vector3(1.8, 1.3, 1.8), -65.0)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(pos.x - 3.4, 0.0, 17.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(pos.x - 3.4, 0.0, 16.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(pos.x - 2.6, 0.0, 15.8), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(pos.x - 2.5, 0.0, 18.0), Vector3.ONE * 1.3)

	# NPC: Miller Bronn
	var bronn = TownNPCScript.new()
	bronn.npc_id = "miller"
	bronn.npc_name = "Miller Bronn"
	bronn.npc_title = "River Grain Master"
	bronn.icon = "⚙️"
	bronn.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	bronn.model_scale = Vector3(0.54, 0.54, 0.54)
	bronn.model_rotation_y = 150.0
	bronn.dialogue_text = "Hear the rumble of the wheel! The river current powers the millstones day and night, grinding Giles's wheat into fine golden flour for the capital."
	bronn.position = Vector3(pos.x - 3.2, 0.0, 18.2)
	parent.add_child(bronn)

func _build_farmlands_hamlet(parent: Node3D) -> void:
	# Grand Windmill (Towering 14.3m high landmark with rotating blades)
	var windmill = _place_prop(parent, "res://assets/overworld/building_windmill_blue.gltf", Vector3(34.0, 0.0, 38.0), Vector3.ONE * 12.0)
	_add_static_cyl(parent, Vector3(34.0, 0.0, 38.0), 4.0, 13.0)
	var fan_rot = RotatingProp.new()
	fan_rot.target_node_name = "building_windmill_top_fan_blue"
	fan_rot.rotation_axis = Vector3(0, 0, 1)
	fan_rot.rpm = 7.5
	windmill.add_child(fan_rot)
	
	# Rolling Hill behind windmill
	_place_prop(parent, "res://assets/overworld/hill_single_A.gltf", Vector3(42.0, 0.0, 42.0), Vector3.ONE * 9.0)
	
	# Thatched Cottages (North of river: Z in [13, 16], X in [22, 38])
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(22.0, 0.0, 14.0), Vector3.ONE * 7.5, 45.0)
	_add_static_box(parent, Vector3(22.0, 3.5, 14.0), Vector3(6.2, 6.5, 6.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(22.0, 7.2, 14.0))
	
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(38.0, 0.0, 15.0), Vector3.ONE * 7.0, -30.0)
	_add_static_box(parent, Vector3(38.0, 4.0, 15.0), Vector3(6.5, 7.5, 7.8))
	AmbientFX.create_chimney_smoke(parent, Vector3(38.0, 8.8, 15.0))
	
	# Village Stone Well (3.5m tall well)
	_place_prop(parent, "res://assets/overworld/building_well_blue.gltf", Vector3(28.0, 0.0, 17.5), Vector3.ONE * 2.8)
	_add_static_cyl(parent, Vector3(28.0, 0.0, 17.5), 1.4, 3.2)
	
	# NPC: Farmer Giles
	var giles = TownNPCScript.new()
	giles.npc_id = "farmer"
	giles.npc_name = "Farmer Giles"
	giles.npc_title = "Hamlet Elder"
	giles.icon = "🌾"
	giles.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	giles.model_scale = Vector3(0.56, 0.56, 0.56)
	giles.model_rotation_y = -45.0
	giles.dialogue_text = "Good day, traveler! Welcome to our modest hamlet. The wheat is ripe, but hungry beasts stalk our pastures. Deliver raw meat or fine hides from the wild beasts, and we shall reward you richly in coin!"
	giles.position = Vector3(25.0, 0.0, 17.0)
	parent.add_child(giles)

	# Tilled Pumpkin Patch (North of river: X in [31, 35], Z in [10, 13])
	for px in range(31, 36):
		for pz in range(10, 13):
			_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(float(px) + 0.3, 0.0, float(pz) + 0.3), Vector3.ONE * 0.4)

	# Farm Tools & Storage Props
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(23.0, 0.0, 18.5), Vector3.ONE * 1.6, 35.0)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(21.5, 0.0, 16.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(20.5, 0.0, 15.5), Vector3.ONE * 1.3)

	# =========================================================================
	# COMPLETELY DRY, FULLY ENCLOSED ANIMAL PASTURE (South of river at Z in [31, 43], X in [23, 41])
	# =========================================================================
	var p_x1 = 23.0
	var p_x2 = 41.0
	var p_z1 = 31.0
	var p_z2 = 43.0
	var f_step = 2.5
	
	# North fence line (Z = 31.0, dry land 3m south of river)
	var x_cursor = p_x1
	while x_cursor <= p_x2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(x_cursor, 0.0, p_z1), Vector3.ONE * 2.2, 90.0)
		x_cursor += f_step
		
	# South fence line (Z = 43.0)
	x_cursor = p_x1
	while x_cursor <= p_x2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(x_cursor, 0.0, p_z2), Vector3.ONE * 2.2, 90.0)
		x_cursor += f_step
		
	# East fence line (X = 41.0)
	var z_cursor = p_z1
	while z_cursor <= p_z2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x2, 0.0, z_cursor), Vector3.ONE * 2.2, 0.0)
		z_cursor += f_step
		
	# West fence line (X = 23.0 with entrance gate at Z = 37.0)
	z_cursor = p_z1
	while z_cursor <= p_z2:
		if abs(z_cursor - 37.0) < 1.3:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight_gate.gltf", Vector3(p_x1, 0.0, z_cursor), Vector3.ONE * 2.2, 0.0)
		else:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x1, 0.0, z_cursor), Vector3.ONE * 2.2, 0.0)
		z_cursor += f_step

	# Pasture Perimeter Collision (Keeps livestock inside the corral)
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z1), Vector3(p_x2 - p_x1 + 1.0, 1.6, 0.4))
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z2), Vector3(p_x2 - p_x1 + 1.0, 1.6, 0.4))
	_add_static_box(parent, Vector3(p_x2, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1 + 1.0))
	_add_static_box(parent, Vector3(p_x1, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1 + 1.0))

	# Farm Supply Wagon & Pallets near Pasture Gate
	_place_prop(parent, "res://assets/village/Prop_Wagon.gltf", Vector3(25.5, 0.0, 39.5), Vector3.ONE * 1.5, -20.0)
	_place_prop(parent, "res://assets/overworld/pallet.gltf", Vector3(24.0, 0.0, 39.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_long_A.gltf", Vector3(24.0, 0.0, 39.0), Vector3.ONE * 1.2)

	# Pasture Livestock Dressing (Water troughs, feed buckets)
	_place_prop(parent, "res://assets/overworld/bucket_water.gltf", Vector3(25.5, 0.0, 33.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(24.5, 0.0, 32.5), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(24.0, 0.0, 33.5), Vector3.ONE * 1.4)

	# Grazing Animals inside the dry fenced pasture
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(28.0, 0.0, 35.0), 45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(36.0, 0.0, 39.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(31.0, 0.0, 41.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.BULL, Vector3(32.0, 0.0, 36.0), 120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(27.0, 0.0, 40.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(38.0, 0.0, 34.0), -85.0)

	# NPC: Barnaby the Stable Master (Outside the Pasture Gate)
	var stablemaster = TownNPCScript.new()
	stablemaster.npc_id = "stablemaster"
	stablemaster.npc_name = "Barnaby"
	stablemaster.npc_title = "Royal Ostler & Stable Master"
	stablemaster.icon = "🐎"
	stablemaster.model_path = "res://assets/characters/adventurers/Knight.glb"
	stablemaster.model_scale = Vector3(0.55, 0.55, 0.55)
	stablemaster.model_rotation_y = 90.0
	stablemaster.position = Vector3(20.8, 0.0, 37.0)
	parent.add_child(stablemaster)
	
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(20.5, 0.0, 39.0), Vector3.ONE * 1.8, 90.0)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(20.5, 0.0, 35.0), Vector3.ONE * 1.4)

func _build_castle_citadel(parent: Node3D) -> void:
	# Royal Castle Keep (Imposing 25.8m tall imperial fortress)
	_place_prop(parent, "res://assets/overworld/building_castle_blue.gltf", Vector3(0.0, 0.0, 44.0), Vector3.ONE * 6.5)
	_add_static_box(parent, Vector3(0.0, 8.0, 44.0), Vector3(13.0, 16.0, 14.5))

	# Left & Right Citadel Watchtowers (15.4m tall catapult towers)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-12.0, 0.0, 38.0), Vector3.ONE * 9.5)
	_add_static_box(parent, Vector3(-12.0, 7.0, 38.0), Vector3(4.5, 14.0, 4.5))
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(12.0, 0.0, 38.0), Vector3.ONE * 9.5)
	_add_static_box(parent, Vector3(12.0, 7.0, 38.0), Vector3(4.5, 14.0, 4.5))

	# Grand Citadel Arched Gateway (Aligned with the Royal Highway at X = 0.0, Z = 38.0)
	var citadel_arch = _place_prop(parent, "res://assets/overworld/arch.gltf", Vector3(0.0, 0.0, 38.0), Vector3(2.5, 3.8, 2.5))
	_place_prop(citadel_arch, "res://assets/overworld/flag_blue.gltf", Vector3(0.0, 4.0, 0.0), Vector3.ONE * 2.2)

	# Stone curtain walls connecting keep to towers (7.5m tall battlements flanking the arch)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-6.8, 0.0, 38.0), Vector3(3.6, 4.5, 3.0))
	_add_static_box(parent, Vector3(-6.8, 3.5, 38.0), Vector3(6.5, 7.5, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(6.8, 0.0, 38.0), Vector3(3.6, 4.5, 3.0))
	_add_static_box(parent, Vector3(6.8, 3.5, 38.0), Vector3(6.5, 7.5, 2.5))

	# Garrison Barracks (9.0m tall)
	_place_prop(parent, "res://assets/overworld/building_barracks_blue.gltf", Vector3(18.0, 0.0, 34.0), Vector3.ONE * 5.5, -45.0)
	_add_static_box(parent, Vector3(18.0, 4.5, 34.0), Vector3(8.0, 7.0, 8.5))

	# Military Market Outpost
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-18.0, 0.0, 34.0), Vector3.ONE * 3.6, 45.0)

	# NPC: Commander Drake (Proportionate ~1.92m knight commander guarding the Citadel Gateway)
	var drake = TownNPCScript.new()
	drake.npc_id = "commander"
	drake.npc_name = "Commander Drake"
	drake.npc_title = "Citadel Commander"
	drake.icon = "🛡️"
	drake.model_path = "res://assets/characters/adventurers/Knight.glb"
	drake.model_scale = Vector3(0.58, 0.58, 0.58)
	drake.model_rotation_y = 150.0
	drake.dialogue_text = "Stand firm, warrior! The Imperial Citadel stands vigil against the abyss. Our scouts report arcane crystals gleaming in the north-eastern crags, and sacred relics lost in the western ruins. Check your royal bounties and bring glory to the realm!"
	drake.position = Vector3(-3.2, 0.0, 35.5)
	parent.add_child(drake)

	# Castle Props
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-4.5, 0.0, 36.0), Vector3.ONE * 2.0, 25.0)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(-12.0, 15.0, 38.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(12.0, 15.0, 38.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(4.5, 0.0, 36.0), Vector3.ONE * 1.5)
	AmbientFX.create_chimney_smoke(parent, Vector3(18.0, 8.8, 34.0))

	# Circling Hawks Flock high above Castle Keep in the upper sky
	var flock_castle = CirclingFlock.new()
	flock_castle.position = Vector3(0.0, 34.0, 42.0)
	flock_castle.bird_count = 5
	flock_castle.circle_radius = 16.0
	flock_castle.flight_height = 34.0
	parent.add_child(flock_castle)

func _build_blackwood_forest(parent: Node3D) -> void:
	# Lumbermill (9.5m tall building)
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-24.0, 0.0, 32.0), Vector3.ONE * 6.0, 90.0)
	_add_static_box(parent, Vector3(-24.0, 4.5, 32.0), Vector3(8.0, 7.0, 8.0))

	# Glowing Forest Fireflies
	AmbientFX.create_forest_fireflies(parent, Vector3(-28.0, 1.8, 22.0), 9.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(-34.0, 1.8, 32.0), 9.0)

	# Dense Forest Trees (Scaled 3.0x - 3.6x -> 10m to 14m tall realistic pines and birches)
	var forest_locs = [
		Vector3(-18.0, 0.0, 8.0), Vector3(-22.0, 0.0, 10.0), Vector3(-26.0, 0.0, 7.0),
		Vector3(-22.0, 0.0, 15.0), Vector3(-28.0, 0.0, 16.0), Vector3(-32.0, 0.0, 14.0),
		Vector3(-25.0, 0.0, 28.0), Vector3(-30.0, 0.0, 26.0), Vector3(-36.0, 0.0, 25.0),
		Vector3(-22.0, 0.0, 38.0), Vector3(-28.0, 0.0, 40.0), Vector3(-34.0, 0.0, 38.0),
		Vector3(-38.0, 0.0, 12.0), Vector3(-42.0, 0.0, 20.0), Vector3(-42.0, 0.0, 28.0),
		Vector3(-44.0, 0.0, 36.0), Vector3(-36.0, 0.0, 42.0), Vector3(-24.0, 0.0, 42.0)
	]
	var f_trees = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/trees_B_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	for i in range(forest_locs.size()):
		var lp = forest_locs[i]
		var tm = f_trees[i % f_trees.size()]
		_place_prop(parent, tm, lp, Vector3.ONE * 3.2, float((i * 53) % 360))
		_add_static_cyl(parent, lp, 1.0, 8.0)

	# Boulders
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-27.0, 0.0, 18.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/rock_single_D.gltf", Vector3(-35.0, 0.0, 20.0), Vector3.ONE * 2.8)

	# Forest Wildlife (Proper animal scales: Stags 32x, Deer 28x, Wolves 17x, Foxes 9x)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-26.0, 0.0, 14.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-34.0, 0.0, 26.0), -45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-22.0, 0.0, 18.0), 110.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-30.0, 0.0, 12.0), -120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(-28.0, 0.0, 32.0), 75.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-38.0, 0.0, 18.0), 160.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-36.0, 0.0, 30.0), -30.0)

	# Special Quest Timber Nodes
	_spawn_material_node(parent, "heartwood_timber", "Heartwood Timber", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-24.0, 0.0, 12.0), Color(0.8, 0.5, 0.2), 20, 15, Vector3(2.5, 2.5, 2.5))
	_spawn_material_node(parent, "ironwood_logs", "Ironwood Logs", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-32.0, 0.0, 26.0), Color(0.7, 0.4, 0.2), 25, 20, Vector3(2.5, 2.5, 2.5))

func _build_iron_mountains(parent: Node3D) -> void:
	# Giant Mountain Peaks (15m - 25m tall mountain crags)
	var mtns = [
		{"pos": Vector3(28.0, 0.0, -36.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 9.0},
		{"pos": Vector3(38.0, 0.0, -32.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 9.5},
		{"pos": Vector3(44.0, 0.0, -22.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 9.0},
		{"pos": Vector3(40.0, 0.0, -12.0), "path": "res://assets/overworld/mountain_A_grass.gltf", "scale": 8.5},
		{"pos": Vector3(22.0, 0.0, -38.0), "path": "res://assets/overworld/hills_A.gltf", "scale": 7.0},
		{"pos": Vector3(20.0, 0.0, -24.0), "path": "res://assets/overworld/hills_B_trees.gltf", "scale": 7.0}
	]
	for m in mtns:
		_place_prop(parent, m["path"], m["pos"], Vector3.ONE * m["scale"])
		_add_static_box(parent, m["pos"] + Vector3(0, 6.0, 0), Vector3(m["scale"] * 2.0, 12.0, m["scale"] * 2.0))

	# Mountain Mine Entrance (6.2m tall mine)
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(34.0, 0.0, -22.0), Vector3.ONE * 5.5, -90.0)
	_add_static_box(parent, Vector3(34.0, 3.5, -22.0), Vector3(7.5, 6.0, 7.5))

	# Mountain Wolf Guard (Fierce predator)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(30.0, 0.0, -24.0), 45.0)

	# Special Quest Mineral Nodes (Mineable crystals and gold ingots)
	_spawn_material_node(parent, "arcane_crystal", "Arcane Cyan Crystal", "💎", "res://assets/items/quest_materials/Crystal1.glb", Vector3(28.0, 0.0, -20.0), Color(0.2, 0.8, 1.0), 30, 25, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "emerald_crystal", "Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(36.0, 0.0, -26.0), Color(0.2, 1.0, 0.4), 35, 30, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "gold_vein", "Mountain Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(26.0, 0.0, -30.0), Color(1.0, 0.85, 0.2), 40, 35, Vector3(1.5, 1.5, 1.5))
	_spawn_material_node(parent, "iron_ore", "Highland Iron Ore", "⛏️", "res://assets/overworld/resource_stone.gltf", Vector3(32.0, 0.0, -16.0), Color(0.6, 0.65, 0.7), 25, 20, Vector3(2.5, 2.5, 2.5))

func _build_forgotten_ruins(parent: Node3D) -> void:
	# Shrines & Ancient Stone Pillars (8.7m tall columns)
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-34.0, 0.0, -4.0), Vector3.ONE * 2.8)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-30.0, 0.0, -8.0), Vector3(1.6, 2.5, 1.6))
	_add_static_cyl(parent, Vector3(-30.0, 0.0, -8.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-38.0, 0.0, -8.0), Vector3(1.6, 2.5, 1.6))
	_add_static_cyl(parent, Vector3(-38.0, 0.0, -8.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-32.0, 0.0, 2.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(-33.0, 0.0, -2.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/bone_A.gltf", Vector3(-31.0, 0.0, -5.0), Vector3.ONE * 1.8)

	# NPC: Hermit Morvath (Proportionate ~1.78m mage)
	var hermit = TownNPCScript.new()
	hermit.npc_id = "hermit"
	hermit.npc_name = "Hermit Morvath"
	hermit.npc_title = "Keeper of the Forgotten"
	hermit.icon = "🔮"
	hermit.model_path = "res://assets/characters/adventurers/Mage.glb"
	hermit.model_scale = Vector3(0.53, 0.53, 0.53)
	hermit.model_rotation_y = 65.0
	hermit.dialogue_text = "Tread lightly, warrior. The stones here remember an empire older than memory. The Sacred Chalice and the Ancient Codex are scattered among these cracked pedestals. Channel the Soul Echoes you reap to unlock arcane boons!"
	hermit.position = Vector3(-32.0, 0.0, -3.0)
	parent.add_child(hermit)

	# Sacred Relic Material Nodes
	_spawn_material_node(parent, "sacred_chalice", "Sacred Chalice of the First Kings", "🏆", "res://assets/items/quest_materials/Chalice.glb", Vector3(-36.0, 0.0, -6.0), Color(1.0, 0.8, 0.2), 50, 50, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "ossuary_codex", "Forgotten Ossuary Codex", "📜", "res://assets/items/quest_materials/Scroll.glb", Vector3(-30.0, 0.0, 2.0), Color(0.9, 0.85, 0.6), 40, 40, Vector3(2.0, 2.0, 2.0))
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
		_apply_flag_shader(prop)
		
	return prop

func _apply_flag_shader(node: Node3D) -> void:
	var flag_shader = load("res://shaders/waving_flag.gdshader")
	if flag_shader:
		var flag_mat = ShaderMaterial.new()
		flag_mat.shader = flag_shader
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
	# 1. Castle Grand Throne Room Doorway
	var castle_door = BuildingDoorway.new()
	castle_door.door_id = "castle_entrance"
	castle_door.prompt_text = "Enter Castle Grand Hall"
	castle_door.target_position = Vector3(0.0, -99.8, 10.0)
	castle_door.target_rotation_y = 180.0
	castle_door.target_cam_distance = 12.0
	castle_door.target_cam_pitch = 40.0
	castle_door.target_bgm_key = "bgm_castle"
	castle_door.position = Vector3(0.0, 0.0, 39.0)
	parent.add_child(castle_door)

	# 2. The Boar's Tusk Tavern Doorway
	var tavern_door = BuildingDoorway.new()
	tavern_door.door_id = "tavern_entrance"
	tavern_door.prompt_text = "Enter The Boar's Tusk Tavern"
	tavern_door.target_position = Vector3(60.0, -99.8, 4.8)
	tavern_door.target_rotation_y = 0.0
	tavern_door.target_cam_distance = 11.0
	tavern_door.target_cam_pitch = 40.0
	tavern_door.target_bgm_key = "bgm_tavern"
	tavern_door.position = Vector3(-7.5, 0.0, 17.5)
	parent.add_child(tavern_door)

	# 3. Master Torval's Forge Doorway
	var forge_door = BuildingDoorway.new()
	forge_door.door_id = "forge_entrance"
	forge_door.prompt_text = "Enter Master Torval's Forge"
	forge_door.target_position = Vector3(120.0, -99.8, 4.0)
	forge_door.target_rotation_y = 0.0
	forge_door.target_cam_distance = 10.0
	forge_door.target_cam_pitch = 40.0
	forge_door.target_bgm_key = "bgm_forge"
	forge_door.position = Vector3(-11.5, 0.0, 0.0)
	parent.add_child(forge_door)

	# 4. Giles's Thatched Cottage Doorway
	var cottage_door = BuildingDoorway.new()
	cottage_door.door_id = "cottage_entrance"
	cottage_door.prompt_text = "Enter Giles's Thatched Cottage"
	cottage_door.target_position = Vector3(180.0, -99.8, 3.0)
	cottage_door.target_rotation_y = 0.0
	cottage_door.target_cam_distance = 10.0
	cottage_door.target_cam_pitch = 40.0
	cottage_door.target_bgm_key = "bgm_overworld"
	cottage_door.position = Vector3(19.5, 0.0, 14.0)
	parent.add_child(cottage_door)

	# 5. Port Blackwater: The Rusty Anchor Tavern Doorway
	var rusty_door = BuildingDoorway.new()
	rusty_door.door_id = "rusty_anchor_entrance"
	rusty_door.prompt_text = "Enter The Rusty Anchor Tavern"
	rusty_door.target_position = Vector3(240.0, -99.8, 4.5)
	rusty_door.target_rotation_y = 0.0
	rusty_door.target_cam_distance = 11.0
	rusty_door.target_cam_pitch = 40.0
	rusty_door.target_bgm_key = "bgm_tavern"
	rusty_door.position = Vector3(-56.0, 0.0, 72.0)
	parent.add_child(rusty_door)

	# 6. Khar-Drakken: Stonegate Smelting Foundry Doorway
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
	# 1. Open Ocean Water Surface (Y = -0.15m, X in [-130, -50], Z in [35, 130])
	var ocean_basin = MeshInstance3D.new()
	ocean_basin.name = "OceanWaterSurface"
	var oc_mesh = PlaneMesh.new()
	oc_mesh.size = Vector2(85.0, 95.0)
	ocean_basin.mesh = oc_mesh
	var ocean_mat = ShaderMaterial.new()
	ocean_mat.shader = load("res://shaders/river_flow.gdshader")
	ocean_basin.material_override = ocean_mat
	ocean_basin.position = Vector3(-90.0, -0.15, 82.5)
	parent.add_child(ocean_basin)

	# 2. Golden Sandy Beach Coastline Strip (X in [-75, -45], Z in [25, 90])
	var sand_mesh_inst = MeshInstance3D.new()
	sand_mesh_inst.name = "CoastalSandVisual"
	var s_mesh = PlaneMesh.new()
	s_mesh.size = Vector2(30.0, 70.0)
	sand_mesh_inst.mesh = s_mesh
	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.82, 0.74, 0.52) # Coastal beach sand
	sand_mat.roughness = 0.94
	sand_mesh_inst.material_override = sand_mat
	sand_mesh_inst.position = Vector3(-60.0, 0.01, 55.0)
	parent.add_child(sand_mesh_inst)

	# 3. Wooden Docks & Piers (Pier stretching into the sea at Z = 65, X from -52 to -88)
	for px in range(-52, -88, -4):
		_place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", Vector3(float(px), 0.0, 65.0), Vector3(2.5, 2.0, 4.0), 90.0)
		_add_static_box(parent, Vector3(float(px), 0.4, 65.0), Vector3(4.2, 0.8, 3.5))
	
	# Harbor Watchman Patrol along the pier
	var harbor_guard = PatrolNPCScript.new()
	harbor_guard.npc_name = "Boatswain Finn"
	harbor_guard.npc_title = "Pier Watchman"
	harbor_guard.position = Vector3(-54.0, 0.4, 65.0)
	harbor_guard.waypoints = [
		Vector3(-54.0, 0.4, 65.0),
		Vector3(-82.0, 0.4, 65.0),
		Vector3(-82.0, 0.4, 65.0),
		Vector3(-54.0, 0.4, 65.0)
	]
	parent.add_child(harbor_guard)

	# Second Jetty at Z = 80, X from -55 to -78
	for px in range(-55, -79, -4):
		_place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", Vector3(float(px), 0.0, 80.0), Vector3(2.5, 2.0, 4.0), 90.0)
		_add_static_box(parent, Vector3(float(px), 0.4, 80.0), Vector3(4.2, 0.8, 3.5))

	# 4. Port Blackwater Settlement Buildings
	# Harbormaster Watchtower (15m tall stone tower overlooking the harbor)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-54.0, 0.0, 48.0), Vector3.ONE * 8.5)
	_add_static_box(parent, Vector3(-54.0, 6.0, 48.0), Vector3(4.5, 12.0, 4.5))

	# The Rusty Anchor Harbor Tavern
	_place_prop(parent, "res://assets/overworld/building_tavern_blue.gltf", Vector3(-56.0, 0.0, 72.0), Vector3.ONE * 6.5, -45.0)
	_add_static_box(parent, Vector3(-56.0, 4.5, 72.0), Vector3(7.5, 9.0, 8.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(-56.0, 8.5, 71.0))

	# Smuggler's Boathouse & Warehouse
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(-66.0, 0.0, 36.0), Vector3.ONE * 7.0, 45.0)
	_add_static_box(parent, Vector3(-66.0, 3.5, 36.0), Vector3(6.5, 7.0, 6.5))

	# Harbor Fish Market Stalls
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-52.0, 0.0, 60.0), Vector3.ONE * 4.2, 30.0)
	_add_static_box(parent, Vector3(-52.0, 2.5, 60.0), Vector3(6.5, 5.0, 5.5))

	# Harbor Cargo Stacks (Barrels, crates, sacks on the piers)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-60.0, 0.0, 64.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-61.2, 0.0, 64.3), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-63.0, 0.0, 66.0), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(-72.0, 0.0, 64.0), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(-58.0, 0.0, 66.0), Vector3.ONE * 1.5)
	_place_lantern_post(parent, Vector3(-54.0, 0.0, 65.0), 90.0)
	_place_lantern_post(parent, Vector3(-76.0, 0.0, 65.0), 90.0)
	_place_lantern_post(parent, Vector3(-54.0, 0.0, 80.0), 90.0)

	# Shoreline Coastal Rocks & Reeds
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-68.0, 0.0, 48.0), Vector3.ONE * 3.2, 35.0)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(-74.0, 0.0, 58.0), Vector3.ONE * 3.5, -45.0)
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-82.0, 0.0, 74.0), Vector3.ONE * 4.0, 60.0)
	_place_prop(parent, "res://assets/overworld/waterplant_A.gltf", Vector3(-70.0, -0.1, 70.0), Vector3.ONE * 2.0)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(-80.0, -0.1, 85.0), Vector3.ONE * 2.2)

	# 5. NPCs
	# Captain Marlo (Corsair Captain)
	var marlo = TownNPCScript.new()
	marlo.npc_id = "captain_marlo"
	marlo.npc_name = "Captain Marlo"
	marlo.npc_title = "Corsair Captain"
	marlo.icon = "⚓"
	marlo.model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
	marlo.model_scale = Vector3(0.55, 0.55, 0.55)
	marlo.model_rotation_y = 75.0
	marlo.dialogue_text = "Ahoy, landlubber! Welcome to Port Blackwater. Smugglers and salty sea dogs rule these tides. The Deep Sea Creeps have infested the southern reef and stolen the Tidecaller's Compass! Slay the lurkers and bring me the Compass to claim the corsair fortune!"
	marlo.position = Vector3(-60.0, 0.0, 68.0)
	parent.add_child(marlo)

	# Harbormaster Corin (Port Warden)
	var corin = TownNPCScript.new()
	corin.npc_id = "harbormaster"
	corin.npc_name = "Harbormaster Corin"
	corin.npc_title = "Port Warden"
	corin.icon = "🧭"
	corin.model_path = "res://assets/characters/adventurers/Knight.glb"
	corin.model_scale = Vector3(0.56, 0.56, 0.56)
	corin.model_rotation_y = 120.0
	corin.dialogue_text = "Welcome to Port Blackwater. Keep your weapons ready—corsairs brawl on the docks, and strange abominations crawl from the seabed. Check the harbor bounties to keep our port safe!"
	corin.position = Vector3(-53.0, 0.0, 52.0)
	parent.add_child(corin)

	# Interactive World Restoration Station: Harbor Cargo Crane
	var crane_station = WorldRepairStationScript.new()
	crane_station.repair_id = "port_crane"
	crane_station.station_name = "Harbor Cargo Crane"
	crane_station.required_materials = {"lumber": 1, "iron_ore": 1}
	crane_station.target_story_act = 2
	crane_station.gold_reward = 150
	crane_station.echo_reward = 50
	crane_station.position = Vector3(-64.0, 0.0, 62.0)
	var ruined_crane = _place_prop(parent, "res://assets/overworld/building_scaffolding.gltf", Vector3(-64.0, 0.0, 62.0), Vector3(2.5, 3.2, 2.5), 15.0)
	var restored_crane = _place_prop(parent, "res://assets/overworld/arch.gltf", Vector3(-64.0, 0.0, 62.0), Vector3(3.0, 4.0, 3.0), 0.0)
	_place_prop(restored_crane, "res://assets/overworld/flag_blue.gltf", Vector3(0.0, 4.2, 0.0), Vector3.ONE * 2.0)
	crane_station.ruined_node = ruined_crane
	crane_station.restored_node = restored_crane
	parent.add_child(crane_station)

	# 6. Enemies
	# Coastal Corsairs / Pirates
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-78.0, 0.0, 72.0), -60.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-70.0, 0.0, 85.0), 30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.PIRATE, Vector3(-84.0, 0.0, 62.0), 110.0)

	# Deep Sea Creeps (Amphibious coastal abominations)
	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(-88.0, 0.0, 92.0), 45.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.CREEP, Vector3(-96.0, 0.0, 78.0), -120.0)

	# 7. Quest Relic & Treasures
	# The Tidecaller's Compass (Key Story Quest Relic)
	_spawn_material_node(parent, "tidecaller_compass", "The Tidecaller's Compass", "🧭", "res://assets/items/quest_materials/Chalice.glb", Vector3(-98.0, 0.0, 84.0), Color(0.18, 0.75, 0.95), 80, 60, Vector3(2.2, 2.2, 2.2))
	# Sunken Smuggler's Loot
	_spawn_material_node(parent, "smugglers_chest", "Sunken Corsair Chest", "📦", "res://assets/items/quest_materials/Chest_Ingots.glb", Vector3(-85.0, 0.0, 82.0), Color(0.95, 0.8, 0.2), 60, 45, Vector3(1.6, 1.6, 1.6))

# =========================================================================
# REGION 2: WHISPERWOOD FOREST & SYLVA'S REST
# =========================================================================
func _build_whisperwood_forest_region(parent: Node3D) -> void:
	# 1. Ancient Dense Forest Canopy (X in [-120, -45], Z in [-120, -15])
	var f_trees = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/trees_B_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	var forest_coords = [
		Vector3(-55.0, 0.0, -35.0), Vector3(-62.0, 0.0, -42.0), Vector3(-68.0, 0.0, -32.0),
		Vector3(-58.0, 0.0, -50.0), Vector3(-65.0, 0.0, -58.0), Vector3(-72.0, 0.0, -48.0),
		Vector3(-80.0, 0.0, -42.0), Vector3(-88.0, 0.0, -52.0), Vector3(-95.0, 0.0, -40.0),
		Vector3(-78.0, 0.0, -78.0), Vector3(-85.0, 0.0, -85.0), Vector3(-92.0, 0.0, -75.0),
		Vector3(-100.0, 0.0, -55.0), Vector3(-105.0, 0.0, -68.0), Vector3(-110.0, 0.0, -45.0),
		Vector3(-102.0, 0.0, -85.0), Vector3(-112.0, 0.0, -78.0), Vector3(-115.0, 0.0, -95.0),
		Vector3(-60.0, 0.0, -80.0), Vector3(-68.0, 0.0, -90.0), Vector3(-75.0, 0.0, -100.0),
		Vector3(-88.0, 0.0, -102.0), Vector3(-98.0, 0.0, -108.0), Vector3(-110.0, 0.0, -112.0)
	]
	for i in range(forest_coords.size()):
		var f_pos = forest_coords[i]
		var t_model = f_trees[i % f_trees.size()]
		_place_prop(parent, t_model, f_pos, Vector3.ONE * 3.5, float((i * 43) % 360))
		_add_static_cyl(parent, f_pos, 1.2, 9.0)

	# Forest Fireflies & Atmospheric Spores
	AmbientFX.create_forest_fireflies(parent, Vector3(-78.0, 2.0, -62.0), 12.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(-92.0, 2.0, -75.0), 14.0)

	# 2. Sylva's Rest Enclave
	# Elder Druid's Stone Circle Shrine
	_place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-82.0, 0.0, -65.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-82.0, 0.0, -61.0), Vector3.ONE * 2.8)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-86.0, 0.0, -65.0), Vector3(1.8, 3.0, 1.8))
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-78.0, 0.0, -65.0), Vector3(1.8, 3.0, 1.8))
	_add_static_cyl(parent, Vector3(-86.0, 0.0, -65.0), 1.0, 9.0)
	_add_static_cyl(parent, Vector3(-78.0, 0.0, -65.0), 1.0, 9.0)

	# Ranger Outpost Cottage
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(-72.0, 0.0, -56.0), Vector3.ONE * 6.5, -45.0)
	_add_static_box(parent, Vector3(-72.0, 3.5, -56.0), Vector3(6.5, 7.0, 7.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(-72.0, 8.0, -56.0))

	# Woodland Sawmill
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-68.0, 0.0, -72.0), Vector3.ONE * 5.5, 90.0)
	_add_static_box(parent, Vector3(-68.0, 4.0, -72.0), Vector3(7.5, 6.5, 7.5))

	# 3. NPCs
	# Elder Thorne (Circle Druid)
	var thorne = TownNPCScript.new()
	thorne.npc_id = "druid_thorne"
	thorne.npc_name = "Elder Thorne"
	thorne.npc_title = "Circle Druid"
	thorne.icon = "🌿"
	thorne.model_path = "res://assets/characters/adventurers/Mage.glb"
	thorne.model_scale = Vector3(0.54, 0.54, 0.54)
	thorne.model_rotation_y = 45.0
	thorne.dialogue_text = "Peace be upon your spirit, traveler. Whisperwood Forest suffers under bandit outlaws who felled the sacred grove and severed the Living Heartwood. Drive back the highwaymen, return the Heartwood to the shrine, and receive nature's eternal rejuvenation!"
	thorne.position = Vector3(-80.0, 0.0, -63.0)
	parent.add_child(thorne)

	# Ranger Elora (Woodland Scout)
	var elora = TownNPCScript.new()
	elora.npc_id = "ranger_elora"
	elora.npc_name = "Ranger Elora"
	elora.npc_title = "Woodland Scout"
	elora.icon = "🏹"
	elora.model_path = "res://assets/characters/adventurers/Rogue.glb"
	elora.model_scale = Vector3(0.53, 0.53, 0.53)
	elora.model_rotation_y = 120.0
	elora.dialogue_text = "Tread lightly. Bandit outlaws and hungry timber wolves stalk the shadows of the pines. Clear the woods and our scouts will ensure your safe passage across the realm!"
	elora.position = Vector3(-70.0, 0.0, -54.0)
	parent.add_child(elora)

	# Interactive World Restoration Station: Druidic Sun Altar
	var altar_station = WorldRepairStationScript.new()
	altar_station.repair_id = "druid_altar"
	altar_station.station_name = "Whisperwood Sun Altar"
	altar_station.required_materials = {"arcane_crystal": 1, "emerald_crystal": 1}
	altar_station.target_story_act = 3
	altar_station.gold_reward = 150
	altar_station.echo_reward = 50
	altar_station.position = Vector3(-84.0, 0.0, -68.0)
	var ruined_altar = _place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-84.0, 0.0, -68.0), Vector3.ONE * 2.2, 45.0)
	var restored_altar = _place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-84.0, 0.0, -68.0), Vector3.ONE * 2.6, 45.0)
	var a_light = OmniLight3D.new()
	a_light.light_color = Color(0.2, 1.0, 0.4)
	a_light.light_energy = 2.2
	a_light.omni_range = 8.0
	a_light.position.y = 1.8
	restored_altar.add_child(a_light)
	altar_station.ruined_node = ruined_altar
	altar_station.restored_node = restored_altar
	parent.add_child(altar_station)

	# 4. Enemies & Wildlife
	# Forest Bandits
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-92.0, 0.0, -48.0), 60.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-102.0, 0.0, -62.0), -30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.BANDIT, Vector3(-86.0, 0.0, -82.0), 140.0)

	# Wild Timber Wolf Pack
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-98.0, 0.0, -78.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-106.0, 0.0, -84.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-75.0, 0.0, -45.0), 90.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-78.0, 0.0, -48.0), -45.0)

	# 5. Quest Relic & Nodes
	# The Living Heartwood (Key Story Quest Relic)
	_spawn_material_node(parent, "living_heartwood", "The Living Heartwood", "🌱", "res://assets/overworld/resource_lumber.gltf", Vector3(-89.0, 0.0, -72.0), Color(0.25, 0.88, 0.35), 80, 60, Vector3(3.0, 3.0, 3.0))
	_spawn_material_node(parent, "heartwood_timber", "Ancient Ironwood", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-95.0, 0.0, -55.0), Color(0.8, 0.5, 0.2), 30, 20, Vector3(2.5, 2.5, 2.5))

# =========================================================================
# REGION 3: KHAR-DRAKKEN CRAGS & ORC BASTION
# =========================================================================
func _build_khar_drakken_crags_region(parent: Node3D) -> void:
	# 1. Towering Mountain Massifs (X in [50, 120], Z in [-120, -10])
	var crag_peaks = [
		{"pos": Vector3(58.0, 0.0, -40.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 10.0},
		{"pos": Vector3(70.0, 0.0, -32.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 11.0},
		{"pos": Vector3(88.0, 0.0, -42.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 11.5},
		{"pos": Vector3(65.0, 0.0, -75.0), "path": "res://assets/overworld/mountain_A_grass.gltf", "scale": 10.5},
		{"pos": Vector3(82.0, 0.0, -85.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 12.0},
		{"pos": Vector3(100.0, 0.0, -65.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 11.0},
		{"pos": Vector3(112.0, 0.0, -85.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 12.0},
		{"pos": Vector3(92.0, 0.0, -112.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 12.5},
		{"pos": Vector3(110.0, 0.0, -110.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 12.0}
	]
	for cp in crag_peaks:
		_place_prop(parent, cp["path"], cp["pos"], Vector3.ONE * cp["scale"])
		_add_static_box(parent, cp["pos"] + Vector3(0, 7.0, 0), Vector3(cp["scale"] * 2.2, 14.0, cp["scale"] * 2.2))

	# 2. Stonegate Dwarven Mining Settlement (X = 72, Z = -55)
	# Ancestral Deep Mine Shaft
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(74.0, 0.0, -52.0), Vector3.ONE * 6.0, -90.0)
	_add_static_box(parent, Vector3(74.0, 3.5, -52.0), Vector3(8.0, 6.5, 8.0))

	# Mountain Watchtower
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(62.0, 0.0, -42.0), Vector3.ONE * 8.5)
	_add_static_box(parent, Vector3(62.0, 6.0, -42.0), Vector3(4.5, 12.0, 4.5))

	# Dwarven Forge Pavilion
	_place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(70.0, 0.0, -62.0), Vector3.ONE * 2.5, 90.0)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(68.0, 0.0, -60.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(72.0, 0.0, -62.0), Vector3.ONE * 2.0)
	AmbientFX.create_chimney_smoke(parent, Vector3(70.0, 4.0, -62.0))

	# 3. The Orc Stronghold & Bastion (Upper Plateau: X in [92, 110], Z in [-85, -110])
	var OverworldGateScript = preload("res://src/world/OverworldGate.gd")
	var orc_gate = OverworldGateScript.new()
	orc_gate.position = Vector3(94.0, 0.0, -88.0)
	orc_gate.rotation_degrees.y = 45.0
	parent.add_child(orc_gate)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(89.0, 0.0, -85.0), Vector3(3.5, 4.0, 2.5), 45.0)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(99.0, 0.0, -91.0), Vector3(3.5, 4.0, 2.5), 45.0)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(93.0, 0.0, -86.0), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/bone_A.gltf", Vector3(96.0, 0.0, -87.0), Vector3.ONE * 2.0)

	# 4. NPCs
	# Torvald Ironbreaker (Runesmith)
	var torv = TownNPCScript.new()
	torv.npc_id = "runesmith_torvald"
	torv.npc_name = "Torvald Ironbreaker"
	torv.npc_title = "Highland Runesmith"
	torv.icon = "⛏️"
	torv.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torv.model_scale = Vector3(0.40, 0.40, 0.40)
	torv.model_rotation_y = 60.0
	torv.dialogue_text = "By the thunder of stone! The Orc Warlords have seized our upper stronghold and stolen the Runebound Mountain Core! Cleave through their ranks, return the Core, and I shall temper your weapons with ancient dwarven runes!"
	torv.position = Vector3(69.0, 0.0, -58.0)
	parent.add_child(torv)

	# Interactive World Restoration Station: Smelter Blast Bellows
	var bellows_station = WorldRepairStationScript.new()
	bellows_station.repair_id = "smelter_bellows"
	bellows_station.station_name = "Smelter Blast Bellows"
	bellows_station.required_materials = {"gold_vein": 1, "iron_ore": 1}
	bellows_station.target_story_act = 4
	bellows_station.gold_reward = 180
	bellows_station.echo_reward = 60
	bellows_station.position = Vector3(73.0, 0.0, -56.0)
	var ruined_bellows = _place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(73.0, 0.0, -56.0), Vector3.ONE * 2.2, -30.0)
	var restored_bellows = _place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(73.0, 0.0, -56.0), Vector3.ONE * 2.6, -30.0)
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

	# 5. Enemies
	# Orc Berserkers
	_spawn_enemy(parent, EnemyAI.EnemyType.ORC, Vector3(98.0, 0.0, -94.0), -45.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.ORC, Vector3(105.0, 0.0, -104.0), 120.0)

	# Mountain Demons / Cliff Lurkers
	_spawn_enemy(parent, EnemyAI.EnemyType.DEMON, Vector3(88.0, 0.0, -96.0), 30.0)
	_spawn_enemy(parent, EnemyAI.EnemyType.DEMON, Vector3(104.0, 0.0, -88.0), -110.0)

	# 6. Quest Relic & Minerals
	# The Runebound Mountain Core (Key Story Quest Relic)
	_spawn_material_node(parent, "runebound_core", "Runebound Mountain Core", "⛰️", "res://assets/items/quest_materials/Crystal1.glb", Vector3(106.0, 0.0, -108.0), Color(1.0, 0.55, 0.15), 100, 75, Vector3(2.2, 2.2, 2.2))
	# High Mountain Gold & Ore Veins
	_spawn_material_node(parent, "gold_vein", "High Crag Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(78.0, 0.0, -68.0), Color(1.0, 0.85, 0.2), 40, 35, Vector3(1.5, 1.5, 1.5))
	_spawn_material_node(parent, "emerald_crystal", "Mountain Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(84.0, 0.0, -76.0), Color(0.2, 1.0, 0.4), 35, 30, Vector3(1.8, 1.8, 1.8))

# =========================================================================
# CROSSROADS, HIGHROADS & WAYSTONE NETWORK
# =========================================================================
func _build_crossroads_and_highroads(parent: Node3D) -> void:
	# 1. Central Crossroads Waystone Signpost (Near Tavern & West Highway at X = -12.0, Z = 14.0)
	var sign_cross = TownNPCScript.new()
	sign_cross.npc_id = "signpost_crossroads"
	sign_cross.npc_name = "Kingdom Crossroads Waystone"
	sign_cross.npc_title = "Fast Travel & Directions"
	sign_cross.icon = "🪧"
	sign_cross.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_cross.model_scale = Vector3.ONE * 1.2
	sign_cross.dialogue_text = "Kingdom Crossroad Waystone:\n• South-West: Port Blackwater (Harbor, Ships & Ocean)\n• North-West: Whisperwood Forest (Druidic Enclave)\n• North-East: Khar-Drakken Crags (Dwarven Mines & Orcs)\n• Central: Oakhaven Town (Castle & Catacombs)"
	sign_cross.position = Vector3(-12.0, 0.0, 14.0)
	parent.add_child(sign_cross)
	_place_lantern_post(parent, Vector3(-12.0, 0.0, 14.0))

	# 2. Port Blackwater Waystone Signpost
	var sign_port = TownNPCScript.new()
	sign_port.npc_id = "signpost_port"
	sign_port.npc_name = "Port Blackwater Waystone"
	sign_port.npc_title = "Fast Travel & Directions"
	sign_port.icon = "⚓"
	sign_port.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_port.model_scale = Vector3.ONE * 1.2
	sign_port.dialogue_text = "Port Blackwater Harbor Waystone.\nFast Travel to other unlocked settlements in the realm."
	sign_port.position = Vector3(-50.0, 0.0, 56.0)
	parent.add_child(sign_port)
	_place_lantern_post(parent, Vector3(-50.0, 0.0, 56.0))

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
	_place_lantern_post(parent, Vector3(-66.0, 0.0, -52.0))

	# 4. Khar-Drakken Waystone Signpost
	var sign_crag = TownNPCScript.new()
	sign_crag.npc_id = "signpost_crags"
	sign_crag.npc_name = "Khar-Drakken Waystone"
	sign_crag.npc_title = "Fast Travel & Directions"
	sign_crag.icon = "⛰️"
	sign_crag.model_path = "res://assets/overworld/post_lantern.gltf"
	sign_crag.model_scale = Vector3.ONE * 1.2
	sign_crag.dialogue_text = "Khar-Drakken Mountain Waystone (Stonegate Outpost).\nFast Travel to other unlocked settlements in the realm."
	sign_crag.position = Vector3(60.0, 0.0, -46.0)
	parent.add_child(sign_crag)
	_place_lantern_post(parent, Vector3(60.0, 0.0, -46.0))

	# 5. Cobblestone / Dirt Road Segments linking Regions
	# South-West Coastal Highroad (winds from X = -18, Z = 16 toward X = -50, Z = 55)
	for step in range(1, 16):
		var alpha = float(step) / 16.0
		var rx = lerp(-18.0, -50.0, alpha)
		var rz = lerp(16.0, 55.0, alpha)
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(rx, 0.02, rz), Vector3(1.2, 1.0, 1.2))

	# North-West Pilgrim Trail (winds from X = -34, Z = -4 toward X = -66, Z = -52)
	for step in range(1, 15):
		var alpha = float(step) / 15.0
		var rx = lerp(-34.0, -66.0, alpha)
		var rz = lerp(-4.0, -52.0, alpha)
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", Vector3(rx, 0.02, rz), Vector3(2.2, 1.0, 2.2))

	# North-East Mountain Pass (winds from X = 34, Z = -22 toward X = 60, Z = -46)
	for step in range(1, 14):
		var alpha = float(step) / 14.0
		var rx = lerp(34.0, 60.0, alpha)
		var rz = lerp(-22.0, -46.0, alpha)
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", Vector3(rx, 0.02, rz), Vector3(2.2, 1.0, 2.2))
