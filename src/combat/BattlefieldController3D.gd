extends Node3D
class_name BattlefieldController3D

const BattlegroundTroopAIScript = preload("res://src/combat/BattlegroundTroopAI.gd")

signal battle_started()
signal battle_victory()
signal battle_wave_cleared(wave_number: int)

@export var battlefield_name: String = "Plains of the Crimson Front"
@export var auto_start_distance: float = 65.0

var royal_troops: Array = []
var crimson_troops: Array = []
var current_wave: int = 1
var is_battle_active: bool = false
var is_victory_achieved: bool = false

var _hero_player: Node3D = null
var _hud_layer: CanvasLayer = null
var _hud_container: Control = null
var _royal_count_label: Label = null
var _crimson_count_label: Label = null
var _command_banner_label: Label = null
var _command_banner_timer: float = 0.0
var _war_horn_prop: Node3D = null
var _victory_chest: Node3D = null

func _ready() -> void:
	add_to_group("army_formation")
	add_to_group("battlefield_controller")
	add_to_group("interactable")

	_build_battlefield_fortifications()
	_build_war_horn_interaction()
	_build_tactical_hud()
	spawn_battlefield_armies()

func _build_battlefield_fortifications() -> void:
	# 1. King's Royal Command Redoubt (North side of battlefield: Z ≈ 126.0)
	# War Pavilions & Command Tents
	_place_local_prop("res://assets/overworld/tent.gltf", Vector3(-12.0, 0.0, -22.0), Vector3.ONE * 2.4, 30.0)
	_place_local_prop("res://assets/overworld/tent.gltf", Vector3(12.0, 0.0, -22.0), Vector3.ONE * 2.4, -30.0)
	_place_local_prop("res://assets/overworld/tent.gltf", Vector3(0.0, 0.0, -28.0), Vector3.ONE * 3.0, 0.0)

	# Royal Blue Heraldic Standards
	for bx in [-16.0, -8.0, 8.0, 16.0]:
		_place_local_prop("res://assets/overworld/flag_blue.gltf", Vector3(bx, 0.0, -20.0), Vector3.ONE * 2.2)

	# Royal Armory racks, pallets, crates
	_place_local_prop("res://assets/overworld/weaponrack.gltf", Vector3(-8.0, 0.0, -18.0), Vector3.ONE * 1.8, 90.0)
	_place_local_prop("res://assets/overworld/weaponrack.gltf", Vector3(8.0, 0.0, -18.0), Vector3.ONE * 1.8, -90.0)
	_place_local_prop("res://assets/overworld/pallet.gltf", Vector3(-14.0, 0.0, -24.0), Vector3.ONE * 1.5)
	_place_local_prop("res://assets/overworld/crate_A_big.gltf", Vector3(-14.0, 0.0, -24.0), Vector3.ONE * 1.3)
	_place_local_prop("res://assets/overworld/barrel.gltf", Vector3(14.0, 0.0, -24.0), Vector3.ONE * 1.3)

	# 2. Central No-Man's Land: Defensive Stakes, Barricades & Earthworks (Z ≈ 0.0 locally)
	# Spiked timber palisades with openings for cavalry & troop charges
	for fx in [-24.0, -18.0, -12.0, 12.0, 18.0, 24.0]:
		_place_local_prop("res://assets/overworld/fence_wood_straight.gltf", Vector3(fx, 0.0, -4.0), Vector3.ONE * 2.2, 90.0)
		_place_local_prop("res://assets/overworld/fence_wood_straight.gltf", Vector3(fx, 0.0, 4.0), Vector3.ONE * 2.2, 90.0)

	# Earth trenches & berms
	for tx in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		_place_local_prop("res://assets/overworld/floor_dirt.gltf", Vector3(tx, 0.01, 0.0), Vector3(3.2, 1.0, 3.2))

	# Burning Iron Signal Braziers
	_place_burning_brazier(Vector3(-15.0, 0.0, 0.0))
	_place_burning_brazier(Vector3(15.0, 0.0, 0.0))

	# 3. Crimson Enemy Vanguard Bastion (South side of battlefield: Z ≈ 26.0 locally)
	# Crimson Command Pavilions & Watchtowers
	_place_local_prop("res://assets/overworld/building_tower_catapult_red.gltf", Vector3(-20.0, 0.0, 30.0), Vector3.ONE * 7.5, 0.0)
	_place_local_prop("res://assets/overworld/building_tower_catapult_red.gltf", Vector3(20.0, 0.0, 30.0), Vector3.ONE * 7.5, 0.0)
	_place_local_prop("res://assets/overworld/tent.gltf", Vector3(-6.0, 0.0, 28.0), Vector3.ONE * 2.6, 180.0)
	_place_local_prop("res://assets/overworld/tent.gltf", Vector3(6.0, 0.0, 28.0), Vector3.ONE * 2.6, 180.0)

	# Crimson War Banners
	for rx in [-18.0, -7.0, 7.0, 18.0]:
		_place_local_prop("res://assets/overworld/flag_red.gltf", Vector3(rx, 0.0, 24.0), Vector3.ONE * 2.2, 180.0)

	# Munition Wagons & Barrels
	_place_local_prop("res://assets/overworld/wheelbarrow.gltf", Vector3(-12.0, 0.0, 26.0), Vector3.ONE * 1.4, 45.0)
	_place_local_prop("res://assets/overworld/pallet.gltf", Vector3(12.0, 0.0, 26.0), Vector3.ONE * 1.5)
	_place_local_prop("res://assets/overworld/barrel.gltf", Vector3(12.5, 0.0, 26.0), Vector3.ONE * 1.3)

