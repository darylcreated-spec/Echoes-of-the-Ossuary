extends CanvasLayer
class_name HUD

const BoonSelectionModalScript = preload("res://src/ui/BoonSelectionModal.gd")
const BoonSystemScript = preload("res://src/combat/BoonSystem.gd")
const MissionMenuScript = preload("res://src/ui/MissionMenu.gd")
const DialogueModalScript = preload("res://src/ui/DialogueModal.gd")

# Health Bar references
var hp_bar: ProgressBar = null
var hp_damage_bar: ProgressBar = null
var hp_label: Label = null

# Floor & Currency Labels
var floor_label: Label = null
var gold_label: Label = null
var echoes_label: Label = null

# Boons Container
var boons_container: HBoxContainer = null

# Boss Bar
var boss_container: VBoxContainer = null
var boss_name_label: Label = null
var boss_hp_bar: ProgressBar = null

# Interaction Prompt
var interact_prompt: Label = null

# Modals
var boon_modal: Control = null
var altar_modal: Control = null
var death_modal: Control = null
var mission_menu: Control = null
var dialogue_modal: DialogueModal = null
var fade_curtain: ColorRect = null

# Mission Notification Toast
var mission_toast: PanelContainer = null
var mission_toast_lbl: Label = null
var _toast_tween: Tween = null

func _ready() -> void:
	add_to_group("hud")
	_build_ui_tree()
	_connect_game_signals()
	_update_currencies()
	_update_floor_display()

func _connect_game_signals() -> void:
	GameManager.gold_changed.connect(func(_new_val, _d): _update_currencies())
	GameManager.echoes_changed.connect(func(_new_val, _d): _update_currencies())
	GameManager.floor_changed.connect(func(_f): _update_floor_display())
	GameManager.boon_acquired.connect(_on_boon_acquired)
	GameManager.game_over.connect(_on_game_over)
	GameManager.mission_completed.connect(_on_mission_completed)
	
	# Connect to player if spawned
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(update_player_health)
		var cur_hp = player.get("current_health")
		var max_hp = player.get("max_health")
		if cur_hp != null and max_hp != null:
			update_player_health(cur_hp, max_hp)

