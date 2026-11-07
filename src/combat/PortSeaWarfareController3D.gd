extends Node3D
class_name PortSeaWarfareController3D

const BattlegroundTroopAIScript = preload("res://src/combat/BattlegroundTroopAI.gd")
const EnemyNavalShip3DScript = preload("res://src/world/EnemyNavalShip3D.gd")

signal sea_battle_started()
signal sea_battle_victory()

@export var auto_hud_distance: float = 56.0

var port_marines: Array = []
var sea_invaders: Array = []
var invading_warships: Array = []
var coastal_cannons: Array = []

var _total_marines_spawned: int = 14
var _total_invaders_spawned: int = 16
var is_battle_active: bool = false
var is_victory_achieved: bool = false
var current_wave: int = 1

var _hero_player: Node3D = null
var _hud_layer: CanvasLayer = null
var _hud_container: Control = null
var _marine_count_label: Label = null
var _invader_count_label: Label = null
var _banner_label: Label = null
var _banner_timer: float = 0.0
var _cannon_exchange_timer: float = 5.5
var _victory_chest: Node3D = null

func _ready() -> void:
	add_to_group("port_sea_warfare")
	add_to_group("interactable")

	_build_port_coastal_defenses_and_landing_boats()
	_build_naval_war_horn()
	_build_sea_warfare_hud()
	spawn_port_sea_battle()