func _place_burning_brazier(local_pos: Vector3) -> void:
	var brazier = AssetLoader.load_or_generate_model("res://assets/overworld/shrine_candles.gltf", "dungeon", "brazier")
	brazier.position = local_pos
	brazier.scale = Vector3.ONE * 1.8
	add_child(brazier)

	var flame_light = OmniLight3D.new()
	flame_light.light_color = Color(1.0, 0.55, 0.15)
	flame_light.light_energy = 3.5
	flame_light.omni_range = 10.0
	flame_light.position = local_pos + Vector3(0.0, 1.4, 0.0)
	add_child(flame_light)

func _place_local_prop(model_path: String, local_pos: Vector3, scale_v: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0) -> Node3D:
	var prop = AssetLoader.load_or_generate_model(model_path, "dungeon", "battle_prop")
	prop.position = local_pos
	prop.scale = scale_v
	prop.rotation_degrees.y = rot_y_deg
	add_child(prop)
	return prop

func _build_war_horn_interaction() -> void:
	# Royal War Horn on the Commander's Crest
	var horn_root = Node3D.new()
	horn_root.name = "RoyalWarHornStand"
	horn_root.position = Vector3(0.0, 0.0, -20.0)
	add_child(horn_root)
	_war_horn_prop = horn_root

	var ped = AssetLoader.load_or_generate_model("res://assets/overworld/pillar.gltf", "dungeon", "horn_pedestal")
	ped.scale = Vector3(0.7, 1.1, 0.7)
	horn_root.add_child(ped)

	var horn_lbl = Label3D.new()
	horn_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	horn_lbl.position = Vector3(0.0, 1.8, 0.0)
	horn_lbl.pixel_size = 0.006
	horn_lbl.visibility_range_end = 24.0
	horn_lbl.modulate = Color(1.0, 0.9, 0.4)
	horn_lbl.text = "📯 Royal War Horn\n[E] Sound Horn to Rally Vanguard"
	horn_root.add_child(horn_lbl)

	var area = Area3D.new()
	area.name = "HornInteractArea"
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

