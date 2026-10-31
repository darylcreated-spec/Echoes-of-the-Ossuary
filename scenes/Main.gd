extends Node3D

@onready var camera: Camera3D = $IsometricCamera
@onready var dungeon_gen: Node3D = $DungeonGenerator
@onready var player: Node3D = $Player
@onready var hud: CanvasLayer = $UI_HUD

# --- CAMERA CONTROL MODES & PROPERTIES ---
enum CameraMode { FOLLOW, FREECAM }
var current_camera_mode: CameraMode = CameraMode.FOLLOW

# Follow Mode Spherical Parameters
var cam_yaw: float = 45.0
var cam_pitch: float = 48.0
var cam_distance: float = 16.0
var target_cam_yaw: float = 45.0
var target_cam_pitch: float = 48.0
var target_cam_distance: float = 16.0

const MIN_DISTANCE: float = 4.5
const MAX_DISTANCE: float = 48.0
const MIN_PITCH: float = 18.0
const MAX_PITCH: float = 80.0

var camera_follow_speed: float = 8.5
var camera_rot_speed: float = 9.0

# Mouse Drag State
var is_mouse_dragging: bool = false

# FreeCam Parameters
var freecam_pos: Vector3 = Vector3.ZERO
var freecam_yaw: float = 45.0
var freecam_pitch: float = -35.0
var freecam_speed: float = 24.0
var freecam_boost_speed: float = 55.0

# UI Overlay Elements
var camera_ui_container: PanelContainer = null
var camera_ui_label: Label = null
var camera_mode_button: Button = null

var current_room: Node3D = null

func _ready() -> void:
	add_to_group("main")
	
	if camera:
		CombatJuice.register_camera(camera)
		
	# Start serene Overworld theme on game start
	AudioManager.play_bgm("bgm_overworld", -12.0)
	
	# Initial room build (Sanctuary Hub)
	load_current_floor_room()
	
	if camera and player:
		camera.make_current()
		_init_camera_position()
		
	_setup_camera_ui()

func _init_camera_position() -> void:
	target_cam_yaw = 45.0
	target_cam_pitch = 48.0
	target_cam_distance = 16.0
	cam_yaw = target_cam_yaw
	cam_pitch = target_cam_pitch
	cam_distance = target_cam_distance
	
	if player and camera:
		var yaw_rad = deg_to_rad(cam_yaw)
		var pitch_rad = deg_to_rad(cam_pitch)
		var offset = Vector3(
			cam_distance * cos(pitch_rad) * sin(yaw_rad),
			cam_distance * sin(pitch_rad),
			cam_distance * cos(pitch_rad) * cos(yaw_rad)
		)
		var look_target = player.global_position + Vector3(0, 0.9, 0)
		camera.global_position = look_target + offset
		camera.look_at(look_target, Vector3.UP)

func _physics_process(delta: float) -> void:
	if current_camera_mode == CameraMode.FOLLOW:
		_process_follow_camera(delta)
	else:
		_process_freecam(delta)

func _process_follow_camera(delta: float) -> void:
	if not player or not is_instance_valid(player) or not camera:
		return
		
	# Keyboard Orbit Controls (Arrow keys, Z/X, [/])
	var orbit_input = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_BRACKETLEFT):
		orbit_input -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_BRACKETRIGHT):
		orbit_input += 1.0
		
	var pitch_input = 0.0
	if Input.is_key_pressed(KEY_UP):
		pitch_input += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		pitch_input -= 1.0
		
	var zoom_input = 0.0
	if Input.is_key_pressed(KEY_PAGEUP) or Input.is_key_pressed(KEY_EQUAL):
		zoom_input -= 1.0
	if Input.is_key_pressed(KEY_PAGEDOWN) or Input.is_key_pressed(KEY_MINUS):
		zoom_input += 1.0
		
	if orbit_input != 0.0:
		target_cam_yaw += orbit_input * delta * 110.0
	if pitch_input != 0.0:
		target_cam_pitch = clamp(target_cam_pitch + pitch_input * delta * 45.0, MIN_PITCH, MAX_PITCH)
	if zoom_input != 0.0:
		target_cam_distance = clamp(target_cam_distance + zoom_input * delta * 18.0, MIN_DISTANCE, MAX_DISTANCE)

	# Smoothly interpolate current angles and distance toward target
	cam_yaw = lerp_angle(deg_to_rad(cam_yaw), deg_to_rad(target_cam_yaw), delta * camera_rot_speed)
	cam_yaw = rad_to_deg(cam_yaw)
	cam_pitch = lerp(cam_pitch, target_cam_pitch, delta * camera_rot_speed)
	cam_distance = lerp(cam_distance, target_cam_distance, delta * camera_follow_speed)
	
	var yaw_rad = deg_to_rad(cam_yaw)
	var pitch_rad = deg_to_rad(cam_pitch)
	
	var offset = Vector3(
		cam_distance * cos(pitch_rad) * sin(yaw_rad),
		cam_distance * sin(pitch_rad),
		cam_distance * cos(pitch_rad) * cos(yaw_rad)
	)
	
	var look_target = player.global_position + Vector3(0, 0.9, 0)
	var target_pos = look_target + offset
	camera.global_position = camera.global_position.lerp(target_pos, delta * camera_follow_speed)
	camera.look_at(look_target, Vector3.UP)

