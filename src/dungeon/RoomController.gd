extends Node3D
class_name RoomController

const LootChestScript = preload("res://src/dungeon/LootChest.gd")
const UpgradeAltarScript = preload("res://src/dungeon/UpgradeAltar.gd")
const ClassPedestalScript = preload("res://src/dungeon/ClassPedestal.gd")
const BossWardenScript = preload("res://src/actors/BossWarden.gd")
const EnemyAIScript = preload("res://src/actors/EnemyAI.gd")
const DescentSigilScript = preload("res://src/dungeon/DescentSigil.gd")

signal room_cleared()

@export var is_hub_room: bool = false
@export var is_boss_room: bool = false
@export var enemy_wave_count: int = 1

var alive_enemies: Array[Node3D] = []
var is_combat_active: bool = false
var has_cleared: bool = false

var exit_portal: Area3D = null
var chest_spawn_point: Vector3 = Vector3.ZERO
var enemy_spawn_points: Array[Vector3] = []

func _ready() -> void:
	if is_hub_room:
		_setup_hub_interactables()
	elif is_boss_room:
		_setup_boss_encounter()
	else:
		_setup_chamber_encounter()

func _setup_hub_interactables() -> void:
	# Hub has hero class pedestals, Upgrade Altar, and Descent Sigil
	_spawn_descent_sigil(Vector3(0, 0, 7.0))
	_spawn_upgrade_altar(Vector3(-5.0, 0, 0))
	_spawn_class_pedestals(Vector3(0, 0, -4.0))

func _setup_chamber_encounter() -> void:
	# Define spawn points inside room
	enemy_spawn_points = [
		Vector3(-5.0, 0, -5.0),
		Vector3(5.0, 0, -5.0),
		Vector3(-5.0, 0, 5.0),
		Vector3(5.0, 0, 5.0),
		Vector3(0.0, 0, -6.0)
	]
	chest_spawn_point = Vector3(0, 0, 0)
	
	# Create entry trigger zone
	var entry_trigger = Area3D.new()
	entry_trigger.name = "EntryTrigger"
	entry_trigger.collision_layer = 0
	entry_trigger.collision_mask = 1 << 1 # Player
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(16.0, 4.0, 16.0)
	col.shape = box
	entry_trigger.add_child(col)
	add_child(entry_trigger)
	entry_trigger.body_entered.connect(_on_player_entered_room)

func _setup_boss_encounter() -> void:
	chest_spawn_point = Vector3(0, 0, 0)
	# Spawns boss immediately or when entered
	var boss_scene = load("res://scenes/BossWarden.tscn")
	var boss = null
	if boss_scene:
		boss = boss_scene.instantiate()
	else:
		boss = BossWardenScript.new()
		
	add_child(boss)
	boss.position = Vector3(0, 0, -8.0)
	alive_enemies.append(boss)
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_slain)

func _on_player_entered_room(body: Node3D) -> void:
	if body.is_in_group("player") and not is_combat_active and not has_cleared:
		is_combat_active = true
		_start_wave()

func _start_wave() -> void:
	var floor_num = GameManager.current_floor
	var enemy_count = 3 + floor_num
	var enemy_scene = load("res://scenes/EnemySkeleton.tscn")
	
	for i in range(enemy_count):
		var spawn_pos = enemy_spawn_points[i % enemy_spawn_points.size()]
		spawn_pos += Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		
		var enemy = null
		if enemy_scene:
			enemy = enemy_scene.instantiate()
		else:
			enemy = EnemyAIScript.new()
			
		# Determine enemy type distribution based on floor
		if i == 0 and floor_num >= 2:
			enemy.enemy_type = EnemyAIScript.EnemyType.WARRIOR
		elif i == 1 and floor_num >= 3:
			enemy.enemy_type = EnemyAIScript.EnemyType.ROGUE
		elif i == 2 and floor_num >= 4:
			enemy.enemy_type = EnemyAIScript.EnemyType.MAGE
		else:
			enemy.enemy_type = EnemyAIScript.EnemyType.MINION
			
		enemy.position = spawn_pos
		add_child(enemy)
		alive_enemies.append(enemy)
		enemy.character_died.connect(_on_enemy_died.bind(enemy))
		
		# Summon rune effect
		CombatJuice.spawn_hit_spark(spawn_pos + Vector3(0, 0.5, 0), Color(0.1, 0.9, 0.8))

func _on_enemy_died(enemy: Node3D) -> void:
	alive_enemies.erase(enemy)
	if alive_enemies.is_empty() and not has_cleared:
		_on_chamber_cleared()

