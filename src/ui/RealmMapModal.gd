extends Control
class_name RealmMapModal

# Signals
signal region_travel_requested(region_id: String, target_pos: Vector3, region_name: String)

var _is_open: bool = false
var panel_container: PanelContainer = null
var current_loc_label: Label = null

const REGIONS = [
	{
		"id": "hub",
		"name": "🏰 Oakhaven Sanctuary & Town Hub",
		"coords": Vector3(0.0, 0.5, 3.8),
		"zone": "Central Heartland",
		"desc": "The fortified sanctuary of Oakhaven. Features the Ancient Crypt of the Ossuary, Master Torval's Forge, Eldress Alyssa's Cathedral, The Boar's Tusk Tavern, and the Royal Citadel."
	},
	{
		"id": "port",
		"name": "⚓ Port Blackwater & Coastal Harbor",
		"coords": Vector3(-58.0, 0.5, 66.0),
		"zone": "South-West Ocean Coast",
		"desc": "A windswept seaside haven for merchants, smugglers, and corsairs. Features wooden jetties stretching into the ocean, The Rusty Anchor Tavern, cargo cranes, and sandy beaches."
	},
	{
		"id": "whisperwood",
		"name": "🌲 Whisperwood Ancient Forest",
		"coords": Vector3(-78.0, 0.5, -62.0),
		"zone": "North-West Primordial Pines",
		"desc": "A dense woodland canopy alive with fireflies and ancient pine trees. Features Elder Thorne's Druidic Stone Circle, the sacred Sun Altar, and roaming timber wolf packs."
	},
	{
		"id": "crags",
		"name": "⛰️ Khar-Drakken Crags & Dwarven Mines",
		"coords": Vector3(70.0, 0.5, -55.0),
		"zone": "North-East Mountain Massifs",
		"desc": "Jagged iron peaks and deep ancestral mine shafts. Features Torvald Ironbreaker's smelting forge, blazing blast bellows, and the cliffside Orc Stronghold."
	},
	{
		"id": "farms",
		"name": "🌾 Farmlands & Grazing Pasture",
		"coords": Vector3(28.0, 0.5, 34.0),
		"zone": "South-East Pastoral Plains",
		"desc": "Rolling wheat meadows, thatched farmer cottages, pumpkin patches, and a towering windmill overlooking fully enclosed pastures filled with horses and cattle."
	}
]

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func toggle_map() -> void:
	if _is_open:
		close_map()
	else:
		open_map()

func open_map() -> void:
	_is_open = true
	visible = true
	_update_current_location()
	AudioManager.play_sfx("ui_switch", 0.08, -4.0)

func close_map() -> void:
	_is_open = false
	visible = false
	AudioManager.play_sfx("ui_switch", 0.08, -6.0)

func _update_current_location() -> void:
	if not current_loc_label:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		current_loc_label.text = "Current Position: Unknown"
		return
		
	var pos = player.global_position
	var cur_name = "Oakhaven Town Hub"
	if pos.x <= -40.0 and pos.z >= 30.0:
		cur_name = "Port Blackwater Coast"
	elif pos.x <= -40.0 and pos.z <= 0.0:
		cur_name = "Whisperwood Forest"
	elif pos.x >= 40.0 and pos.z <= 0.0:
		cur_name = "Khar-Drakken Mountain Crags"
	elif pos.x >= 20.0 and pos.z >= 28.0:
		cur_name = "Sunrise Farmlands & Pastures"
	elif pos.z >= 35.0 and abs(pos.x) <= 15.0:
		cur_name = "Royal Castle Citadel"
	elif pos.z >= 20.0 and pos.z <= 28.0:
		cur_name = "River Highway & Bridges"
		
	current_loc_label.text = "📍 You Are Currently At: %s (X: %.1f, Z: %.1f)" % [cur_name, pos.x, pos.z]