func _build_port_coastal_defenses_and_landing_boats() -> void:
	# 1. Hero's Port Fortifications & Coastal Cannon Batteries along the Quay & Beach (Local X ≈ +2 to +8)
	_place_local_prop("res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(6.0, 0.0, -14.0), Vector3.ONE * 6.8, -90.0)
	_place_local_prop("res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(6.0, 0.0, 18.0), Vector3.ONE * 6.8, -90.0)

	# 4 Coastal Artillery Cannons aimed West toward the Sea & Landing Beach
	for cz in [-10.0, -3.0, 5.0, 13.0]:
		var c_base = _place_local_prop("res://assets/overworld/pallet.gltf", Vector3(3.5, 0.0, cz), Vector3(1.6, 1.2, 1.6))
		var cannon = _place_local_prop("res://assets/ships/cannon.glb", Vector3(3.2, 0.25, cz), Vector3.ONE * 2.2, -90.0)
		coastal_cannons.append(cannon)
		_place_local_prop("res://assets/overworld/flag_blue.gltf", Vector3(4.5, 0.0, cz + 1.8), Vector3.ONE * 2.0, -90.0)

	# Defensive timber barricades & munition crates along the Port Quay
	for bz in [-12.0, -6.0, 8.0, 15.0]:
		_place_local_prop("res://assets/overworld/fence_wood_straight.gltf", Vector3(1.5, 0.0, bz), Vector3.ONE * 2.0, 0.0)
	_place_local_prop("res://assets/overworld/weaponrack.gltf", Vector3(5.0, 0.0, -1.0), Vector3.ONE * 1.7, 0.0)
	_place_local_prop("res://assets/overworld/barrel.gltf", Vector3(4.8, 0.0, 2.0), Vector3.ONE * 1.3, 0.0)

	# 2. Invading Amphibious Assault Landing Boats beached on the shoreline (Local X ≈ -11.0)
	for lz in [-11.0, -2.0, 7.0, 16.0]:
		_place_local_prop("res://assets/ships/boat-row-large.glb", Vector3(-11.5, -0.15, lz), Vector3.ONE * 2.1, 82.0 + randf_range(-8.0, 8.0))
		_place_local_prop("res://assets/overworld/flag_red.gltf", Vector3(-9.5, 0.0, lz + 1.2), Vector3.ONE * 2.0, 90.0)

	# 3. Offshore Invading Sea Armada Warships (Local X ≈ -32.0 to -42.0 in deeper water)
	var ship_configs = [
		{"name": "Dread Flagship Kraken's Maw", "pos": Vector3(-36.0, -0.3, -12.0), "rot": 75.0},
		{"name": "Corsair Frigate Blood-Tide", "pos": Vector3(-40.0, -0.3, 4.0), "rot": 92.0},
		{"name": "Sea-Raider Galleon Iron-Reef", "pos": Vector3(-35.0, -0.3, 20.0), "rot": 105.0}
	]
	for sc in ship_configs:
		var w_ship = EnemyNavalShip3DScript.new()
		w_ship.ship_name = sc["name"]
		w_ship.max_health = 240.0
		w_ship.position = sc["pos"]
		w_ship.rotation_degrees.y = sc["rot"]
		add_child(w_ship)
		invading_warships.append(w_ship)

func _place_local_prop(model_path: String, local_pos: Vector3, scale_v: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0) -> Node3D:
	var prop = AssetLoader.load_or_generate_model(model_path, "dungeon", "port_battle_prop")
	prop.position = local_pos
	prop.scale = scale_v
	prop.rotation_degrees.y = rot_y_deg
	add_child(prop)
	return prop

func _build_naval_war_horn() -> void:
	var horn_root = Node3D.new()
	horn_root.name = "PortNavalWarHorn"
	horn_root.position = Vector3(4.5, 0.0, 0.0)
	add_child(horn_root)

	var ped = AssetLoader.load_or_generate_model("res://assets/overworld/pillar.gltf", "dungeon", "port_horn_pedestal")
	ped.scale = Vector3(0.7, 1.1, 0.7)
	horn_root.add_child(ped)

	var horn_lbl = Label3D.new()
	horn_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	horn_lbl.position = Vector3(0.0, 1.85, 0.0)
	horn_lbl.pixel_size = 0.006
	horn_lbl.visibility_range_end = 24.0
	horn_lbl.modulate = Color(0.45, 0.92, 1.0)
	horn_lbl.text = "⚓ Port Naval Defense Horn\n[E] Sound Horn to Rally Port Marines & Cannons"
	horn_root.add_child(horn_lbl)

	var area = Area3D.new()
	area.name = "PortHornInteractArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.5, 2.5, 3.5)
	col.shape = box
	col.position.y = 1.0
	area.add_child(col)
	horn_root.add_child(area)
	area.add_to_group("interactable")
	area.set_meta("interaction_target", self)

func spawn_port_sea_battle() -> void:
	_cleanup_port_troops()
	is_battle_active = true
	is_victory_achieved = false

	# 1. Hero's Port Marine Garrison (14 Units defending the Quay & Beachhead at X ≈ +1.0 to +4.5)
	_spawn_port_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.COMMANDER, "High Admiral Marcus", Vector3(3.5, 0.0, 1.5), Vector3(1.0, 0.0, 0.0))

	for mz in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.KNIGHT, "Royal Port Marine", Vector3(1.0, 0.0, mz), Vector3(0.0, 0.0, mz * 0.2))

	for hz in [-6.5, -2.0, 2.5, 7.0]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.BERSERKER, "Harbor Guard Halberdier", Vector3(2.2, 0.0, hz), Vector3(0.5, 0.0, hz * 0.2))

	for az in [-7.5, -2.5, 2.5, 7.5]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.ARCHER, "Quay Longbowman", Vector3(4.2, 0.0, az), Vector3(1.5, 0.0, az * 0.2))

	# 2. Invading Sea Raider Army (16 Units storming from the Beached Longboats at X ≈ -9.0 to -5.5)
	_spawn_port_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.COMMANDER, "Corsair Fleet-Lord Varkas", Vector3(-9.5, 0.0, 1.5), Vector3(-1.0, 0.0, 0.0))

	for cz in [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.KNIGHT, "Corsair Sea Raider", Vector3(-6.0, 0.0, cz), Vector3(0.0, 0.0, cz * 0.2))

	for bz in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.BERSERKER, "Sea-Wolf Reaver", Vector3(-7.8, 0.0, bz), Vector3(-0.5, 0.0, bz * 0.2))

	for rz in [-7.5, -2.5, 2.5, 7.5]:
		_spawn_port_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.ARCHER, "Corsair Deck Arbalest", Vector3(-9.8, 0.0, rz), Vector3(-1.5, 0.0, rz * 0.2))

	_total_marines_spawned = port_marines.size()
	_total_invaders_spawned = sea_invaders.size()

	sea_battle_started.emit()
	show_sea_banner("⚓ PORT BLACKWATER SEA WARFARE! [1] Repel Beachhead [2] Quay Shield Wall [3] Rally [4] Bowmen [5] Coastal Cannons!", 4.5)