func _on_chamber_cleared() -> void:
	has_cleared = true
	is_combat_active = false
	room_cleared.emit()
	GameManager.advance_chamber()
	
	AudioManager.play_sfx("chest_open", 0.05, 1.0)
	CombatJuice.add_trauma(0.2)
	
	# Spawn Loot Chest
	var chest = LootChestScript.new()
	chest.name = "LootChest"
	chest.position = chest_spawn_point
	add_child(chest)
	
	# Spawn Exit Descent Sigil
	_spawn_descent_sigil(Vector3(0, 0, 8.5))

func _on_boss_slain() -> void:
	has_cleared = true
	GameManager.record_boss_slain()
	# Spawns Grand Trophy Chest & Sanctuary Return Portal
	var chest = LootChestScript.new()
	chest.gold_amount = 200
	chest.position = Vector3(0, 0, 0)
	add_child(chest)
	_spawn_return_portal(Vector3(0, 0, 6.0))

# --- INTERACTABLE OBJECT SPAWNERS ---
func _spawn_descent_sigil(pos: Vector3) -> void:
	var sigil = DescentSigilScript.new()
	sigil.position = pos
	add_child(sigil)

func _spawn_return_portal(pos: Vector3) -> void:
	var portal = Area3D.new()
	portal.name = "ReturnPortal"
	portal.collision_layer = 1 << 5
	portal.position = pos
	
	var mesh = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = 1.2
	tor.outer_radius = 1.6
	mesh.mesh = tor
	mesh.rotation_degrees.x = 90.0
	mesh.position.y = 1.8
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.7, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.1)
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	portal.add_child(mesh)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5, 3.0, 2.5)
	col.shape = shape
	portal.add_child(col)
	
	var label = Label3D.new()
	label.text = "[E] Return to Sanctuary"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 3.2
	portal.add_child(label)
	
	# Dynamic interaction method
	portal.set_meta("action", "return_to_sanctuary")
	add_child(portal)

func _spawn_upgrade_altar(pos: Vector3) -> void:
	var altar = UpgradeAltarScript.new()
	altar.name = "UpgradeAltar"
	altar.position = pos
	
	# Altar Stone plinth
	var base = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 1.2, 1.6)
	base.mesh = box
	base.position.y = 0.6
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.25)
	mat.roughness = 0.9
	base.material_override = mat
	altar.add_child(base)
	
	# Floating soul flame brazier
	var flame = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	flame.mesh = sphere
	flame.position.y = 1.6
	
	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(0.1, 0.9, 0.8)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(0.1, 0.9, 0.8)
	flame_mat.emission_energy_multiplier = 3.5
	flame.material_override = flame_mat
	altar.add_child(flame)
	
	var area = Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 1 << 5 # Interactable
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.8, 2.8, 2.8)
	col.shape = shape
	col.position.y = 1.0
	area.add_child(col)
	altar.add_child(area)
	
	var label = Label3D.new()
	label.text = "[E] Soul Altar"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.4
	label.font_size = 30
	altar.add_child(label)
	
	add_child(altar)

func _spawn_class_pedestals(base_pos: Vector3) -> void:
	var classes = [
		{"type": GameManager.HeroClass.KNIGHT, "name": "Knight", "offset": Vector3(-4.5, 0, 0)},
		{"type": GameManager.HeroClass.ROGUE, "name": "Rogue", "offset": Vector3(-1.5, 0, 0)},
		{"type": GameManager.HeroClass.MAGE, "name": "Mage", "offset": Vector3(1.5, 0, 0)},
		{"type": GameManager.HeroClass.BARBARIAN, "name": "Barbarian", "offset": Vector3(4.5, 0, 0)}
	]
	
	for c in classes:
		var ped = ClassPedestalScript.new()
		ped.name = "Pedestal_" + c["name"]
		ped.hero_class = c["type"]
		ped.position = base_pos + c["offset"]
		
		# Stone Pedestal
		var base = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.8
		cyl.bottom_radius = 0.9
		cyl.height = 0.4
		base.mesh = cyl
		base.position.y = 0.2
		ped.add_child(base)
		
		var area = Area3D.new()
		area.name = "InteractArea"
		area.collision_layer = 1 << 5
		area.collision_mask = 0
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 1.4
		shape.height = 2.0
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		ped.add_child(area)
		
		# Floating Miniature Hero Preview
		var preview = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/" + c["name"] + ".glb", "character", c["name"])
		preview.scale = Vector3(0.65, 0.65, 0.65)
		preview.position.y = 0.45
		ped.add_child(preview)
		
		var label = Label3D.new()
		label.text = "[E] " + c["name"]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 1.9
		label.font_size = 26
		ped.add_child(label)
		
		add_child(ped)
