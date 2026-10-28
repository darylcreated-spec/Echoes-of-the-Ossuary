extends Control
class_name DialogueModal

signal dialogue_closed()
signal action_triggered(action_name: String)

var _title_label: Label = null
var _body_label: Label = null
var _buttons_box: HBoxContainer = null
var _icon_label: Label = null
var _frame: PanelContainer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.75)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_dialogue()
	)
	add_child(bg)
	
	# Dialog Window Box (Lower third of screen for classic RPG presentation)
	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(780, 220)
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_top = 1.0
	_frame.anchor_bottom = 1.0
	_frame.offset_left = -390
	_frame.offset_right = 390
	_frame.offset_top = -250
	_frame.offset_bottom = -30
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.07, 0.08, 0.12, 0.96)
	frame_style.border_color = Color(0.85, 0.70, 0.32) # Burnished Gold
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	frame_style.content_margin_left = 24
	frame_style.content_margin_right = 24
	frame_style.content_margin_top = 18
	frame_style.content_margin_bottom = 18
	_frame.add_theme_stylebox_override("panel", frame_style)
	add_child(_frame)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_frame.add_child(vbox)
	
	# Header with Icon & Name
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	
	_icon_label = Label.new()
	_icon_label.text = "💬"
	_icon_label.add_theme_font_size_override("font_size", 28)
	header.add_child(_icon_label)
	
	_title_label = Label.new()
	_title_label.text = "NPC Name"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	header.add_child(_title_label)
	
	# Dialog Text Body
	_body_label = Label.new()
	_body_label.text = "Dialogue content goes here..."
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(730, 70)
	_body_label.add_theme_font_size_override("font_size", 15)
	_body_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	vbox.add_child(_body_label)
	
	# Action buttons row
	_buttons_box = HBoxContainer.new()
	_buttons_box.alignment = BoxContainer.ALIGNMENT_END
	_buttons_box.add_theme_constant_override("separation", 14)
	vbox.add_child(_buttons_box)

func show_dialogue(npc_name: String, icon: String, text: String, actions: Array[Dictionary]) -> void:
	_title_label.text = npc_name
	_icon_label.text = icon
	_body_label.text = text
	
	# Clear previous buttons
	for child in _buttons_box.get_children():
		child.queue_free()
		
	# Populate action buttons
	for act in actions:
		var btn = Button.new()
		btn.text = act.get("label", "Option")
		btn.custom_minimum_size = Vector2(130, 34)
		btn.focus_mode = Control.FOCUS_NONE
		
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = act.get("color", Color(0.18, 0.22, 0.32))
		b_style.border_color = Color(0.8, 0.7, 0.35)
		b_style.set_border_width_all(1)
		b_style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", b_style)
		
		var act_id = act.get("id", "")
		btn.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			action_triggered.emit(act_id)
			if act.get("closes", true):
				close_dialogue()
		)
		_buttons_box.add_child(btn)
		
	# Always add a farewell close button if not included
	var close_btn = Button.new()
	close_btn.text = "Farewell"
	close_btn.custom_minimum_size = Vector2(100, 34)
	close_btn.focus_mode = Control.FOCUS_NONE
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.12, 0.13, 0.18)
	c_style.border_color = Color(0.4, 0.45, 0.55)
	c_style.set_border_width_all(1)
	c_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", c_style)
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("button_click")
		close_dialogue()
	)
	_buttons_box.add_child(close_btn)
	
	visible = true
	AudioManager.play_sfx("button_click", 0.05, 1.0)

func close_dialogue() -> void:
	visible = false
	dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_dialogue()
		get_viewport().set_input_as_handled()