func _spawn_port_troop(f: int, r: int, t_name: String, local_pos: Vector3, form_offset: Vector3) -> Node:
	var troop = BattlegroundTroopAIScript.new()
	troop.faction = f
	troop.role = r
	troop.unit_name = t_name
	troop.custom_royal_group = "port_royal_army"
	troop.custom_crimson_group = "port_invader_army"
	troop.position = local_pos
	troop.home_formation_pos = global_position + local_pos
	troop.formation_offset = form_offset
	troop.unit_died.connect(_on_port_troop_died)
	add_child(troop)

	if f == BattlegroundTroopAIScript.Faction.ROYAL:
		port_marines.append(troop)
	else:
		sea_invaders.append(troop)
	return troop

func _cleanup_port_troops() -> void:
	for m in port_marines:
		if is_instance_valid(m):
			m.queue_free()
	port_marines.clear()

	for s in sea_invaders:
		if is_instance_valid(s):
			s.queue_free()
	sea_invaders.clear()

	if is_instance_valid(_victory_chest):
		_victory_chest.queue_free()
		_victory_chest = null

func _on_port_troop_died(dead_unit: Node) -> void:
	if dead_unit.faction == BattlegroundTroopAIScript.Faction.CRIMSON:
		sea_invaders.erase(dead_unit)
		if count_alive_invaders() == 0 and not is_victory_achieved:
			_trigger_sea_victory()
	else:
		port_marines.erase(dead_unit)

func count_alive_marines() -> int:
	var count = 0
	for m in port_marines:
		if is_instance_valid(m) and m.current_state != BattlegroundTroopAIScript.State.DEAD:
			count += 1
	return count

func count_alive_invaders() -> int:
	var count = 0
	for s in sea_invaders:
		if is_instance_valid(s) and s.current_state != BattlegroundTroopAIScript.State.DEAD:
			count += 1
	return count

func _process(delta: float) -> void:
	if not _hero_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_hero_player = players[0]

	var dist = 999.0
	if is_instance_valid(_hero_player):
		dist = global_position.distance_to(_hero_player.global_position)

	var is_near = dist < auto_hud_distance and (not _hero_player.get("is_captaining_ship"))
	if _hud_container:
		_hud_container.visible = is_near

	if is_near:
		_process_port_commands()
		_cannon_exchange_timer -= delta
		if _cannon_exchange_timer <= 0.0 and not is_victory_achieved:
			_cannon_exchange_timer = 6.5
			_fire_ship_and_shore_exchange()

	_banner_timer = max(0.0, _banner_timer - delta)
	if _banner_label and _banner_timer <= 0.0:
		_banner_label.text = ""

	_update_sea_hud_tallies()

func _process_port_commands() -> void:
	if Input.is_key_pressed(KEY_1):
		command_marines_charge()
	elif Input.is_key_pressed(KEY_2):
		command_marines_shield_wall()
	elif Input.is_key_pressed(KEY_3):
		command_marines_rally()
	elif Input.is_key_pressed(KEY_4):
		command_marines_volley()
	elif Input.is_key_pressed(KEY_5):
		command_coastal_cannon_barrage()

func command_marines_charge() -> void:
	show_sea_banner("⚓ ORDER: STORM THE BEACHHEAD! Port Marines charging the sea raiders!", 2.5)
	AudioManager.play_sfx("horn_rally", 0.08, 1.1)
	for m in port_marines:
		if is_instance_valid(m):
			m.command_charge()

func command_marines_shield_wall() -> void:
	show_sea_banner("🛡️ ORDER: QUAY SHIELD WALL! Holding the harbor piers (-75% Dmg)!", 2.5)
	AudioManager.play_sfx("parry_ring", 0.05, 1.2)
	for m in port_marines:
		if is_instance_valid(m):
			m.command_shield_wall()

