extends Control
class_name JournalModal

var _current_tab: int = 0
var _tab_buttons: Array[Button] = []
var _tab_containers: Array[Control] = []

# Tab 0: Chronicles
var _act_title_lbl: Label = null
var _act_synopsis_lbl: Label = null
var _main_objective_lbl: Label = null
var _bounties_list: VBoxContainer = null
var _restoration_list: VBoxContainer = null

# Tab 1: Hero Sheet
var _hero_title_lbl: Label = null
var _hp_val_lbl: Label = null
var _atk_val_lbl: Label = null
var _def_val_lbl: Label = null
var _spd_val_lbl: Label = null
var _crit_val_lbl: Label = null
var _talents_container: VBoxContainer = null
var _relics_container: HFlowContainer = null

# Tab 2: Codex
var _codex_title_lbl: Label = null
var _codex_body_lbl: Label = null
var _selected_codex_idx: int = 0

const CODEX_ENTRIES: Array[Dictionary] = [
	{
		"title": "👑 The Oakhaven Crown & The Catacomb Blight",
		"chapter": "Chapter I: The Fallen Sanctuary",
		"content": "For three centuries, the Sanctuary of Oakhaven stood as the heart of the realm. Its marble plazas and grand cathedral echoed with hymns of protection. Yet deep beneath the northern crypts, an ancient seal carved by the First Kings began to fracture.\n\nFrom the subterranean catacombs rose an unnatural necromantic blight, awakening skeletal legions and driving the realm's sentinels into disarray. King Valerius now looks to wandering champions to cleanse the catacombs and uncover the origin of the abyssal corruption."
	},
	{
		"title": "⚓ Port Blackwater & The Corsair Brotherhood",
		"chapter": "Chapter II: The Western Tides",
		"content": "South-west of the capital lies Port Blackwater, a fortified sea harbor where corsairs and merchants trade contraband under the banner of Captain Marlo. In recent days, sunken pirate galleons have stirred from the seabed, and the harbor cargo crane lies shattered in ruin.\n\nOnly the recovery of the Tidecaller's Compass from the submerged smugglers' den can calm the raging waves and secure maritime supply lines for the realm's war effort."
	},
	{
		"title": "🌲 The Circle of Sylva & The Corrupted Canopy",
		"chapter": "Chapter III: The Whispering Pines",
		"content": "North-west through the high mountain passes stretches Whisperwood Forest, home to the reclusive Circle of Sylva. Led by Elder Thorne, the druids once tended the sacred groves and communed with primeval beast spirits.\n\nA demonic miasma has seeped into the forest floor, defiling the Druidic Sun Altar and turning the woodland creatures rabid. Restoring the Sun Altar with refined Arcane Crystals will restore natural harmony to the woodland."
	},
	{
		"title": "🌋 The Bastion of Khar-Drakken & The Runeforge",
		"chapter": "Chapter IV: The Iron Bastion",
		"content": "Perched upon the jagged volcanic ridges of the eastern crags, Khar-Drakken is an ancient dwarven fortress renowned for its runic smelters. Within its depths, legendary weapons were once forged using dragon-fire and enchanted stone.\n\nNow overrun by magma creeps and orcish raiders, the grand smelter bellows have gone cold. By gathering mountain gold and iron ore, a courageous smith can relight the eternal ancestral forge."
	},
	{
		"title": "💀 The Abyssal Seal & The Bone Titan",
		"chapter": "Chapter V: The Descent into the Crypts",
		"content": "Beneath the mausoleum lies the four-tiered underworld known as the Ossuary. Each descent plunges deeper through bone-strewn crypts, guarded by skeletal warriors and cursed traps.\n\nAt the deepest floor slumbers the Bone Titan—a colossus stitched together from thousands of fallen warriors. Only a hero who has unified the blessings of Port Blackwater, Whisperwood, and Khar-Drakken can endure the Titan's devastating earth-shattering strikes."
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func toggle_modal() -> void:
	if visible:
		close_modal()
	else:
		open_modal()

func open_modal() -> void:
	visible = true
	get_tree().paused = true
	_refresh_data()
	AudioManager.play_sfx("ui_switch", 0.08, 1.2)

func close_modal() -> void:
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx("ui_switch", 0.08, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		close_modal()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J:
		close_modal()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_switch_tab((_current_tab + 1) % 3)
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Fullscreen backdrop
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.07, 0.92)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Main Window Panel Container
	var center_box = CenterContainer.new()
	center_box.anchor_right = 1.0
	center_box.anchor_bottom = 1.0
	add_child(center_box)

	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(940, 620)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.10, 0.14, 0.98)
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 2
	p_style.border_color = Color(0.85, 0.72, 0.35, 0.9)
	p_style.set_corner_radius_all(10)
	p_style.content_margin_left = 20
	p_style.content_margin_top = 18
	p_style.content_margin_right = 20
	p_style.content_margin_bottom = 18
	main_panel.add_theme_stylebox_override("panel", p_style)
	center_box.add_child(main_panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	main_panel.add_child(root_vbox)

	# 1. Header Bar
	var header = HBoxContainer.new()
	root_vbox.add_child(header)

	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "📖 CHRONICLES OF AETHELGARD — REALM JOURNAL"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.modulate = Color(1.0, 0.85, 0.35)
	header_vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "[J] Close Journal  |  [Tab] Switch Page  |  [Esc] Resume Journey"
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.modulate = Color(0.65, 0.72, 0.80)
	header_vbox.add_child(sub_lbl)

	var close_btn = Button.new()
	close_btn.text = " ✕ Close "
	close_btn.custom_minimum_size = Vector2(80, 32)
	close_btn.pressed.connect(close_modal)
	header.add_child(close_btn)

	# 2. Navigation Tab Buttons
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tab_bar)

	var tab_titles = [
		"📜 Chronicles & Quests",
		"⚔️ Hero Sheet & Talents",
		"🏛️ Realm Lore Codex"
	]
	for i in range(tab_titles.size()):
		var btn = Button.new()
		btn.text = tab_titles[i]
		btn.custom_minimum_size = Vector2(220, 36)
		var tab_idx = i
		btn.pressed.connect(func(): _switch_tab(tab_idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	# Content Area
	var content_stack = PanelContainer.new()
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cs_style = StyleBoxFlat.new()
	cs_style.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	cs_style.set_corner_radius_all(6)
	cs_style.content_margin_left = 16
	cs_style.content_margin_top = 16
	cs_style.content_margin_right = 16
	cs_style.content_margin_bottom = 16
	content_stack.add_theme_stylebox_override("panel", cs_style)
	root_vbox.add_child(content_stack)

	# Tab 0: Chronicles Container
	var tab0 = _build_tab0_chronicles()
	content_stack.add_child(tab0)
	_tab_containers.append(tab0)

	# Tab 1: Hero Sheet Container
	var tab1 = _build_tab1_hero_sheet()
	content_stack.add_child(tab1)
	_tab_containers.append(tab1)

	# Tab 2: Codex Container
	var tab2 = _build_tab2_codex()
	content_stack.add_child(tab2)
	_tab_containers.append(tab2)

	_switch_tab(0)

func _switch_tab(idx: int) -> void:
	_current_tab = idx
	for i in range(_tab_containers.size()):
		_tab_containers[i].visible = (i == idx)
		if i < _tab_buttons.size():
			if i == idx:
				_tab_buttons[i].modulate = Color(1.0, 0.9, 0.4)
			else:
				_tab_buttons[i].modulate = Color(0.8, 0.8, 0.8)
	AudioManager.play_sfx("ui_switch", 0.05, 1.1)

# --- TAB 0: CHRONICLES & QUESTS ---
func _build_tab0_chronicles() -> Control:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)

	# Act Banner Card
	var act_card = PanelContainer.new()
	var ac_style = StyleBoxFlat.new()
	ac_style.bg_color = Color(0.12, 0.14, 0.20, 0.9)
	ac_style.border_width_left = 3
	ac_style.border_color = Color(0.9, 0.75, 0.25)
	ac_style.set_corner_radius_all(6)
	ac_style.content_margin_left = 14
	ac_style.content_margin_top = 12
	ac_style.content_margin_right = 14
	ac_style.content_margin_bottom = 12
	act_card.add_theme_stylebox_override("panel", ac_style)
	vbox.add_child(act_card)

	var ac_vbox = VBoxContainer.new()
	ac_vbox.add_theme_constant_override("separation", 6)
	act_card.add_child(ac_vbox)

	_act_title_lbl = Label.new()
	_act_title_lbl.text = "ACT I: SHADOW OVER PORT BLACKWATER"
	_act_title_lbl.add_theme_font_size_override("font_size", 18)
	_act_title_lbl.modulate = Color(1.0, 0.88, 0.4)
	ac_vbox.add_child(_act_title_lbl)

	_act_synopsis_lbl = Label.new()
	_act_synopsis_lbl.text = "Synopsis of current act..."
	_act_synopsis_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_act_synopsis_lbl.add_theme_font_size_override("font_size", 13)
	_act_synopsis_lbl.modulate = Color(0.8, 0.85, 0.9)
	ac_vbox.add_child(_act_synopsis_lbl)

	_main_objective_lbl = Label.new()
	_main_objective_lbl.text = "🎯 Objective: Restore the Harbor Cargo Crane and retrieve the Tidecaller's Compass."
	_main_objective_lbl.add_theme_font_size_override("font_size", 14)
	_main_objective_lbl.modulate = Color(0.4, 0.95, 0.6)
	ac_vbox.add_child(_main_objective_lbl)

	# Two-Column Layout: Bounties & World Restorations
	var cols = HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 20)
	vbox.add_child(cols)

	# Left Column: Active Bounties
	var b_col = VBoxContainer.new()
	b_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_col.add_theme_constant_override("separation", 8)
	cols.add_child(b_col)

	var b_header = Label.new()
	b_header.text = "📜 SANCTUARY GUILD BOUNTIES"
	b_header.add_theme_font_size_override("font_size", 15)
	b_header.modulate = Color(0.85, 0.75, 0.3)
	b_col.add_child(b_header)

	_bounties_list = VBoxContainer.new()
	_bounties_list.add_theme_constant_override("separation", 8)
	b_col.add_child(_bounties_list)

	# Right Column: World Restoration Projects
	var r_col = VBoxContainer.new()
	r_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_col.add_theme_constant_override("separation", 8)
	cols.add_child(r_col)

	var r_header = Label.new()
	r_header.text = "🔨 REALM STRUCTURE RESTORATION"
	r_header.add_theme_font_size_override("font_size", 15)
	r_header.modulate = Color(0.4, 0.85, 0.95)
	r_col.add_child(r_header)

	_restoration_list = VBoxContainer.new()
	_restoration_list.add_theme_constant_override("separation", 8)
	r_col.add_child(_restoration_list)

	return scroll

# --- TAB 1: HERO SHEET & TALENTS ---
func _build_tab1_hero_sheet() -> Control:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)

	# Hero Overview Card
	var hero_card = PanelContainer.new()
	var hc_style = StyleBoxFlat.new()
	hc_style.bg_color = Color(0.10, 0.12, 0.18, 0.9)
	hc_style.border_width_left = 3
	hc_style.border_color = Color(0.35, 0.75, 1.0)
	hc_style.set_corner_radius_all(6)
	hc_style.content_margin_left = 14
	hc_style.content_margin_top = 10
	hc_style.content_margin_right = 14
	hc_style.content_margin_bottom = 10
	hero_card.add_theme_stylebox_override("panel", hc_style)
	vbox.add_child(hero_card)

	var hc_hbox = HBoxContainer.new()
	hc_hbox.add_theme_constant_override("separation", 16)
	hero_card.add_child(hc_hbox)

	var hc_vbox = VBoxContainer.new()
	hc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hc_hbox.add_child(hc_vbox)

	_hero_title_lbl = Label.new()
	_hero_title_lbl.text = "KNIGHT — IRON VANGUARD"
	_hero_title_lbl.add_theme_font_size_override("font_size", 19)
	_hero_title_lbl.modulate = Color(1.0, 0.9, 0.45)
	hc_vbox.add_child(_hero_title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = "A stalwart protector clad in plate mail. Exceptional survivability and devastating sweeping cleaves."
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color(0.75, 0.82, 0.9)
	hc_vbox.add_child(desc_lbl)

	# Attributes Grid
	var stat_grid = GridContainer.new()
	stat_grid.columns = 3
	stat_grid.add_theme_constant_override("h_separation", 14)
	stat_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(stat_grid)

	_hp_val_lbl = _add_stat_box(stat_grid, "❤️ Vitality (HP)", "100 / 100", Color(0.3, 0.9, 0.4))
	_atk_val_lbl = _add_stat_box(stat_grid, "⚔️ Attack Power", "25 DMG", Color(1.0, 0.4, 0.4))
	_def_val_lbl = _add_stat_box(stat_grid, "🛡️ Damage Reduction", "20%", Color(0.4, 0.75, 1.0))
	_spd_val_lbl = _add_stat_box(stat_grid, "⚡ Movement Speed", "6.5 m/s", Color(1.0, 0.85, 0.3))
	_crit_val_lbl = _add_stat_box(stat_grid, "🎯 Critical Strike", "15% (x2.0)", Color(0.9, 0.4, 0.9))
	_add_stat_box(stat_grid, "💨 Dash Cooldown", "0.9 sec", Color(0.4, 0.95, 0.8))

	# Class Specialization Talents
	var t_header = Label.new()
	t_header.text = "🌟 CLASS SPECIALIZATION TALENTS"
	t_header.add_theme_font_size_override("font_size", 15)
	t_header.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(t_header)

	_talents_container = VBoxContainer.new()
	_talents_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_talents_container)

	# Equipped Relics Section
	var r_header = Label.new()
	r_header.text = "💎 EQUIPPED SOUL RELICS & BOONS"
	r_header.add_theme_font_size_override("font_size", 15)
	r_header.modulate = Color(0.2, 0.9, 0.85)
	vbox.add_child(r_header)

	_relics_container = HFlowContainer.new()
	_relics_container.add_theme_constant_override("h_separation", 10)
	_relics_container.add_theme_constant_override("v_separation", 10)
	vbox.add_child(_relics_container)

	return scroll