func _build_ui() -> void:
	# Full-screen translucent backdrop
	var bg = ColorRect.new()
	bg.name = "Backdrop"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.09, 0.82)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_map()
	)
	add_child(bg)

	panel_container = PanelContainer.new()
	panel_container.name = "MapPanel"
	panel_container.custom_minimum_size = Vector2(820, 540)
	panel_container.set_anchors_preset(Control.PRESET_CENTER)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.16, 0.96)
	sb.border_color = Color(0.72, 0.58, 0.28, 0.95) # Gold filigree frame
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.shadow_color = Color(0, 0, 0, 0.65)
	sb.shadow_size = 18
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel_container.add_theme_stylebox_override("panel", sb)
	add_child(panel_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel_container.add_child(vbox)

	# Title Header
	var title_bar = HBoxContainer.new()
	vbox.add_child(title_bar)

	var title_lbl = Label.new()
	title_lbl.text = "🗺️ KINGDOM REALM MAP & FAST TRAVEL"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_bar.add_child(title_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "✕ Close [N / Esc]"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close_map)
	title_bar.add_child(close_btn)

	# Subtitle / current location
	current_loc_label = Label.new()
	current_loc_label.text = "📍 Locating current position..."
	current_loc_label.add_theme_font_size_override("font_size", 13)
	current_loc_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95))
	vbox.add_child(current_loc_label)

	var div = HSeparator.new()
	vbox.add_child(div)

	# Scrollable Region List
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var region_vbox = VBoxContainer.new()
	region_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(region_vbox)

	for r in REGIONS:
		var reg_card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.12, 0.16, 0.22, 0.9)
		card_sb.border_color = Color(0.24, 0.35, 0.48, 0.8)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left = 14
		card_sb.content_margin_right = 14
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10
		reg_card.add_theme_stylebox_override("panel", card_sb)
		region_vbox.add_child(reg_card)

		var c_hbox = HBoxContainer.new()
		c_hbox.add_theme_constant_override("separation", 16)
		reg_card.add_child(c_hbox)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_hbox.add_child(info_box)

		var name_lbl = Label.new()
		name_lbl.text = r["name"]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		info_box.add_child(name_lbl)

		var zone_lbl = Label.new()
		zone_lbl.text = "Region Zone: " + r["zone"] + " (Coordinates: %.0f, %.0f)" % [r["coords"].x, r["coords"].z]
		zone_lbl.add_theme_font_size_override("font_size", 12)
		zone_lbl.add_theme_color_override("font_color", Color(0.72, 0.65, 0.45))
		info_box.add_child(zone_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = r["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
		info_box.add_child(desc_lbl)

		var travel_btn = Button.new()
		travel_btn.text = "⚡ Fast Travel"
		travel_btn.custom_minimum_size = Vector2(130, 42)
		travel_btn.focus_mode = Control.FOCUS_NONE
		travel_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var t_pos = r["coords"]
		var t_id = r["id"]
		var t_name = r["name"]
		travel_btn.pressed.connect(func():
			_execute_fast_travel(t_id, t_pos, t_name)
		)
		c_hbox.add_child(travel_btn)

func _execute_fast_travel(region_id: String, target_pos: Vector3, region_name: String) -> void:
	close_map()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Visual transition feedback
		CombatJuice.spawn_hit_spark(player.global_position + Vector3(0, 1.0, 0), Color(0.4, 0.8, 1.0))
		CombatJuice.add_trauma(0.2)
		AudioManager.play_sfx("descent_sigil", 0.08, 0.0)
		
		# Teleport player
		player.global_position = target_pos
		player.velocity = Vector3.ZERO
		
		# Re-orient camera to target
		var main = get_tree().get_first_node_in_group("main")
		if main and "reset_camera_view" in main:
			main.reset_camera_view()
			
		# Toast notification on HUD
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("📍 Fast-Traveled to " + region_name)
		elif hud and "mission_toast" in hud and hud.mission_toast:
			hud.mission_toast_lbl.text = "📍 Arrived at " + region_name
			hud.mission_toast.visible = true
			get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(hud.mission_toast): hud.mission_toast.visible = false)
			
	region_travel_requested.emit(region_id, target_pos, region_name)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N or event.keycode == KEY_M:
			if event.keycode == KEY_N or (event.keycode == KEY_M and Input.is_key_pressed(KEY_SHIFT)):
				toggle_map()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _is_open:
			close_map()
			get_viewport().set_input_as_handled()
