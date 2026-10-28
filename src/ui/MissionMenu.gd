extends Control
class_name MissionMenu

signal menu_closed()

var _filter_mode: String = "all" # "all", "active", "completed"
var _cards_container: VBoxContainer = null
var _tab_all_btn: Button = null
var _tab_active_btn: Button = null
var _tab_completed_btn: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	_connect_signals()
	visible = false

func _connect_signals() -> void:
	GameManager.mission_updated.connect(func(_m): if visible: refresh_missions())
	GameManager.mission_completed.connect(func(_m): if visible: refresh_missions())
	GameManager.mission_claimed.connect(func(_m): if visible: refresh_missions())

func _setup_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.07, 0.88)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_menu()
	)
	add_child(bg)
	
	# Center Window Frame
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(760, 560)
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -380
	frame.offset_right = 380
	frame.offset_top = -280
	frame.offset_bottom = 280
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.09, 0.13, 0.96)
	frame_style.border_color = Color(0.72, 0.58, 0.28)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	frame_style.content_margin_left = 24
	frame_style.content_margin_right = 24
	frame_style.content_margin_top = 20
	frame_style.content_margin_bottom = 20
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	frame.add_child(main_vbox)
	
	# Top Header Bar
	var header_bar = HBoxContainer.new()
	main_vbox.add_child(header_bar)
	
	var header_text_vbox = VBoxContainer.new()
	header_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(header_text_vbox)
	
	var title = Label.new()
	title.text = "📜 BOUNTIES & OSSUARY MISSIONS"
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.85, 0.35)
	header_text_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Complete challenges during your descent to earn Gold and Soul Echoes."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.7, 0.75, 0.8)
	header_text_vbox.add_child(subtitle)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(close_menu)
	header_bar.add_child(close_btn)
	
	# Tabs HBox
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(tabs_hbox)
	
	_tab_all_btn = _create_tab_button("All Bounties", "all")
	_tab_active_btn = _create_tab_button("Active", "active")
	_tab_completed_btn = _create_tab_button("Completed", "completed")
	
	tabs_hbox.add_child(_tab_all_btn)
	tabs_hbox.add_child(_tab_active_btn)
	tabs_hbox.add_child(_tab_completed_btn)
	
	# Scrollable Cards Area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)
	
	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_cards_container)
	
	# Footer
	var footer = Label.new()
	footer.text = "Tip: Press [M] or [Tab] to toggle the Bounties & Missions Menu at any time."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.modulate = Color(0.55, 0.6, 0.68)
	main_vbox.add_child(footer)