func _add_stat_box(parent: Control, label_text: String, val_text: String, val_col: Color) -> Label:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 56)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.16, 0.9)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.2, 0.25, 0.35)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_top = 6
	sb.content_margin_right = 12
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var v = VBoxContainer.new()
	panel.add_child(v)

	var l = Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(0.65, 0.7, 0.8)
	v.add_child(l)

	var v_lbl = Label.new()
	v_lbl.text = val_text
	v_lbl.add_theme_font_size_override("font_size", 16)
	v_lbl.modulate = val_col
	v.add_child(v_lbl)
	return v_lbl

# --- TAB 2: CODEX ---
func _build_tab2_codex() -> Control:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)

	# Left Codex Chapters List
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(280, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp_style = StyleBoxFlat.new()
	lp_style.bg_color = Color(0.07, 0.08, 0.12, 0.9)
	lp_style.set_corner_radius_all(6)
	lp_style.content_margin_left = 8
	lp_style.content_margin_top = 8
	lp_style.content_margin_right = 8
	lp_style.content_margin_bottom = 8
	left_panel.add_theme_stylebox_override("panel", lp_style)
	hbox.add_child(left_panel)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left_scroll)

	var chapters_vbox = VBoxContainer.new()
	chapters_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapters_vbox.add_theme_constant_override("separation", 8)
	left_scroll.add_child(chapters_vbox)

	for i in range(CODEX_ENTRIES.size()):
		var entry = CODEX_ENTRIES[i]
		var btn = Button.new()
		btn.text = entry["title"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(250, 44)
		var c_idx = i
		btn.pressed.connect(func(): _select_codex(c_idx))
		chapters_vbox.add_child(btn)

	# Right Lore Viewer
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color(0.08, 0.10, 0.15, 0.95)
	rp_style.border_width_left = 2
	rp_style.border_color = Color(0.85, 0.72, 0.35, 0.6)
	rp_style.set_corner_radius_all(6)
	rp_style.content_margin_left = 20
	rp_style.content_margin_top = 16
	rp_style.content_margin_right = 20
	rp_style.content_margin_bottom = 16
	right_panel.add_theme_stylebox_override("panel", rp_style)
	hbox.add_child(right_panel)

	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_scroll)

	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 14)
	right_scroll.add_child(right_vbox)

	_codex_title_lbl = Label.new()
	_codex_title_lbl.add_theme_font_size_override("font_size", 20)
	_codex_title_lbl.modulate = Color(1.0, 0.88, 0.4)
	right_vbox.add_child(_codex_title_lbl)

	_codex_body_lbl = Label.new()
	_codex_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codex_body_lbl.add_theme_font_size_override("font_size", 14)
	_codex_body_lbl.modulate = Color(0.85, 0.9, 0.95)
	right_vbox.add_child(_codex_body_lbl)

	_select_codex(0)
	return hbox

