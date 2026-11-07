extends Control
class_name MainMenu

signal start_descent_requested()
signal campaign_started(is_new_campaign: bool, chosen_class: int, use_top_down: bool)
signal resume_requested()
signal return_to_title_requested()

var is_pause_mode: bool = false
var selected_hero_class: int = 0
var prefer_top_down_camera: bool = false

var _backdrop: ColorRect = null
var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var creator_credit_label: Label = null
var footer_credit_label: Label = null
var _save_summary_lbl: Label = null
var _status_feedback_lbl: Label = null

var _continue_btn: Button = null
var _new_game_btn: Button = null
var _resume_btn: Button = null
var _save_btn: Button = null
var _return_title_btn: Button = null
var _camera_pref_btn: Button = null
var _guide_pref_btn: Button = null

var _class_buttons: Array[Button] = []
var _settings_panel: PanelContainer = null
var _controls_panel: PanelContainer = null
var _volume_slider: HSlider = null
var _volume_val_lbl: Label = null
var _fullscreen_btn: Button = null

const CLASS_DATA: Array[Dictionary] = [
	{
		"id": 0,
		"name": "🛡️ Knight — Royal Vanguard",
		"desc": "Armored Sentinel • Sword & Shield Parry + Heavy Crossbow • 120 HP | 24 ATK | 10 DEF"
	},
	{
		"id": 1,
		"name": "🏹 Rogue — Shadow Marksman",
		"desc": "Swift Ranger • Twin Daggers + Recurve Longbow • 95 HP | 26 ATK | High Crit & Speed"
	},
	{
		"id": 2,
		"name": "🔮 Mage — Arcane Scholar",
		"desc": "Battle Mystic • Runed Staff + Arcane Ward Mastery • 90 HP | 28 ATK | Spell Burst"
	},
	{
		"id": 3,
		"name": "🪓 Barbarian — Iron Berserker",
		"desc": "Heavy Warlord • Two-Handed Great Axe Cleave • 135 HP | 32 ATK | High Stagger"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	selected_hero_class = int(GameManager.selected_class)
	_build_menu_ui()
	_refresh_menu_state()

func _build_menu_ui() -> void:
	# 1. Cinematic Semi-Transparent Backdrop (allows live 3D kingdom vista behind menu)
	_backdrop = ColorRect.new()
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_bottom = 1.0
	_backdrop.color = Color(0.03, 0.04, 0.07, 0.58)
	add_child(_backdrop)

	# 2. Main Centered Royal Frame
	var center_wrap = CenterContainer.new()
	center_wrap.anchor_right = 1.0
	center_wrap.anchor_bottom = 1.0
	add_child(center_wrap)

	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(1060, 635)
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.07, 0.08, 0.12, 0.94)
	panel_sb.border_color = Color(0.86, 0.70, 0.30, 0.96)
	panel_sb.set_border_width_all(3)
	panel_sb.set_corner_radius_all(12)
	panel_sb.content_margin_left = 26
	panel_sb.content_margin_right = 26
	panel_sb.content_margin_top = 20
	panel_sb.content_margin_bottom = 18
	main_panel.add_theme_stylebox_override("panel", panel_sb)
	center_wrap.add_child(main_panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(root_vbox)

	# 3. Header Section: Title, Subtitle & Creator Credit Pill
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	root_vbox.add_child(header_vbox)

	var mf = AssetLoader.get_medieval_font()

	_title_lbl = Label.new()
	_title_lbl.text = "⚔️ ECHOES OF THE OSSUARY ⚔️"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if mf:
		_title_lbl.add_theme_font_override("font", mf)
	_title_lbl.add_theme_font_size_override("font_size", 38)
	_title_lbl.add_theme_constant_override("outline_size", 8)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.98))
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.44))
	header_vbox.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.text = "CHRONICLES OF OAKHAVEN • COMBINED-ARMS SIEGE & HIGH-SEAS WARFARE"
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.add_theme_font_size_override("font_size", 14)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98))
	header_vbox.add_child(_subtitle_lbl)

	# Prominent Creator Credit Badge in Header
	var creator_center = CenterContainer.new()
	header_vbox.add_child(creator_center)

	var creator_pill = PanelContainer.new()
	var pill_sb = StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.14, 0.11, 0.05, 0.96)
	pill_sb.border_color = Color(0.95, 0.78, 0.28, 0.95)
	pill_sb.set_border_width_all(1)
	pill_sb.set_corner_radius_all(6)
	pill_sb.content_margin_left = 18
	pill_sb.content_margin_right = 18
	pill_sb.content_margin_top = 4
	pill_sb.content_margin_bottom = 4
	creator_pill.add_theme_stylebox_override("panel", pill_sb)
	creator_center.add_child(creator_pill)

	creator_credit_label = Label.new()
	creator_credit_label.text = "👑 Created by daryl.created@gmail.com"
	creator_credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if mf:
		creator_credit_label.add_theme_font_override("font", mf)
	creator_credit_label.add_theme_font_size_override("font_size", 18)
	creator_credit_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	creator_pill.add_child(creator_credit_label)

	var sep_top = HSeparator.new()
	root_vbox.add_child(sep_top)

	# 4. Two-Column Main Body
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 20)
	root_vbox.add_child(body_hbox)

	# --- LEFT COLUMN: Hero Class & Camera/Guide Preferences ---
	var left_card = PanelContainer.new()
	left_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_card.size_flags_stretch_ratio = 1.15
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.10, 0.12, 0.17, 0.92)
	card_sb.border_color = Color(0.45, 0.38, 0.22, 0.85)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 16
	card_sb.content_margin_right = 16
	card_sb.content_margin_top = 14
	card_sb.content_margin_bottom = 14
	left_card.add_theme_stylebox_override("panel", card_sb)
	body_hbox.add_child(left_card)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_card.add_child(left_vbox)

	var class_hdr = Label.new()
	class_hdr.text = "🛡️ CHOOSE YOUR CHAMPION'S MANTLE"
	class_hdr.add_theme_font_size_override("font_size", 16)
	class_hdr.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	left_vbox.add_child(class_hdr)

	_class_buttons.clear()
	for c_info in CLASS_DATA:
		var cid: int = int(c_info["id"])
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "%s\n   %s" % [c_info["name"], c_info["desc"]]
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func(): _select_hero_class(cid))
		left_vbox.add_child(btn)
		_class_buttons.append(btn)

	var pref_hdr = Label.new()
	pref_hdr.text = "🎥 CAMERA VIEW & STORY GUIDE PREFERENCES"
	pref_hdr.add_theme_font_size_override("font_size", 15)
	pref_hdr.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	left_vbox.add_child(pref_hdr)

	_camera_pref_btn = Button.new()
	_camera_pref_btn.custom_minimum_size = Vector2(0, 38)
	_camera_pref_btn.focus_mode = Control.FOCUS_NONE
	_camera_pref_btn.pressed.connect(_toggle_camera_preference)
	left_vbox.add_child(_camera_pref_btn)

	_guide_pref_btn = Button.new()
	_guide_pref_btn.custom_minimum_size = Vector2(0, 38)
	_guide_pref_btn.focus_mode = Control.FOCUS_NONE
	_guide_pref_btn.pressed.connect(_toggle_guide_preference)
	left_vbox.add_child(_guide_pref_btn)

	# --- RIGHT COLUMN: Campaign Actions, Settings & Controls ---
	var right_card = PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.size_flags_stretch_ratio = 1.0
	right_card.add_theme_stylebox_override("panel", card_sb.duplicate())
	body_hbox.add_child(right_card)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 9)
	right_card.add_child(right_vbox)

	var act_hdr = Label.new()
	act_hdr.text = "📜 ROYAL CAMPAIGN COMMAND"
	act_hdr.add_theme_font_size_override("font_size", 16)
	act_hdr.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	right_vbox.add_child(act_hdr)

	_save_summary_lbl = Label.new()
	_save_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_save_summary_lbl.add_theme_font_size_override("font_size", 13)
	_save_summary_lbl.add_theme_color_override("font_color", Color(0.86, 0.94, 0.86))
	right_vbox.add_child(_save_summary_lbl)

	# Primary Action Buttons
	_continue_btn = _make_menu_button("▶ CONTINUE CAMPAIGN", Color(0.16, 0.46, 0.26), Color(0.45, 0.95, 0.60))
	_continue_btn.pressed.connect(_on_continue_pressed)
	right_vbox.add_child(_continue_btn)

	_new_game_btn = _make_menu_button("⚔️ START NEW CAMPAIGN", Color(0.48, 0.34, 0.12), Color(1.0, 0.85, 0.35))
	_new_game_btn.pressed.connect(_on_new_campaign_pressed)
	right_vbox.add_child(_new_game_btn)

	_resume_btn = _make_menu_button("▶ RESUME ADVENTURE [Esc]", Color(0.16, 0.46, 0.26), Color(0.45, 0.95, 0.60))
	_resume_btn.pressed.connect(_on_resume_pressed)
	right_vbox.add_child(_resume_btn)

	_save_btn = _make_menu_button("💾 SAVE CAMPAIGN PROGRESS", Color(0.18, 0.34, 0.52), Color(0.55, 0.85, 1.0))
	_save_btn.pressed.connect(_on_save_pressed)
	right_vbox.add_child(_save_btn)

	var settings_btn = _make_menu_button("⚙️ AUDIO & DISPLAY SETTINGS", Color(0.22, 0.25, 0.34), Color(0.75, 0.82, 0.95))
	settings_btn.pressed.connect(_toggle_settings_subpanel)
	right_vbox.add_child(settings_btn)

	var controls_btn = _make_menu_button("📖 CONTROLS & WARFARE GUIDE", Color(0.22, 0.25, 0.34), Color(0.75, 0.82, 0.95))
	controls_btn.pressed.connect(_toggle_controls_subpanel)
	right_vbox.add_child(controls_btn)

	_return_title_btn = _make_menu_button("🏰 RETURN TO OPENING TITLE SCREEN", Color(0.38, 0.26, 0.14), Color(0.95, 0.78, 0.42))
	_return_title_btn.pressed.connect(_on_return_to_title_pressed)
	right_vbox.add_child(_return_title_btn)

	var quit_btn = _make_menu_button("🚪 QUIT TO DESKTOP", Color(0.42, 0.16, 0.16), Color(0.95, 0.48, 0.48))
	quit_btn.pressed.connect(_on_quit_button_pressed)
	right_vbox.add_child(quit_btn)

	_status_feedback_lbl = Label.new()
	_status_feedback_lbl.text = ""
	_status_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_feedback_lbl.add_theme_font_size_override("font_size", 14)
	_status_feedback_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65))
	right_vbox.add_child(_status_feedback_lbl)

	# Collapsible Sub-Panels (Settings & Controls)
	_build_settings_subpanel(right_vbox)
	_build_controls_subpanel(right_vbox)

	# 5. Footer Attribution Bar
	var sep_bot = HSeparator.new()
	root_vbox.add_child(sep_bot)

	footer_credit_label = Label.new()
	footer_credit_label.text = "✨ Created by daryl.created@gmail.com  •  Echoes of the Ossuary — AA Medieval Action-RPG & Tactical Warfare Edition ✨"
	footer_credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_credit_label.add_theme_font_size_override("font_size", 14)
	footer_credit_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.58))
	root_vbox.add_child(footer_credit_label)