func _create_tab_button(label: String, mode: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(110, 32)
	btn.pressed.connect(func():
		_filter_mode = mode
		_update_tab_styles()
		refresh_missions()
	)
	return btn

func _update_tab_styles() -> void:
	var active_color = Color(1.0, 0.85, 0.3)
	var idle_color = Color(0.7, 0.7, 0.7)
	if _tab_all_btn: _tab_all_btn.modulate = active_color if _filter_mode == "all" else idle_color
	if _tab_active_btn: _tab_active_btn.modulate = active_color if _filter_mode == "active" else idle_color
	if _tab_completed_btn: _tab_completed_btn.modulate = active_color if _filter_mode == "completed" else idle_color

func refresh_missions() -> void:
	if not _cards_container:
		return
		
	_update_tab_styles()
	
	for c in _cards_container.get_children():
		c.queue_free()
		
	var all_missions = GameManager.get_missions()
	var displayed_count = 0
	
	for m in all_missions:
		var is_done = m.get("completed", false)
		var is_claimed = m.get("claimed", false)
		
		# Filtering
		if _filter_mode == "active" and (is_done and is_claimed):
			continue
		elif _filter_mode == "completed" and not is_done:
			continue
			
		displayed_count += 1
		var card = _build_mission_card(m)
		_cards_container.add_child(card)
		
	if displayed_count == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No missions found in this category."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		empty_lbl.custom_minimum_size = Vector2(0, 100)
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_cards_container.add_child(empty_lbl)

func _build_mission_card(m: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 72)
	
	var is_completed = m.get("completed", false)
	var is_claimed = m.get("claimed", false)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.19, 0.95) if not is_completed else Color(0.14, 0.18, 0.16, 0.95)
	var border_c = Color(0.25, 0.3, 0.4)
	if is_claimed:
		border_c = Color(0.3, 0.5, 0.35)
	elif is_completed:
		border_c = Color(0.9, 0.75, 0.25)
	style.border_color = border_c
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)
	
	# Icon Box
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(44, 44)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.07, 0.08, 0.12)
	icon_style.set_corner_radius_all(6)
	icon_box.add_theme_stylebox_override("panel", icon_style)
	
	var icon_lbl = Label.new()
	icon_lbl.text = m.get("icon", "⚔")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_box.add_child(icon_lbl)
	hbox.add_child(icon_box)
	
	# Details Column
	var details_vbox = VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(details_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = m.get("title", "Mission")
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.modulate = Color(1.0, 0.9, 0.5) if is_completed else Color(0.95, 0.95, 0.95)
	details_vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = m.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color(0.72, 0.75, 0.8)
	details_vbox.add_child(desc_lbl)
	
	# Progress bar
	var cur_val = m.get("current", 0)
	var target_val = m.get("target", 1)
	
	var prog_box = HBoxContainer.new()
	prog_box.add_theme_constant_override("separation", 8)
	details_vbox.add_child(prog_box)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 10)
	bar.max_value = target_val
	bar.value = cur_val
	bar.show_percentage = false
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.85, 0.4) if is_completed else Color(0.25, 0.65, 0.9)
	bar_fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", bar_fill)
	prog_box.add_child(bar)
	
	var prog_lbl = Label.new()
	prog_lbl.text = str(cur_val) + " / " + str(target_val)
	prog_lbl.add_theme_font_size_override("font_size", 11)
	prog_lbl.modulate = Color(0.8, 0.85, 0.9)
	prog_box.add_child(prog_lbl)
	
	# Rewards & Action Column
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(170, 0)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(right_vbox)
	
	# Rewards label
	var r_gold = m.get("reward_gold", 0)
	var r_echoes = m.get("reward_echoes", 0)
	var reward_lbl = Label.new()
	reward_lbl.text = "💰 " + str(r_gold) + "   ✨ " + str(r_echoes)
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 12)
	reward_lbl.modulate = Color(1.0, 0.88, 0.4)
	right_vbox.add_child(reward_lbl)
	
	# Claim / State Button
	if is_claimed:
		var claimed_lbl = Label.new()
		claimed_lbl.text = "CLAIMED ✓"
		claimed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		claimed_lbl.add_theme_font_size_override("font_size", 12)
		claimed_lbl.modulate = Color(0.4, 0.8, 0.5)
		right_vbox.add_child(claimed_lbl)
	elif is_completed:
		var claim_btn = Button.new()
		claim_btn.text = "CLAIM REWARD"
		claim_btn.custom_minimum_size = Vector2(140, 28)
		claim_btn.modulate = Color(1.0, 0.9, 0.3)
		var m_id = m.get("id", "")
		claim_btn.pressed.connect(func():
			GameManager.claim_mission_reward(m_id)
			refresh_missions()
		)
		right_vbox.add_child(claim_btn)
	else:
		var in_prog = Label.new()
		in_prog.text = "IN PROGRESS"
		in_prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		in_prog.add_theme_font_size_override("font_size", 12)
		in_prog.modulate = Color(0.55, 0.6, 0.65)
		right_vbox.add_child(in_prog)
		
	return panel

func open_menu() -> void:
	refresh_missions()
	visible = true

func close_menu() -> void:
	visible = false
	menu_closed.emit()

func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		open_menu()
