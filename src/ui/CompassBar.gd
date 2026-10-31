extends Control
class_name CompassBar

const LANDMARKS = [
	{"name": "🏰 Oakhaven Citadel", "pos": Vector3(0.0, 0.0, 44.0), "color": Color(0.7, 0.85, 1.0)},
	{"name": "⛪ Cathedral of Light", "pos": Vector3(16.0, 0.0, 0.0), "color": Color(1.0, 0.9, 0.5)},
	{"name": "⚒️ Torval's Forge", "pos": Vector3(-15.0, 0.0, 0.0), "color": Color(1.0, 0.6, 0.3)},
	{"name": "🍺 Boar's Tusk Tavern", "pos": Vector3(-10.0, 0.0, 17.5), "color": Color(0.9, 0.7, 0.4)},
	{"name": "⚓ Port Blackwater", "pos": Vector3(-58.0, 0.0, 66.0), "color": Color(0.4, 0.8, 0.95)},
	{"name": "🌲 Whisperwood Grove", "pos": Vector3(-78.0, 0.0, -62.0), "color": Color(0.4, 0.9, 0.5)},
	{"name": "⛰️ Khar-Drakken Mines", "pos": Vector3(70.0, 0.0, -55.0), "color": Color(0.95, 0.75, 0.45)},
	{"name": "🌾 Sunnydale Windmill", "pos": Vector3(34.0, 0.0, 38.0), "color": Color(0.95, 0.88, 0.4)}
]

var container: HBoxContainer = null

func _ready() -> void:
	custom_minimum_size = Vector2(700, 24)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -350
	offset_right = 350
	offset_top = 44
	offset_bottom = 68
	
	container = HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 14)
	add_child(container)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not container:
		return
		
	# Clear previous markers
	for c in container.get_children():
		c.queue_free()
		
	# Find up to 3 closest landmarks
	var p_pos = player.global_position
	var list = []
	for lm in LANDMARKS:
		var d = p_pos.distance_to(lm["pos"])
		list.append({"name": lm["name"], "dist": d, "color": lm["color"], "pos": lm["pos"]})
		
	list.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	for i in range(min(4, list.size())):
		var item = list[i]
		var lbl = Label.new()
		var dir_str = _get_direction_string(p_pos, item["pos"])
		lbl.text = "%s [%s %.0fm]" % [item["name"], dir_str, item["dist"]]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", item["color"])
		container.add_child(lbl)

func _get_direction_string(from_pos: Vector3, to_pos: Vector3) -> String:
	var diff = to_pos - from_pos
	var angle = atan2(diff.x, diff.z) # Angle in radians
	var deg = rad_to_deg(angle)
	if deg < 0:
		deg += 360.0
		
	if deg >= 337.5 or deg < 22.5:
		return "S"
	elif deg >= 22.5 and deg < 67.5:
		return "SW"
	elif deg >= 67.5 and deg < 112.5:
		return "W"
	elif deg >= 112.5 and deg < 157.5:
		return "NW"
	elif deg >= 157.5 and deg < 202.5:
		return "N"
	elif deg >= 202.5 and deg < 247.5:
		return "NE"
	elif deg >= 247.5 and deg < 292.5:
		return "E"
	else:
		return "SE"