func _make_menu_button(label_text: String, bg_col: Color, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 38)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15)
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	var hover_sb = sb.duplicate()
	hover_sb.bg_color = bg_col.lightened(0.16)
	btn.add_theme_stylebox_override("hover", hover_sb)
	return btn

func _build_settings_subpanel(parent: VBoxContainer) -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	sb.border_color = Color(0.55, 0.75, 0.95, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_settings_panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(_settings_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_settings_panel.add_child(vbox)

	var vol_hbox = HBoxContainer.new()
	vbox.add_child(vol_hbox)

	var vol_lbl = Label.new()
	vol_lbl.text = "🔊 Master Volume:"
	vol_lbl.add_theme_font_size_override("font_size", 13)
	vol_hbox.add_child(vol_lbl)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 5.0
	_volume_slider.value = 85.0
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.value_changed.connect(_on_volume_changed)
	vol_hbox.add_child(_volume_slider)

	_volume_val_lbl = Label.new()
	_volume_val_lbl.text = "85%"
	_volume_val_lbl.add_theme_font_size_override("font_size", 13)
	vol_hbox.add_child(_volume_val_lbl)

	_fullscreen_btn = Button.new()
	_fullscreen_btn.text = "🖥️ Toggle Windowed / Fullscreen"
	_fullscreen_btn.focus_mode = Control.FOCUS_NONE
	_fullscreen_btn.pressed.connect(_on_toggle_fullscreen)
	vbox.add_child(_fullscreen_btn)

func _build_controls_subpanel(parent: VBoxContainer) -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	sb.border_color = Color(0.85, 0.72, 0.35, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_controls_panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(_controls_panel)

	var lbl = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	lbl.text = (
		"• Movement & Dash: [WASD] Move  |  [Space] Dodge Dash  |  [F] Summon/Mount Warsteed\n" +
		"• Combat & Stances: [LMB / J] Melee Combo  |  [RMB / K] Shield Parry  |  [Q] Swap Melee / Ranged Bow\n" +
		"• World & Story UI: [E] Interact/Talk  |  [H] Story Guide Pop-Up  |  [N] Realm Map  |  [L] Lore  |  [M] Quests\n" +
		"• Camera & Warfare: [V] Switch Camera (Action-RPG / Top-Down)  |  [Keys 1-5] Tactical Army & Naval Orders"
	)
	_controls_panel.add_child(lbl)

func open_title_screen() -> void:
	is_pause_mode = false
	visible = true
	if _status_feedback_lbl:
		_status_feedback_lbl.text = ""
	_refresh_menu_state()

func open_pause_menu() -> void:
	is_pause_mode = true
	visible = true
	if _status_feedback_lbl:
		_status_feedback_lbl.text = ""
	_refresh_menu_state()

func _refresh_menu_state() -> void:
	if not _title_lbl:
		return

	if _backdrop:
		_backdrop.color = Color(0.02, 0.03, 0.06, 0.76) if is_pause_mode else Color(0.03, 0.04, 0.07, 0.54)

	if is_pause_mode:
		_title_lbl.text = "⏸️ ECHOES OF THE OSSUARY — PAUSED"
		_subtitle_lbl.text = "CAMPAIGN IN PROGRESS • ADJUST SETTINGS, SAVE OR RESUME"
	else:
		_title_lbl.text = "⚔️ ECHOES OF THE OSSUARY ⚔️"
		_subtitle_lbl.text = "CHRONICLES OF OAKHAVEN • COMBINED-ARMS SIEGE & HIGH-SEAS WARFARE"

	if _continue_btn:
		_continue_btn.visible = not is_pause_mode
	if _new_game_btn:
		_new_game_btn.visible = not is_pause_mode
	if _resume_btn:
		_resume_btn.visible = is_pause_mode
	if _save_btn:
		_save_btn.visible = is_pause_mode
	if _return_title_btn:
		_return_title_btn.visible = is_pause_mode

	# Update Class Button Highlights
	for i in range(_class_buttons.size()):
		var btn = _class_buttons[i]
		var is_sel = (i == selected_hero_class)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.24, 0.20, 0.08, 0.96) if is_sel else Color(0.12, 0.14, 0.20, 0.90)
		sb.border_color = Color(1.0, 0.86, 0.32, 1.0) if is_sel else Color(0.32, 0.36, 0.46, 0.8)
		sb.set_border_width_all(2 if is_sel else 1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)

	# Update Camera & Guide Buttons
	if _camera_pref_btn:
		_camera_pref_btn.text = "🦅 Starting View: Top-Down Tactical (82° Pitch)" if prefer_top_down_camera else "⚔️ Starting View: Action-RPG (36° Pitch)"
	if _guide_pref_btn:
		_guide_pref_btn.text = "📜 Story Guide Pop-Up: ENABLED [H]" if GameManager.story_guide_enabled else "📜 Story Guide Pop-Up: HIDDEN [H]"

	# Update Save / Campaign Status Summary
	if _save_summary_lbl:
		var q = GameManager.get_current_campaign_quest()
		var chap_str = q.get("chapter", "Chapter I")
		_save_summary_lbl.text = (
			"Active Champion: Lv.%d %s\n" % [GameManager.hero_level, GameManager.hero_title] +
			"Current Chronicle: %s\n" % chap_str +
			"Treasury: %d Gold  •  %d Soul Echoes" % [GameManager.gold, GameManager.soul_echoes]
		)

func _select_hero_class(class_id: int) -> void:
	selected_hero_class = class_id
	GameManager.set_hero_class(class_id as GameManager.HeroClass)
	AudioManager.play_sfx("ui_switch", 0.05, 0.0)
	_refresh_menu_state()

func _toggle_camera_preference() -> void:
	prefer_top_down_camera = not prefer_top_down_camera
	AudioManager.play_sfx("ui_switch", 0.05, 0.0)
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("apply_camera_preset"):
		main_node.apply_camera_preset(4 if prefer_top_down_camera else 0, false)
	_refresh_menu_state()

func _toggle_guide_preference() -> void:
	GameManager.toggle_story_guide()
	AudioManager.play_sfx("ui_switch", 0.05, 0.0)
	_refresh_menu_state()

func _toggle_settings_subpanel() -> void:
	AudioManager.play_sfx("button_click", 0.05, 0.0)
	if _settings_panel:
		_settings_panel.visible = not _settings_panel.visible
	if _controls_panel and _settings_panel and _settings_panel.visible:
		_controls_panel.visible = false

func _toggle_controls_subpanel() -> void:
	AudioManager.play_sfx("button_click", 0.05, 0.0)
	if _controls_panel:
		_controls_panel.visible = not _controls_panel.visible
	if _settings_panel and _controls_panel and _controls_panel.visible:
		_settings_panel.visible = false

func _on_volume_changed(val: float) -> void:
	if _volume_val_lbl:
		_volume_val_lbl.text = "%d%%" % int(round(val))
	var linear = clampf(val / 100.0, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(linear))
	AudioServer.set_bus_mute(0, val <= 0.5)

func _on_toggle_fullscreen() -> void:
	AudioManager.play_sfx("button_click", 0.05, 0.0)
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("sfx_victory_fanfare", 0.05, -2.0)
	GameManager.set_hero_class(selected_hero_class as GameManager.HeroClass)
	hide()
	start_descent_requested.emit()
	campaign_started.emit(false, selected_hero_class, prefer_top_down_camera)

func _on_new_campaign_pressed() -> void:
	AudioManager.play_sfx("sfx_victory_fanfare", 0.05, -2.0)
	GameManager.reset_for_new_campaign(selected_hero_class as GameManager.HeroClass)
	hide()
	start_descent_requested.emit()
	campaign_started.emit(true, selected_hero_class, prefer_top_down_camera)

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("button_click", 0.05, 0.0)
	hide()
	resume_requested.emit()

func _on_save_pressed() -> void:
	GameManager.save_game()
	AudioManager.play_sfx("level_up", 0.05, 0.0)
	if _status_feedback_lbl:
		_status_feedback_lbl.text = "✓ Campaign Progress Saved!"
	_refresh_menu_state()

func _on_return_to_title_pressed() -> void:
	GameManager.save_game()
	AudioManager.play_sfx("ui_switch", 0.05, 0.0)
	open_title_screen()
	return_to_title_requested.emit()

func _on_start_button_pressed() -> void:
	_on_continue_pressed()

func _on_quit_button_pressed() -> void:
	GameManager.save_game()
	get_tree().quit()