func spawn_battlefield_armies() -> void:
	_cleanup_armies()
	is_battle_active = true
	is_victory_achieved = false

	# 1. Spawn King's Royal Army (14 Units) on North Line (Z ≈ -16.0)
	# [0] Commander
	_spawn_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.COMMANDER, "Marshal of the Citadel", Vector3(0.0, 0.0, -18.0), Vector3(0.0, 0.0, -1.5))

	# [1..5] Royal Vanguard Knights (Frontline Phalanx)
	var knight_xs = [-6.0, -3.0, 0.0, 3.0, 6.0]
	for kx in knight_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.KNIGHT, "Royal Knight", Vector3(kx, 0.0, -14.0), Vector3(kx, 0.0, 0.0))

	# [6..9] Royal Berserkers (Shock Cleavers)
	var zerker_xs = [-4.5, -1.5, 1.5, 4.5]
	for zx in zerker_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.BERSERKER, "Royal Berserker", Vector3(zx, 0.0, -16.0), Vector3(zx, 0.0, 1.5))

	# [10..13] Royal Crossbow Marksmen (Backline Volley)
	var archer_xs = [-5.0, -2.0, 2.0, 5.0]
	for ax in archer_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.ROYAL, BattlegroundTroopAIScript.Role.ARCHER, "Citadel Crossbowman", Vector3(ax, 0.0, -19.0), Vector3(ax, 0.0, -2.5))

	# 2. Spawn Crimson Legion Army (16 Units) on South Line (Z ≈ +22.0)
	# [0] Crimson Warlord Commander
	_spawn_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.COMMANDER, "Crimson Warlord Malakor", Vector3(0.0, 0.0, 24.0), Vector3(0.0, 0.0, 1.5))

	# [1..6] Crimson Footmen (Frontline Swordsmen)
	var c_foot_xs = [-7.5, -4.5, -1.5, 1.5, 4.5, 7.5]
	for cx in c_foot_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.KNIGHT, "Redcrest Footman", Vector3(cx, 0.0, 18.0), Vector3(cx, 0.0, 0.0))

	# [7..11] Crimson Marauder Berserkers
	var c_zerk_xs = [-6.0, -3.0, 0.0, 3.0, 6.0]
	for zx in c_zerk_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.BERSERKER, "Crimson Marauder", Vector3(zx, 0.0, 20.0), Vector3(zx, 0.0, 1.0))

	# [12..15] Crimson Outlaw Archers
	var c_arch_xs = [-4.5, -1.5, 1.5, 4.5]
	for ax in c_arch_xs:
		_spawn_troop(BattlegroundTroopAIScript.Faction.CRIMSON, BattlegroundTroopAIScript.Role.ARCHER, "Redcrest Arbalest", Vector3(ax, 0.0, 22.0), Vector3(ax, 0.0, 2.5))

	battle_started.emit()
	show_command_banner("⚔️ THE SOUTHERN BATTLEGROUND HAS ENGAGED! Press [1] Charge, [2] Shield Wall, [3] Rally, [4] Volley!", 4.0)
	AudioManager.play_sfx("horn_rally", 0.05, 1.5)

func _spawn_troop(f: int, r: int, troop_name: String, local_pos: Vector3, form_offset: Vector3) -> Node:
	var troop = BattlegroundTroopAIScript.new()
	troop.faction = f
	troop.role = r
	troop.unit_name = troop_name
	troop.position = local_pos
	troop.home_formation_pos = global_position + local_pos
	troop.formation_offset = form_offset
	troop.unit_died.connect(_on_troop_died)

	add_child(troop)

	if f == BattlegroundTroopAIScript.Faction.ROYAL:
		royal_troops.append(troop)
	else:
		crimson_troops.append(troop)

	return troop

func _cleanup_armies() -> void:
	for t in royal_troops:
		if is_instance_valid(t):
			t.queue_free()
	royal_troops.clear()

	for t in crimson_troops:
		if is_instance_valid(t):
			t.queue_free()
	crimson_troops.clear()

	if is_instance_valid(_victory_chest):
		_victory_chest.queue_free()
		_victory_chest = null