func _process_freecam(delta: float) -> void:
	if not camera:
		return
		
	# Flight direction relative to camera look
	var move_vec = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move_vec -= camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_vec += camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_vec -= camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_vec += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E):
		move_vec += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_Q):
		move_vec -= Vector3.UP
		
	var speed = freecam_boost_speed if Input.is_key_pressed(KEY_SHIFT) else freecam_speed
	if move_vec != Vector3.ZERO:
		freecam_pos += move_vec.normalized() * speed * delta
		
	camera.global_position = freecam_pos
	camera.rotation_degrees = Vector3(freecam_pitch, freecam_yaw, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	# Mode toggle with [C] or [F1]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or event.keycode == KEY_F1:
			toggle_camera_mode()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_R:
			reset_camera_view()
			get_viewport().set_input_as_handled()
			return
			
	# Mouse Wheel Zoom (Follow) or Speed (FreeCam)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if current_camera_mode == CameraMode.FOLLOW:
				target_cam_distance = clamp(target_cam_distance - 2.5, MIN_DISTANCE, MAX_DISTANCE)
			else:
				freecam_speed = clamp(freecam_speed + 4.0, 6.0, 90.0)
			_update_camera_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if current_camera_mode == CameraMode.FOLLOW:
				target_cam_distance = clamp(target_cam_distance + 2.5, MIN_DISTANCE, MAX_DISTANCE)
			else:
				freecam_speed = clamp(freecam_speed - 4.0, 6.0, 90.0)
			_update_camera_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_mouse_dragging = true
			get_viewport().set_input_as_handled()
			return
			
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_mouse_dragging = false
			get_viewport().set_input_as_handled()
			return
			
	# Mouse Motion Drag Orbit / Look
	if event is InputEventMouseMotion and is_mouse_dragging:
		var rel = event.relative
		if current_camera_mode == CameraMode.FOLLOW:
			target_cam_yaw -= rel.x * 0.35
			target_cam_pitch = clamp(target_cam_pitch + rel.y * 0.35, MIN_PITCH, MAX_PITCH)
		else:
			freecam_yaw -= rel.x * 0.35
			freecam_pitch = clamp(freecam_pitch - rel.y * 0.35, -88.0, 88.0)
		get_viewport().set_input_as_handled()
		return

func toggle_camera_mode() -> void:
	if current_camera_mode == CameraMode.FOLLOW:
		current_camera_mode = CameraMode.FREECAM
		if camera:
			freecam_pos = camera.global_position
			freecam_yaw = cam_yaw
			freecam_pitch = -cam_pitch
		if player and "is_input_locked" in player:
			player.is_input_locked = true
			player.velocity = Vector3.ZERO
	else:
		current_camera_mode = CameraMode.FOLLOW
		if player and "is_input_locked" in player:
			player.is_input_locked = false
	_update_camera_ui()

func reset_camera_view() -> void:
	target_cam_yaw = 45.0
	target_cam_pitch = 48.0
	target_cam_distance = 16.0
	if current_camera_mode == CameraMode.FREECAM:
		toggle_camera_mode()
	_update_camera_ui()

func _setup_camera_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "CameraControlsLayer"
	canvas.layer = 15 # Above background HUD elements
	add_child(canvas)
	
	camera_ui_container = PanelContainer.new()
	camera_ui_container.name = "CameraBar"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	sb.border_color = Color(0.24, 0.32, 0.44, 0.9)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	camera_ui_container.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	camera_ui_container.add_child(hbox)
	
	camera_mode_button = Button.new()
	camera_mode_button.text = "🎥 Free-Cam [C]"
	camera_mode_button.focus_mode = Control.FOCUS_NONE
	camera_mode_button.pressed.connect(toggle_camera_mode)
	hbox.add_child(camera_mode_button)
	
	camera_ui_label = Label.new()
	camera_ui_label.text = "Zoom: [Scroll] | Orbit: [RMB Drag / Arrows] | Reset: [R]"
	camera_ui_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	camera_ui_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(camera_ui_label)
	
	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset [R]"
	reset_btn.focus_mode = Control.FOCUS_NONE
	reset_btn.pressed.connect(reset_camera_view)
	hbox.add_child(reset_btn)
	
	canvas.add_child(camera_ui_container)
	camera_ui_container.anchor_left = 0.0
	camera_ui_container.anchor_top = 1.0
	camera_ui_container.anchor_right = 0.0
	camera_ui_container.anchor_bottom = 1.0
	camera_ui_container.offset_left = 16.0
	camera_ui_container.offset_top = -48.0
	camera_ui_container.offset_right = 530.0
	camera_ui_container.offset_bottom = -12.0
	
	_update_camera_ui()

func _update_camera_ui() -> void:
	if not camera_ui_label or not camera_mode_button:
		return
	if current_camera_mode == CameraMode.FOLLOW:
		camera_mode_button.text = "🎥 Free-Cam [C]"
		camera_ui_label.text = "Zoom: [Scroll] (%.0fm) | Orbit: [RMB Drag / Arrows] | Reset: [R]" % target_cam_distance
	else:
		camera_mode_button.text = "🎯 Follow Player [C]"
		camera_ui_label.text = "FREE-CAM: [WASD] Fly | [Space/Ctrl] Up/Down | [Shift] Boost | [RMB Drag] Look"

func load_current_floor_room() -> Node3D:
	current_room = dungeon_gen.build_floor_room(GameManager.current_floor)
	var room = current_room
	
	_update_environment_lighting(GameManager.current_floor)
	
	# Select appropriate music theme: Overworld village vs. Underworld Catacombs
	if GameManager.current_floor == 0:
		AudioManager.play_bgm("bgm_overworld", -12.0)
	else:
		AudioManager.play_bgm("bgm_dungeon", -10.0)
	
	# Reposition player: spawn in courtyard plaza in Overworld (floor 0), or north door in chambers
	if player and is_instance_valid(player):
		player.global_position = Vector3(0, 0.5, 3.8 if GameManager.current_floor == 0 else -6.0)
		player.velocity = Vector3.ZERO
		player.current_health = player.max_health
		player.health_changed.emit(player.current_health, player.max_health)
		
	# Connect Boss if Floor 5
	if GameManager.current_floor >= 5 and room:
		for child in room.get_children():
			if child.has_signal("boss_health_updated"):
				child.boss_health_updated.connect(hud.update_boss_health)
				if "boss_name" in child and "current_health" in child and "max_health" in child:
					hud.update_boss_health(child.current_health, child.max_health, child.boss_name)
	return current_room

func _update_environment_lighting(floor_num: int) -> void:
	var dir_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
	var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
	
	if floor_num == 0:
		# Overworld Surface Hub: Golden-hour open daylight
		if dir_light:
			dir_light.light_energy = 1.35
			dir_light.light_color = Color(1.0, 0.95, 0.88)
		if world_env and world_env.environment:
			world_env.environment.ambient_light_energy = 1.15
			world_env.environment.ambient_light_color = Color(0.52, 0.62, 0.76)
			if world_env.environment.sky and world_env.environment.sky.sky_material is ProceduralSkyMaterial:
				var sky_mat: ProceduralSkyMaterial = world_env.environment.sky.sky_material
				sky_mat.sky_top_color = Color(0.28, 0.52, 0.88)
				sky_mat.sky_horizon_color = Color(0.68, 0.82, 0.94)
				sky_mat.ground_bottom_color = Color(0.2, 0.28, 0.2)
				sky_mat.ground_horizon_color = Color(0.48, 0.62, 0.48)
	else:
		# Subterranean Ossuary Delve: Dark moody dungeon
		if dir_light:
			dir_light.light_energy = 0.55
			dir_light.light_color = Color(0.65, 0.75, 0.85)
		if world_env and world_env.environment:
			world_env.environment.ambient_light_energy = 0.65
			world_env.environment.ambient_light_color = Color(0.16, 0.2, 0.28)
			if world_env.environment.sky and world_env.environment.sky.sky_material is ProceduralSkyMaterial:
				var sky_mat: ProceduralSkyMaterial = world_env.environment.sky.sky_material
				sky_mat.sky_top_color = Color(0.06, 0.08, 0.14)
				sky_mat.sky_horizon_color = Color(0.12, 0.14, 0.2)
				sky_mat.ground_bottom_color = Color(0.03, 0.04, 0.06)
				sky_mat.ground_horizon_color = Color(0.08, 0.1, 0.14)