func _build_ui_tree() -> void:
	var root_control = Control.new()
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	# Top Left: Health & Status
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(24, 20)
	root_control.add_child(top_left)
	
	var hp_box = Control.new()
	hp_box.custom_minimum_size = Vector2(280, 26)
	top_left.add_child(hp_box)
	
	# Delayed Damage Bar (Red)
	hp_damage_bar = ProgressBar.new()
	hp_damage_bar.size = Vector2(280, 24)
	hp_damage_bar.show_percentage = false
	var dmg_style = StyleBoxFlat.new()
	dmg_style.bg_color = Color(0.8, 0.2, 0.2)
	dmg_style.set_corner_radius_all(4)
	hp_damage_bar.add_theme_stylebox_override("fill", dmg_style)
	hp_box.add_child(hp_damage_bar)
	
	# Foreground Health Bar (Green)
	hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(280, 24)
	hp_bar.show_percentage = false
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.2, 0.85, 0.4)
	hp_style.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", hp_style)
	hp_box.add_child(hp_bar)
	
	hp_label = Label.new()
	hp_label.position = Vector2(10, 2)
	hp_label.text = "100 / 100"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_box.add_child(hp_label)
	
	# Top Right: Currencies & Floor
	var top_right = VBoxContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.position = Vector2(-240, 20)
	root_control.add_child(top_right)
	
	floor_label = Label.new()
	floor_label.text = "Sanctuary Hub"
	floor_label.add_theme_font_size_override("font_size", 18)
	floor_label.modulate = Color(1.0, 0.85, 0.3)
	top_right.add_child(floor_label)
	
	var curr_box = HBoxContainer.new()
	curr_box.add_theme_constant_override("separation", 16)
	top_right.add_child(curr_box)
	
	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	gold_label.modulate = Color(1.0, 0.9, 0.4)
	curr_box.add_child(gold_label)
	
	echoes_label = Label.new()
	echoes_label.text = "Echoes: 0"
	echoes_label.modulate = Color(0.2, 0.9, 0.85)
	curr_box.add_child(echoes_label)
	
	var missions_btn = Button.new()
	missions_btn.text = "📜 Missions [M]"
	missions_btn.custom_minimum_size = Vector2(110, 26)
	missions_btn.pressed.connect(func(): if mission_menu: mission_menu.toggle_menu())
	top_right.add_child(missions_btn)
	
	# Bottom Left: Active Relic Boons
	boons_container = HBoxContainer.new()
	boons_container.position = Vector2(24, 660)
	boons_container.add_theme_constant_override("separation", 8)
	root_control.add_child(boons_container)
	
	# Center Bottom: Interaction Prompt
	interact_prompt = Label.new()
	interact_prompt.text = "[E] Interact"
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.anchor_left = 0.5
	interact_prompt.anchor_right = 0.5
	interact_prompt.anchor_top = 0.8
	interact_prompt.anchor_bottom = 0.8
	interact_prompt.offset_left = -150
	interact_prompt.offset_right = 150
	interact_prompt.add_theme_font_size_override("font_size", 20)
	interact_prompt.modulate = Color(1.0, 0.95, 0.5)
	interact_prompt.visible = false
	root_control.add_child(interact_prompt)
	
	# Top Center: Boss Health Bar
	boss_container = VBoxContainer.new()
	boss_container.anchor_left = 0.5
	boss_container.anchor_right = 0.5
	boss_container.offset_left = -260
	boss_container.offset_right = 260
	boss_container.offset_top = 24
	boss_container.visible = false
	root_control.add_child(boss_container)
	
	boss_name_label = Label.new()
	boss_name_label.text = "Skeletal Warden"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 16)
	boss_name_label.modulate = Color(1.0, 0.3, 0.3)
	boss_container.add_child(boss_name_label)
	
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(520, 18)
	boss_hp_bar.show_percentage = false
	var boss_style = StyleBoxFlat.new()
	boss_style.bg_color = Color(0.9, 0.15, 0.15)
	boss_style.set_corner_radius_all(4)
	boss_hp_bar.add_theme_stylebox_override("fill", boss_style)
	boss_container.add_child(boss_hp_bar)
	
	# Modals
	boon_modal = BoonSelectionModalScript.new()
	add_child(boon_modal)
	
	_create_altar_modal()
	_create_death_modal()

	mission_menu = MissionMenuScript.new()
	add_child(mission_menu)
	_create_mission_toast(root_control)

	dialogue_modal = DialogueModalScript.new()
	dialogue_modal.action_triggered.connect(_on_dialogue_action)
	add_child(dialogue_modal)

	# Full-screen transition curtain for building doorways & floor transitions
	fade_curtain = ColorRect.new()
	fade_curtain.name = "FadeCurtain"
	fade_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_curtain.anchor_right = 1.0
	fade_curtain.anchor_bottom = 1.0
	fade_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_curtain)

func fade_screen(to_black: bool, duration: float = 0.25) -> Signal:
	if not fade_curtain:
		fade_curtain = ColorRect.new()
		fade_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
		fade_curtain.anchor_right = 1.0
		fade_curtain.anchor_bottom = 1.0
		fade_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fade_curtain)
	var target_alpha = 1.0 if to_black else 0.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_curtain, "color:a", target_alpha, duration)
	return tween.finished

