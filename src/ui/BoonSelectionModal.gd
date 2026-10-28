extends Control
class_name BoonSelectionModal

signal boon_selected(boon: Dictionary)

var _cards_container: HBoxContainer = null
var _boons_presented: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	var title = Label.new()
	title.text = "— CHOOSE AN OSSUARY RELIC —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Embrace an ancient soul blessing for this descent"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.modulate = Color(0.7, 0.75, 0.8)
	vbox.add_child(subtitle)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)
	
	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	vbox.add_child(_cards_container)

func display_choices(boon_list: Array[Dictionary]) -> void:
	_boons_presented = boon_list
	for c in _cards_container.get_children():
		c.queue_free()
		
	for boon in boon_list:
		var card = _create_boon_card(boon)
		_cards_container.add_child(card)
		
	visible = true
	get_tree().paused = true

func _create_boon_card(boon: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 320)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = boon.get("color", Color(0.8, 0.8, 0.8))
	style.content_margin_left = 16
	style.content_margin_top = 20
	style.content_margin_right = 16
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(vbox)
	
	# Top info
	var top_box = VBoxContainer.new()
	
	var rarity_label = Label.new()
	rarity_label.text = "[" + boon.get("rarity", "Common") + "]"
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.modulate = boon.get("color", Color(0.8, 0.8, 0.8))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(rarity_label)
	
	var name_label = Label.new()
	name_label.text = boon.get("name", "Unknown Relic")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_box.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = "\n" + boon.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.modulate = Color(0.85, 0.88, 0.92)
	top_box.add_child(desc_label)
	
	vbox.add_child(top_box)
	
	# Select Button
	var btn = Button.new()
	btn.text = "Select Relic"
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(_on_card_selected.bind(boon))
	vbox.add_child(btn)
	
	return panel

func _on_card_selected(boon: Dictionary) -> void:
	AudioManager.play_sfx("chest_open", 0.1, 1.0)
	GameManager.add_boon(boon)
	visible = false
	get_tree().paused = false
	boon_selected.emit(boon)