func _select_codex(idx: int) -> void:
	_selected_codex_idx = idx
	if idx >= 0 and idx < CODEX_ENTRIES.size():
		var entry = CODEX_ENTRIES[idx]
		_codex_title_lbl.text = entry["chapter"] + "\n" + entry["title"]
		_codex_body_lbl.text = entry["content"]

# --- DATA REFRESH ---
func _refresh_data() -> void:
	_refresh_chronicles()
	_refresh_hero_sheet()

func _refresh_chronicles() -> void:
	var act_info = GameManager.get_current_act_info()
	if _act_title_lbl:
		_act_title_lbl.text = act_info.get("title", "Act " + str(act_info.get("act", 1))).to_upper()
	if _act_synopsis_lbl:
		_act_synopsis_lbl.text = act_info.get("synopsis", "")
	if _main_objective_lbl:
		_main_objective_lbl.text = "🎯 Objective: " + act_info.get("main_objective", "")

	# Populate Bounties
	if _bounties_list:
		for c in _bounties_list.get_children():
			c.queue_free()
		for mission in GameManager.missions:
			var panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.09, 0.11, 0.16, 0.9)
			style.set_corner_radius_all(4)
			style.content_margin_left = 10
			style.content_margin_top = 8
			style.content_margin_right = 10
			style.content_margin_bottom = 8
			panel.add_theme_stylebox_override("panel", style)
			_bounties_list.add_child(panel)

			var v = VBoxContainer.new()
			panel.add_child(v)

			var cur_p = mission.get("progress", 0)
			var max_p = mission.get("target_progress", 1)
			var is_done = mission.get("completed", false)

			var name_l = Label.new()
			name_l.text = mission.get("title", "Bounty") + (" [COMPLETED]" if is_done else (" (" + str(cur_p) + "/" + str(max_p) + ")"))
			name_l.modulate = Color(0.4, 0.9, 0.4) if is_done else Color(1.0, 0.85, 0.3)
			name_l.add_theme_font_size_override("font_size", 13)
			v.add_child(name_l)

			var desc_l = Label.new()
			desc_l.text = mission.get("description", "")
			desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_l.add_theme_font_size_override("font_size", 11)
			desc_l.modulate = Color(0.7, 0.75, 0.8)
			v.add_child(desc_l)

	# Populate World Restorations
	if _restoration_list:
		for c in _restoration_list.get_children():
			c.queue_free()

		var repairs_data = [
			{
				"id": "port_crane",
				"name": "⚓ Port Blackwater Cargo Crane",
				"req": "Requires: 1 Lumber + 1 Iron Ore",
				"reward": "Restores harbor shipping & earns 150 Gold",
				"done": GameManager.world_repairs.get("port_crane", false)
			},
			{
				"id": "druid_altar",
				"name": "🌲 Whisperwood Sun Altar",
				"req": "Requires: 1 Arcane Crystal + 1 Emerald",
				"reward": "Cleanses forest miasma & earns druidic boon",
				"done": GameManager.world_repairs.get("druid_altar", false)
			},
			{
				"id": "smelter_bellows",
				"name": "🔥 Khar-Drakken Smelter Bellows",
				"req": "Requires: 1 Gold Ingot + 1 Iron Ore",
				"reward": "Ignites runeforge & enables Masterwork Tempering",
				"done": GameManager.world_repairs.get("smelter_bellows", false)
			}
		]

		for item in repairs_data:
			var panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.09, 0.11, 0.16, 0.9)
			style.set_corner_radius_all(4)
			style.content_margin_left = 10
			style.content_margin_top = 8
			style.content_margin_right = 10
			style.content_margin_bottom = 8
			panel.add_theme_stylebox_override("panel", style)
			_restoration_list.add_child(panel)

			var v = VBoxContainer.new()
			panel.add_child(v)

			var r_title = Label.new()
			r_title.text = item["name"] + (" [REPAIRED]" if item["done"] else " [IN RUINS]")
			r_title.modulate = Color(0.3, 0.9, 0.5) if item["done"] else Color(0.95, 0.65, 0.25)
			r_title.add_theme_font_size_override("font_size", 13)
			v.add_child(r_title)

			var r_desc = Label.new()
			r_desc.text = item["reward"] if item["done"] else (item["req"] + " — " + item["reward"])
			r_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			r_desc.add_theme_font_size_override("font_size", 11)
			r_desc.modulate = Color(0.7, 0.75, 0.8)
			v.add_child(r_desc)