func update_player_health(curr: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = curr
		hp_label.text = str(int(curr)) + " / " + str(int(max_v))
		
		# Delayed smooth damage bar
		if hp_damage_bar:
			hp_damage_bar.max_value = max_v
			var tween = hp_damage_bar.create_tween()
			tween.tween_property(hp_damage_bar, "value", curr, 0.45).set_delay(0.25).set_trans(Tween.TRANS_QUAD)

func update_boss_health(curr: float, max_v: float, b_name: String) -> void:
	if curr <= 0.0:
		boss_container.visible = false
		return
	boss_container.visible = true
	boss_name_label.text = b_name
	boss_hp_bar.max_value = max_v
	boss_hp_bar.value = curr

func _update_currencies() -> void:
	if gold_label:
		gold_label.text = "Gold: " + str(GameManager.gold)
	if echoes_label:
		echoes_label.text = "Soul Echoes: " + str(GameManager.soul_echoes)

func _update_floor_display() -> void:
	if not floor_label:
		return
	if GameManager.current_floor == 0:
		floor_label.text = "Surface Sanctuary (Overworld)"
	elif GameManager.current_floor >= 5:
		floor_label.text = "Floor 5: The Ossuary Throne"
	else:
		floor_label.text = "Ossuary Delve • Floor " + str(GameManager.current_floor) + " • Chamber " + str(GameManager.current_chamber_index) + "/" + str(GameManager.max_chambers_per_floor)

func _on_boon_acquired(boon: Dictionary) -> void:
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(36, 36)
	var style = StyleBoxFlat.new()
	style.bg_color = boon.get("color", Color(0.2, 0.5, 0.8))
	style.set_corner_radius_all(4)
	badge.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = boon.get("name", "B")[0]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(label)
	badge.tooltip_text = boon.get("name", "") + "\n" + boon.get("description", "")
	boons_container.add_child(badge)

func show_boon_selection() -> void:
	var choices = BoonSystemScript.get_random_boons(3)
	boon_modal.display_choices(choices)

# --- ALTAR MODAL ---
func _create_altar_modal() -> void:
	altar_modal = Control.new()
	altar_modal.anchor_right = 1.0
	altar_modal.anchor_bottom = 1.0
	altar_modal.visible = false
	add_child(altar_modal)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 0.88)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	altar_modal.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -200
	panel.offset_bottom = 200
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18)
	style.border_color = Color(0.1, 0.85, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_top = 20
	style.content_margin_right = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	altar_modal.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "— BRAZIER OF PERPETUAL ASH —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.1, 0.9, 0.85)
	vbox.add_child(title)
	
	# Upgrades list
	_add_upgrade_row(vbox, "Max Health (+20 HP)", "max_hp")
	_add_upgrade_row(vbox, "Attack Power (+12%)", "attack_power")
	_add_upgrade_row(vbox, "Dash Cooldown (-12%)", "dash_cooldown")
	
	var close_btn = Button.new()
	close_btn.text = "Step Away"
	close_btn.pressed.connect(func():
		altar_modal.visible = false
		get_tree().paused = false
	)
	vbox.add_child(close_btn)

func _add_upgrade_row(parent: VBoxContainer, label_text: String, upgrade_id: String) -> void:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	
	var btn = Button.new()
	var cost = GameManager.get_upgrade_cost(upgrade_id)
	btn.text = ("Cost: " + str(cost) + " Echoes") if cost > 0 else "MAXED"
	btn.pressed.connect(func():
		if GameManager.purchase_upgrade(upgrade_id):
			var new_cost = GameManager.get_upgrade_cost(upgrade_id)
			btn.text = ("Cost: " + str(new_cost) + " Echoes") if new_cost > 0 else "MAXED"
			_update_currencies()
	)
	row.add_child(btn)
	parent.add_child(row)

func open_dialogue(title_text: String, icon_str: String, body_text: String, actions: Array[Dictionary]) -> void:
	if dialogue_modal:
		dialogue_modal.show_dialogue(title_text, icon_str, body_text, actions)

func _on_dialogue_action(action_id: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	match action_id:
		"open_upgrades":
			show_altar_modal()
		"open_missions":
			if mission_menu:
				mission_menu.open_menu()
		"gate_info":
			if dialogue_modal:
				var follow_up_actions: Array[Dictionary] = [
					{
						"id": "open_missions",
						"label": "📜 Check Bounties",
						"color": Color(0.18, 0.42, 0.65),
						"closes": true
					}
				]
				dialogue_modal.show_dialogue(
					"Captain Vane (Gate Sentinel)",
					"🛡️",
					"Beyond this archway lies the Descent Sigil into the Ossuary. The crypt grows more perilous with every floor. Steel your courage, claim bounties, and re-temper your soul at the forge!",
					follow_up_actions
				)
		"turn_in_chalice":
			if GameManager.materials.get("sacred_chalice", 0) > 0:
				GameManager.materials["sacred_chalice"] = 0
				GameManager.quest_chalice_completed = true
				GameManager.add_gold(150)
				GameManager.add_echoes(40)
				GameManager.acquire_boon_by_id("knight_crest")
				AudioManager.play_sfx("level_up", 0.08, 1.2)
				if dialogue_modal:
					dialogue_modal.show_dialogue(
						"Steward Alden (Royal Castellan)",
						"👑",
						"Splendid! The Crown grants you 150 Gold, 40 Soul Echoes, and bestows the legendary Knight's Royal Crest (+15% Damage Reduction & +30 HP) upon your mantle!",
						[]
					)
		"turn_in_scroll":
			if GameManager.materials.get("ossuary_codex", 0) > 0:
				GameManager.materials["ossuary_codex"] = 0
				GameManager.quest_vintage_completed = true
				GameManager.add_gold(80)
				GameManager.add_echoes(25)
				if player and player.has_method("heal"):
					player.heal(player.max_health)
				AudioManager.play_sfx("gold_pickup", 0.08, 1.0)
				if dialogue_modal:
					dialogue_modal.show_dialogue(
						"Barkeep Barnaby (Tavern Master)",
						"🍺",
						"Magnificent! Barnaby hands you 80 Gold, 25 Soul Echoes, and pours a grand flagon of restorative draught, restoring your health completely to full!",
						[]
					)
		"turn_in_ingots":
			var mat_key = ""
			if GameManager.materials.get("smugglers_chest", 0) > 0:
				mat_key = "smugglers_chest"
			elif GameManager.materials.get("gold_vein", 0) > 0:
				mat_key = "gold_vein"
			elif GameManager.materials.get("iron_ore", 0) > 0:
				mat_key = "iron_ore"
			if mat_key != "":
				GameManager.materials[mat_key] = maxi(0, GameManager.materials[mat_key] - 1)
				GameManager.quest_steel_completed = true
				GameManager.add_gold(100)
				GameManager.upgrade_attack_power_level += 1
				GameManager.player_stats_changed.emit()
				AudioManager.play_sfx("anvil_strike", 0.08, 1.0)
				if dialogue_modal:
					dialogue_modal.show_dialogue(
						"Master Torval (Grand Forge Smith)",
						"⚒️",
						"By the roaring coals! Torval plunges the ingots into the furnace and strikes your blade. You receive 100 Gold and a permanent +3 Weapon Attack Power bonus!",
						[]
					)
		"turn_in_wolves":
			GameManager.quest_wolves_completed = true
			GameManager.add_gold(60)
			GameManager.add_echoes(30)
			AudioManager.play_sfx("gold_pickup", 0.08, 1.0)
			if dialogue_modal:
				dialogue_modal.show_dialogue(
					"Elder Giles (Hamlet Elder)",
					"🌾",
					"Elder Giles beams with relief! The hamlet grants you 60 Gold and 30 Soul Echoes for protecting the sheep pasture!",
					[]
				)
		"barkeep_ale":
			if GameManager.gold >= 5:
				GameManager.add_gold(-5)
				if player and player.has_method("heal"):
					player.heal(20.0)
				AudioManager.play_sfx("gold_pickup", 0.08, 1.2)
				if dialogue_modal:
					dialogue_modal.show_dialogue(
						"Barkeep Barnaby",
						"🍺",
						"You down a rich, foaming flagon of spiced mead! A warm glow spreads through your limbs (+20 HP restored).",
						[]
					)
			else:
				if dialogue_modal:
					dialogue_modal.show_dialogue(
						"Barkeep Barnaby",
						"🍺",
						"Barnaby winks: 'Come back when you've got 5 gold coins in your pouch, friend!'",
						[]
					)
		"bard_song":
			if dialogue_modal:
				dialogue_modal.show_dialogue(
					"Bard Finn (Minstrel of Oakhaven)",
					"🪕",
					"Bard Finn strums a haunting lute ballad: 'The stones beneath whisper of an ancient king... He who braves the five tiers shall wear the crown of dawn!' You feel a serene focus settle in your veins.",
					[]
				)

func show_altar_modal() -> void:
	altar_modal.visible = true
	get_tree().paused = true

# --- DEATH / VICTORY MODAL ---
func _create_death_modal() -> void:
	death_modal = Control.new()
	death_modal.anchor_right = 1.0
	death_modal.anchor_bottom = 1.0
	death_modal.visible = false
	add_child(death_modal)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.02, 0.92)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	death_modal.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -200
	vbox.offset_right = 200
	vbox.offset_top = -140
	vbox.offset_bottom = 140
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	death_modal.add_child(vbox)
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "DEATH CLAIMS ANOTHER SOUL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(1.0, 0.25, 0.25)
	vbox.add_child(title)
	
	var stats = Label.new()
	stats.name = "StatsLabel"
	stats.text = "Your mortal shell shatters. Soul Echoes bound to the Eternal Brazier."
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	var restart_btn = Button.new()
	restart_btn.text = "Awaken at the Sanctuary"
	restart_btn.custom_minimum_size = Vector2(0, 44)
	restart_btn.pressed.connect(func():
		death_modal.visible = false
		get_tree().paused = false
		GameManager.return_to_sanctuary()
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("load_current_floor_room"):
			main.load_current_floor_room()
	)
	vbox.add_child(restart_btn)

func _on_game_over(victory: bool) -> void:
	death_modal.visible = true
	var title = death_modal.find_child("TitleLabel", true, false)
	if title:
		title.text = "THE OSSUARY IS CONQUERED!" if victory else "DEATH CLAIMS ANOTHER SOUL"
		title.modulate = Color(1.0, 0.85, 0.2) if victory else Color(1.0, 0.2, 0.2)

func _create_mission_toast(parent: Control) -> void:
	mission_toast = PanelContainer.new()
	mission_toast.custom_minimum_size = Vector2(380, 56)
	mission_toast.anchor_left = 0.5
	mission_toast.anchor_right = 0.5
	mission_toast.anchor_top = 0.12
	mission_toast.anchor_bottom = 0.12
	mission_toast.offset_left = -190
	mission_toast.offset_right = 190
	mission_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var toast_style = StyleBoxFlat.new()
	toast_style.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	toast_style.border_color = Color(0.95, 0.8, 0.25)
	toast_style.set_border_width_all(2)
	toast_style.set_corner_radius_all(6)
	toast_style.content_margin_left = 16
	toast_style.content_margin_right = 16
	toast_style.content_margin_top = 8
	toast_style.content_margin_bottom = 8
	mission_toast.add_theme_stylebox_override("panel", toast_style)
	
	mission_toast_lbl = Label.new()
	mission_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_toast_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission_toast_lbl.add_theme_font_size_override("font_size", 13)
	mission_toast_lbl.modulate = Color(1.0, 0.95, 0.7)
	mission_toast.add_child(mission_toast_lbl)
	
	mission_toast.visible = false
	parent.add_child(mission_toast)

func _on_mission_completed(m: Dictionary) -> void:
	if not mission_toast or not mission_toast_lbl:
		return
	mission_toast_lbl.text = "✨ BOUNTY COMPLETED: " + m.get("title", "") + "!\nPress [M] to claim your reward"
	mission_toast.visible = true
	mission_toast.modulate.a = 0.0
	
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
		
	_toast_tween = mission_toast.create_tween()
	_toast_tween.tween_property(mission_toast, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(3.8)
	_toast_tween.tween_property(mission_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): mission_toast.visible = false)
	
	AudioManager.play_sfx("chest_open", 0.08, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_missions"):
		if mission_menu:
			mission_menu.toggle_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		if mission_menu and mission_menu.visible:
			mission_menu.close_menu()
			get_viewport().set_input_as_handled()