func _on_troop_died(dead_unit: Node) -> void:
	if dead_unit.faction == BattlegroundTroopAIScript.Faction.CRIMSON:
		crimson_troops.erase(dead_unit)
		if count_alive_crimson() == 0 and not is_victory_achieved:
			_trigger_victory()
	else:
		royal_troops.erase(dead_unit)

func count_alive_royal() -> int:
	var count = 0
	for t in royal_troops:
		if is_instance_valid(t) and t.current_state != BattlegroundTroopAIScript.State.DEAD:
			count += 1
	return count

func count_alive_crimson() -> int:
	var count = 0
	for t in crimson_troops:
		if is_instance_valid(t) and t.current_state != BattlegroundTroopAIScript.State.DEAD:
			count += 1
	return count

func _process(delta: float) -> void:
	if not _hero_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_hero_player = players[0]

	var dist_to_hero = 999.0
	if is_instance_valid(_hero_player):
		dist_to_hero = global_position.distance_to(_hero_player.global_position)

	# Toggle Tactical HUD visibility based on player proximity to Sector C4 battlefield
	var is_near = dist_to_hero < auto_start_distance
	if _hud_container:
		_hud_container.visible = is_near

	if is_near:
		_process_player_commands()

	_command_banner_timer = max(0.0, _command_banner_timer - delta)
	if _command_banner_label and _command_banner_timer <= 0.0:
		_command_banner_label.text = ""

	_update_hud_tallies()

func _process_player_commands() -> void:
	if Input.is_action_just_pressed("ui_select") or Input.is_key_pressed(KEY_1):
		command_all_charge()
	elif Input.is_key_pressed(KEY_2):
		command_all_shield_wall()
	elif Input.is_key_pressed(KEY_3):
		command_all_rally()
	elif Input.is_key_pressed(KEY_4):
		command_all_volley()

func command_all_charge() -> void:
	show_command_banner("⚔️ ORDER: FULL ARMY CHARGE! All units advance aggressively!", 2.5)
	AudioManager.play_sfx("horn_rally", 0.08, 1.0)
	for t in royal_troops:
		if is_instance_valid(t):
			t.command_charge()

func command_all_shield_wall() -> void:
	show_command_banner("🛡️ ORDER: SHIELD WALL FORMED! +75% Damage Reduction!", 2.5)
	AudioManager.play_sfx("parry_ring", 0.05, 1.2)
	for t in royal_troops:
		if is_instance_valid(t):
			t.command_shield_wall()

func command_all_rally() -> void:
	show_command_banner("📯 ORDER: RALLY TO HERO! Troops breaking off to defend you!", 2.5)
	AudioManager.play_sfx("horn_rally", 0.06, 1.2)
	for t in royal_troops:
		if is_instance_valid(t):
			t.command_rally(_hero_player if _hero_player else self)

func command_all_volley() -> void:
	show_command_banner("🏹 ORDER: ARCHER VOLLEY! Crossbowmen raining bolts on enemy lines!", 2.5)
	AudioManager.play_sfx("bow_shoot", 0.06, 1.0)
	var enemy_center = global_position + Vector3(0.0, 0.0, 16.0)
	for t in royal_troops:
		if is_instance_valid(t):
			t.command_volley(enemy_center)

func show_command_banner(msg: String, duration: float = 2.5) -> void:
	if _command_banner_label:
		_command_banner_label.text = msg
		_command_banner_timer = duration

func _trigger_victory() -> void:
	is_victory_achieved = true
	battle_victory.emit()
	show_command_banner("👑 VICTORY ON THE CRIMSON FRONT! The King's Army Triumphs! (+300 Gold, +150 Soul Echoes)", 5.0)
	AudioManager.play_sfx("horn_rally", 0.02, 2.5)

	# Rewards
	GameManager.player_gold += 300
	GameManager.soul_echoes += 150

	# Spawn Golden Royal Spoils of War Chest in center
	_spawn_victory_chest()

	# Cheer animations for surviving troops
	for t in royal_troops:
		if is_instance_valid(t) and t.current_state != BattlegroundTroopAIScript.State.DEAD:
			t._play_anim("Cheer" if t._anim_player and t._anim_player.has_animation("Cheer") else "Idle")