func _refresh_hero_sheet() -> void:
	var hero_class = GameManager.selected_class
	var class_names = ["Knight", "Rogue", "Mage", "Barbarian"]
	var class_titles = ["Knight — Iron Vanguard", "Rogue — Shadowblade", "Mage — Archmagus", "Barbarian — Berserker King"]
	var c_name = class_names[hero_class] if hero_class >= 0 and hero_class < class_names.size() else "Adventurer"
	var c_title = class_titles[hero_class] if hero_class >= 0 and hero_class < class_titles.size() else "Hero of Aethelgard"

	if _hero_title_lbl:
		_hero_title_lbl.text = c_title.to_upper()

	var stats = GameManager.get_base_hero_stats(hero_class)
	var player = get_tree().get_first_node_in_group("player")
	var cur_hp = player.current_health if (player and "current_health" in player) else stats.get("max_health", 100)
	var max_hp = player.max_health if (player and "max_health" in player) else stats.get("max_health", 100)

	if _hp_val_lbl:
		_hp_val_lbl.text = str(int(cur_hp)) + " / " + str(int(max_hp)) + " HP"
	if _atk_val_lbl:
		_atk_val_lbl.text = str(int(stats.get("attack_damage", 20))) + " DMG"
	if _def_val_lbl:
		var absorbs = []
		if GameManager.has_boon("paladins_ward"): absorbs.append("20% Ward")
		if GameManager.has_boon("knight_crest"): absorbs.append("15% Crest")
		_def_val_lbl.text = (" + ".join(absorbs)) if absorbs.size() > 0 else "Base Armor (0%)"
	if _spd_val_lbl:
		_spd_val_lbl.text = str(snapped(stats.get("move_speed", 6.0), 0.1)) + " m/s"
	if _crit_val_lbl:
		var crit_p = int(stats.get("crit_chance", 0.1) * 100.0)
		_crit_val_lbl.text = str(crit_p) + "% (x2.0 DMG)"

	# Populate Talents
	if _talents_container:
		for c in _talents_container.get_children():
			c.queue_free()
		
		var talents_map = {
			0: [
				{"name": "🛡️ Paladin's Ward", "desc": "Wards the hero with divine aura, absorbing 20% of all incoming damage.", "id": "paladins_ward"},
				{"name": "⚔️ Titan's Cleave", "desc": "Sword sweeps cleave a devastating 35% wider arc, striking all adjacent foes.", "id": "titans_cleave"}
			],
			1: [
				{"name": "💨 Shadowstep", "desc": "Grants extended invulnerability frames during dash and +30% dash travel distance.", "id": "shadowstep"},
				{"name": "🗡️ Venomous Blades", "desc": "Dagger strikes inflict toxic venom, dealing continuous damage over time.", "id": "venomous_blades"}
			],
			2: [
				{"name": "⚡ Arcane Chain", "desc": "Spell bolts pierce primary targets and arc lightning to secondary foes.", "id": "arcane_chain"},
				{"name": "❄️ Frost Nova", "desc": "Releases an icy pulse upon taking heavy hits, chilling nearby enemies.", "id": "frost_nova"}
			],
			3: [
				{"name": "🩸 Berserker Rage", "desc": "Attack damage progressively surges up to +50% as health drops below 50%.", "id": "berserker_rage"},
				{"name": "🦬 Unstoppable Juggernaut", "desc": "Grants complete knockback immunity and +25% maximum health bonus.", "id": "unstoppable_juggernaut"}
			]
		}

		var hero_talents = talents_map.get(hero_class, talents_map[0])
		for talent in hero_talents:
			var unlocked = GameManager.has_boon(talent["id"]) or true # Specialization is active for chosen class
			var card = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.14, 0.20, 0.95) if unlocked else Color(0.08, 0.08, 0.10, 0.7)
			style.border_width_left = 2
			style.border_color = Color(0.9, 0.75, 0.3) if unlocked else Color(0.3, 0.3, 0.35)
			style.set_corner_radius_all(5)
			style.content_margin_left = 12
			style.content_margin_top = 8
			style.content_margin_right = 12
			style.content_margin_bottom = 8
			card.add_theme_stylebox_override("panel", style)
			_talents_container.add_child(card)

			var v = VBoxContainer.new()
			card.add_child(v)

			var t_name = Label.new()
			t_name.text = talent["name"] + (" [ACTIVE SPECIALIZATION]" if unlocked else " [LOCKED]")
			t_name.modulate = Color(1.0, 0.88, 0.35) if unlocked else Color(0.5, 0.5, 0.55)
			t_name.add_theme_font_size_override("font_size", 13)
			v.add_child(t_name)

			var t_desc = Label.new()
			t_desc.text = talent["desc"]
			t_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t_desc.add_theme_font_size_override("font_size", 11)
			t_desc.modulate = Color(0.8, 0.85, 0.9) if unlocked else Color(0.5, 0.5, 0.55)
			v.add_child(t_desc)

	# Populate Relics
	if _relics_container:
		for c in _relics_container.get_children():
			c.queue_free()

		if GameManager.relic_boons.size() == 0:
			var empty_l = Label.new()
			empty_l.text = "No soul relics collected yet. Brave the Catacomb descents or complete world quests to claim ancient artifacts!"
			empty_l.add_theme_font_size_override("font_size", 12)
			empty_l.modulate = Color(0.6, 0.65, 0.7)
			_relics_container.add_child(empty_l)
		else:
			for boon in GameManager.relic_boons:
				var badge = PanelContainer.new()
				badge.custom_minimum_size = Vector2(210, 54)
				var b_style = StyleBoxFlat.new()
				b_style.bg_color = Color(0.10, 0.12, 0.16, 0.95)
				b_style.border_width_left = 2
				b_style.border_color = boon.get("color", Color(0.8, 0.8, 0.8))
				b_style.set_corner_radius_all(4)
				b_style.content_margin_left = 8
				b_style.content_margin_top = 4
				b_style.content_margin_right = 8
				b_style.content_margin_bottom = 4
				badge.add_theme_stylebox_override("panel", b_style)
				_relics_container.add_child(badge)

				var bv = VBoxContainer.new()
				badge.add_child(bv)

				var b_n = Label.new()
				b_n.text = boon.get("name", "Relic")
				b_n.add_theme_font_size_override("font_size", 12)
				b_n.modulate = boon.get("color", Color(0.9, 0.9, 0.9))
				bv.add_child(b_n)

				var b_d = Label.new()
				b_d.text = boon.get("description", "")
				b_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b_d.add_theme_font_size_override("font_size", 10)
				b_d.modulate = Color(0.7, 0.75, 0.8)
				bv.add_child(b_d)