func command_marines_rally() -> void:
	show_sea_banner("📯 ORDER: RALLY TO ADMIRAL HERO! Port Marines forming around you!", 2.5)
	AudioManager.play_sfx("horn_rally", 0.06, 1.25)
	for m in port_marines:
		if is_instance_valid(m):
			m.command_rally(_hero_player if _hero_player else self)

func command_marines_volley() -> void:
	show_sea_banner("🏹 ORDER: QUAY LONGBOW VOLLEY! Raining arrows on the landing boats!", 2.5)
	AudioManager.play_sfx("bow_shoot", 0.06, 1.0)
	var beach_center = global_position + Vector3(-8.0, 0.0, 0.0)
	for m in port_marines:
		if is_instance_valid(m):
			m.command_volley(beach_center)

func command_coastal_cannon_barrage() -> void:
	show_sea_banner("💥⚓ ORDER: COASTAL CANNON BROADSIDE! Bombard the Invading Armada & Beachhead!", 3.0)
	AudioManager.play_sfx("boulder_explosion", 0.08, 0.8)
	_spawn_coastal_artillery_salvo(true)

func _fire_ship_and_shore_exchange() -> void:
	if count_alive_invaders() > 0:
		_spawn_coastal_artillery_salvo(false)
	if count_alive_marines() > 0:
		_spawn_coastal_artillery_salvo(true)

func _spawn_coastal_artillery_salvo(from_port_defenses: bool) -> void:
	if not is_inside_tree():
		return
	var start_x = 3.2 if from_port_defenses else -32.0
	var target_x = -8.0 if from_port_defenses else 2.0
	for z_off in [-8.0, 6.0]:
		var ball = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.36
		sp.height = 0.72
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.65, 0.18) if from_port_defenses else Color(0.95, 0.28, 0.12)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 2.2
		sp.material = mat
		ball.mesh = sp
		add_child(ball)
		ball.position = Vector3(start_x, 2.4, z_off)

		var dest = Vector3(target_x + randf_range(-2.5, 2.5), 0.4, z_off + randf_range(-4.0, 4.0))
		var b_wr = weakref(ball)
		var self_wr = weakref(self)
		var tw = ball.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ball, "position:x", dest.x, 0.85)
		tw.tween_property(ball, "position:z", dest.z, 0.85)
		tw.tween_property(ball, "position:y", 7.8, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(ball, "position:y", dest.y, 0.43).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func():
			var b = b_wr.get_ref()
			if b:
				b.queue_free()
			var s = self_wr.get_ref()
			if s:
				var world_hit = s.global_position + dest
				AudioManager.play_sfx_at_position("cannon_impact", world_hit, 42.0, 0.1, 0.0)
				CombatJuice.spawn_hit_spark(world_hit, Color(1.0, 0.6, 0.2))
				var targets = s.sea_invaders if from_port_defenses else s.port_marines
				for unit in targets:
					if is_instance_valid(unit) and unit.current_state != BattlegroundTroopAIScript.State.DEAD:
						if unit.global_position.distance_to(world_hit) < 4.8:
							unit.take_damage(30.0, s)
				if from_port_defenses:
					for ship in s.invading_warships:
						if is_instance_valid(ship) and ship.has_method("take_naval_damage"):
							ship.take_naval_damage(25.0, s)
		)

func show_sea_banner(msg: String, duration: float = 2.5) -> void:
	if _banner_label:
		_banner_label.text = msg
		_banner_timer = duration

func _trigger_sea_victory() -> void:
	is_victory_achieved = true
	sea_battle_victory.emit()
	show_sea_banner("⚓ VICTORY AT PORT BLACKWATER! The Invading Sea Armada is Repelled! (+350 Gold, +150 Echoes, +240 XP)", 5.5)
	AudioManager.play_sfx("horn_rally", 0.02, 2.2)

	GameManager.add_gold(350)
	GameManager.add_echoes(150)
	GameManager.add_hero_xp(240)
	GameManager.complete_campaign_step_by_id("chapter_3_port_sea_warfare")

	_spawn_sea_victory_chest()