func _spawn_victory_chest() -> void:
	if is_instance_valid(_victory_chest):
		return
	var chest = AssetLoader.load_or_generate_model("res://assets/overworld/crate_A_big.gltf", "dungeon", "victory_chest")
	chest.position = Vector3(0.0, 0.0, 0.0)
	chest.scale = Vector3.ONE * 2.2
	add_child(chest)
	_victory_chest = chest

	var gold_light = OmniLight3D.new()
	gold_light.light_color = Color(1.0, 0.85, 0.2)
	gold_light.light_energy = 4.0
	gold_light.omni_range = 8.0
	gold_light.position = Vector3(0.0, 1.5, 0.0)
	chest.add_child(gold_light)

	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.2, 0.0)
	lbl.pixel_size = 0.006
	lbl.modulate = Color(1.0, 0.88, 0.25)
	lbl.text = "🏆 Royal Spoils of War\n[Claimed: +300 Gold, +150 Echoes]"
	chest.add_child(lbl)

func interact(player: Node = null) -> void:
	# Interacting with the controller or war horn triggers a new battle wave!
	AudioManager.play_sfx("horn_rally", 0.05, 1.5)
	current_wave += 1
	spawn_battlefield_armies()
	show_command_banner("📯 THE ROYAL WAR HORN SOUNDS! Wave %d has entered the fray!" % current_wave, 3.5)

func _build_tactical_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "BattlefieldTacticalHUD"
	add_child(_hud_layer)

	_hud_container = Control.new()
	_hud_container.name = "HUDContainer"
	_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_hud_container)

	# Top Tally Bar
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 48.0
	panel.offset_left = 220.0
	panel.offset_right = -220.0
	panel.offset_bottom = 96.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_royal_count_label = Label.new()
	_royal_count_label.text = "👑 King's Army: 14/14"
	_royal_count_label.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	_royal_count_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(_royal_count_label)

	var vs_lbl = Label.new()
	vs_lbl.text = "   ⚔️   VS   ⚔️   "
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vs_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(vs_lbl)

	_crimson_count_label = Label.new()
	_crimson_count_label.text = "💀 Crimson Legion: 16/16"
	_crimson_count_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_crimson_count_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(_crimson_count_label)

	# Center Action / Command Banner
	_command_banner_label = Label.new()
	_command_banner_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_command_banner_label.offset_top = 104.0
	_command_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_command_banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	_command_banner_label.add_theme_font_size_override("font_size", 20)
	_hud_container.add_child(_command_banner_label)

	# Bottom Command Bar
	var cmd_panel = PanelContainer.new()
	cmd_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cmd_panel.offset_top = -68.0
	cmd_panel.offset_left = 180.0
	cmd_panel.offset_right = -180.0
	cmd_panel.offset_bottom = -22.0
	cmd_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.add_child(cmd_panel)

	var cmd_hbox = HBoxContainer.new()
	cmd_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cmd_panel.add_child(cmd_hbox)

	var commands_text = "[1] Charge!  |  [2] Shield Wall (-75% Dmg)  |  [3] Rally to Hero  |  [4] Crossbow Volley  |  [E] Sound Horn"
	var cmd_lbl = Label.new()
	cmd_lbl.text = commands_text
	cmd_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	cmd_lbl.add_theme_font_size_override("font_size", 15)
	cmd_hbox.add_child(cmd_lbl)

func _update_hud_tallies() -> void:
	if _royal_count_label:
		_royal_count_label.text = "👑 King's Army: %d/14" % count_alive_royal()
	if _crimson_count_label:
		_crimson_count_label.text = "💀 Crimson Legion: %d/16" % count_alive_crimson()