func _spawn_sea_victory_chest() -> void:
	if is_instance_valid(_victory_chest):
		return
	var chest = AssetLoader.load_or_generate_model("res://assets/overworld/crate_A_big.gltf", "dungeon", "sea_victory_chest")
	chest.position = Vector3(2.5, 0.0, 0.0)
	chest.scale = Vector3.ONE * 2.0
	add_child(chest)
	_victory_chest = chest

	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.1, 0.0)
	lbl.pixel_size = 0.006
	lbl.modulate = Color(0.45, 0.95, 1.0)
	lbl.text = "⚓ Admiral's Naval Spoils\n[Claimed: +350 Gold, +150 Echoes]"
	chest.add_child(lbl)

func interact(_player: Node = null) -> void:
	AudioManager.play_sfx("horn_rally", 0.05, 1.4)
	current_wave += 1
	spawn_port_sea_battle()
	show_sea_banner("⚓ PORT NAVAL WAR HORN SOUNDS! Wave %d Amphibious Assault Engaged!" % current_wave, 3.5)

func _build_sea_warfare_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "PortSeaWarfareHUD"
	add_child(_hud_layer)

	_hud_container = Control.new()
	_hud_container.name = "SeaHUDContainer"
	_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.visible = false
	_hud_layer.add_child(_hud_container)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_top = 60.0
	panel.offset_left = -265.0
	panel.offset_right = 265.0
	panel.offset_bottom = 96.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tally_sb = StyleBoxFlat.new()
	tally_sb.bg_color = Color(0.06, 0.08, 0.13, 0.90)
	tally_sb.border_color = Color(0.35, 0.80, 0.98, 0.85)
	tally_sb.set_border_width_all(1)
	tally_sb.set_corner_radius_all(6)
	tally_sb.content_margin_left = 14
	tally_sb.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", tally_sb)
	_hud_container.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_marine_count_label = Label.new()
	_marine_count_label.text = "⚓ Port Defense Garrison: 14/14"
	_marine_count_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	_marine_count_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_marine_count_label)

	var vs_lbl = Label.new()
	vs_lbl.text = "   🌊 VS 🏴‍☠️   "
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vs_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(vs_lbl)

	_invader_count_label = Label.new()
	_invader_count_label.text = "🏴‍☠️ Invading Sea Raiders: 16/16"
	_invader_count_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.48))
	_invader_count_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_invader_count_label)

	_banner_label = Label.new()
	_banner_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner_label.offset_top = 138.0
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	_banner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_banner_label.add_theme_constant_override("outline_size", 4)
	_banner_label.add_theme_font_size_override("font_size", 17)
	_hud_container.add_child(_banner_label)

	var cmd_panel = PanelContainer.new()
	cmd_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cmd_panel.offset_top = -92.0
	cmd_panel.offset_left = -450.0
	cmd_panel.offset_right = 450.0
	cmd_panel.offset_bottom = -58.0
	cmd_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cmd_panel.add_theme_stylebox_override("panel", tally_sb)
	_hud_container.add_child(cmd_panel)

	var cmd_hbox = HBoxContainer.new()
	cmd_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cmd_panel.add_child(cmd_hbox)

	var cmd_lbl = Label.new()
	cmd_lbl.text = "[1] Storm Beachhead!  |  [2] Quay Shield Wall  |  [3] Rally to Hero  |  [4] Quay Bowmen Volley  |  [5] Coastal Cannon Broadside!  |  [E] Sound Horn"
	cmd_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	cmd_lbl.add_theme_font_size_override("font_size", 13)
	cmd_hbox.add_child(cmd_lbl)

func _update_sea_hud_tallies() -> void:
	if _marine_count_label:
		_marine_count_label.text = "⚓ Port Defense Garrison: %d/%d" % [count_alive_marines(), _total_marines_spawned]
	if _invader_count_label:
		_invader_count_label.text = "🏴‍☠️ Invading Sea Armada: %d/%d" % [count_alive_invaders(), _total_invaders_spawned]
