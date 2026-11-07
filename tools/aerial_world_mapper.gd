extends Node
class_name AerialWorldMapper

# Overlay Control to draw gridlines, badges, names and compass on the captured viewport
class AerialGridOverlay extends Control:
	var col_x_bounds = [-210.0, -85.0, 0.0, 75.0, 145.0]
	var row_z_bounds = [-140.0, -45.0, 28.0, 100.0, 210.0]
	var sector_names = {
		"A1": "North-West Ocean",
		"B1": "Whisperwood Enclave",
		"C1": "Crypt Gate & Grove",
		"D1": "Khar-Drakken Crags",
		"A2": "Open Western Ocean",
		"B2": "Boar's Tusk & Market",
		"C2": "Oakhaven Plaza Hub",
		"D2": "River & Watermill",
		"A3": "Port Blackwater Quays",
		"B3": "Sunnydale Farmlands",
		"C3": "Royal Citadel Castle",
		"D3": "Weeping Fen Mire",
		"A4": "Corsair Bastion",
		"B4": "Naval Battle Theater",
		"C4": "Ground Troop Battle",
		"D4": "Southern Estuary"
	}
	var camera: Camera3D = null
	var font: Font = null
	var is_visible_overlay: bool = true

	func _draw() -> void:
		if not is_visible_overlay or not camera:
			return

		var vp_rect = get_viewport_rect()
		var w = vp_rect.size.x
		var h = vp_rect.size.y

		# Draw Grid Lines
		for x_val in col_x_bounds:
			var p1 = camera.unproject_position(Vector3(x_val, 0.0, row_z_bounds[0]))
			var p2 = camera.unproject_position(Vector3(x_val, 0.0, row_z_bounds[4]))
			draw_line(p1, p2, Color(1.0, 0.85, 0.3, 0.75), 2.0)

		for z_val in row_z_bounds:
			var p1 = camera.unproject_position(Vector3(col_x_bounds[0], 0.0, z_val))
			var p2 = camera.unproject_position(Vector3(col_x_bounds[4], 0.0, z_val))
			draw_line(p1, p2, Color(1.0, 0.85, 0.3, 0.75), 2.0)

		# Draw Sector Badges and Labels
		var cols = ["A", "B", "C", "D"]
		var cur_font = font if font else ThemeDB.fallback_font

		for ci in range(4):
			for ri in range(4):
				var code = cols[ci] + str(ri + 1)
				var p_top_left = camera.unproject_position(Vector3(col_x_bounds[ci], 0.0, row_z_bounds[ri]))
				var p_bot_right = camera.unproject_position(Vector3(col_x_bounds[ci + 1], 0.0, row_z_bounds[ri + 1]))
				var sector_w = abs(p_bot_right.x - p_top_left.x)

				# Badge Box: [A1]
				var badge_pos = p_top_left + Vector2(6, 40 if ri == 0 else 6)
				var badge_size = Vector2(38, 24)
				draw_rect(Rect2(badge_pos, badge_size), Color(0.08, 0.08, 0.12, 0.90), true)
				draw_rect(Rect2(badge_pos, badge_size), Color(1.0, 0.84, 0.3, 0.95), false, 1.5)
				draw_string(cur_font, badge_pos + Vector2(5, 17), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.95, 0.5))

				# Region Name Tag right next to the badge, strictly clamped to sector width
				var name_text = sector_names.get(code, "")
				var max_name_w = clamp(sector_w - 48.0, 50.0, 160.0)
				var name_box = Rect2(badge_pos.x + 42, badge_pos.y, max_name_w, 24)
				draw_rect(name_box, Color(0.05, 0.06, 0.09, 0.85), true)
				draw_rect(name_box, Color(0.8, 0.7, 0.35, 0.45), false, 1.0)
				draw_string(cur_font, Vector2(name_box.position.x + 5, name_box.position.y + 16), name_text, HORIZONTAL_ALIGNMENT_LEFT, int(max_name_w - 8), 12, Color(1.0, 1.0, 1.0, 0.95))

		# Header Title Bar (Top edge)
		var header_box = Rect2(w * 0.5 - 240, 6, 480, 32)
		draw_rect(header_box, Color(0.06, 0.07, 0.10, 0.92), true)
		draw_rect(header_box, Color(1.0, 0.84, 0.3, 0.95), false, 1.5)
		draw_string(cur_font, Vector2(w * 0.5 - 230, 27), "ECHOES OF THE OSSUARY — REALM SECTOR MAP", HORIZONTAL_ALIGNMENT_CENTER, 460, 16, Color(1.0, 0.92, 0.6))

		# Compass Rose & Legend (Bottom-Right)
		var compass_box = Rect2(w - 170, h - 130, 158, 118)
		draw_rect(compass_box, Color(0.06, 0.07, 0.10, 0.90), true)
		draw_rect(compass_box, Color(1.0, 0.84, 0.3, 0.8), false, 1.5)
		draw_string(cur_font, Vector2(compass_box.position.x + 12, compass_box.position.y + 24), "COMPASS ORIENTATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.4))
		draw_string(cur_font, Vector2(compass_box.position.x + 79, compass_box.position.y + 48), "▲ NORTH (Z-)", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.4, 0.9, 1.0))
		draw_string(cur_font, Vector2(compass_box.position.x + 10, compass_box.position.y + 72), "◄ WEST (X-)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.85, 0.85))
		draw_string(cur_font, Vector2(compass_box.position.x + 96, compass_box.position.y + 72), "EAST (X+) ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.85, 0.85))
		draw_string(cur_font, Vector2(compass_box.position.x + 79, compass_box.position.y + 98), "▼ SOUTH (Z+)", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1.0, 0.7, 0.4))

		# Map Scale Bar (Bottom-Left)
		var scale_box = Rect2(12, h - 56, 195, 46)
		draw_rect(scale_box, Color(0.06, 0.07, 0.10, 0.90), true)
		draw_rect(scale_box, Color(1.0, 0.84, 0.3, 0.8), false, 1.5)
		draw_string(cur_font, Vector2(20, h - 35), "SCALE: 1 Sector ≈ 85m", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.95, 0.7))
		draw_string(cur_font, Vector2(20, h - 18), "TOTAL REALM: 350m × 350m", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))

static func run_mapping(main_node: Node3D) -> void:
	print("==================================================================")
	print("   AERIAL WORLD ENVIRONMENT MAPPER & SECTOR GRID GENERATOR   ")
	print("==================================================================")
	var tree = main_node.get_tree()
	await tree.process_frame
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame

	main_node.set_physics_process(false)
	var hud: CanvasLayer = main_node.get("hud")
	var cam_ui: Control = main_node.get("camera_ui_container")
	var player: Node3D = main_node.get("player")
	if hud: hud.visible = false
	if cam_ui: cam_ui.visible = false
	if player: player.visible = true

	var out_dir = "C:/Users/daryl/.gemini/antigravity/brain/b85f0ffa-34bf-4cb5-a1fb-9879dd096756/screenshots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var local_dir = "res://screenshots/aerial_grid"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(local_dir))

	var camera: Camera3D = main_node.get("camera")
	if not camera:
		printerr("Camera not found on main node!")
		return

	# Set camera near and far clipping to hide subterranean interior rooms (Y = -100m)
	camera.near = 50.0
	camera.far = 380.0

	# Load font for overlay
	var overlay_font = null
	if FileAccess.file_exists("res://assets/ui/MedievalSharp.ttf"):
		overlay_font = load("res://assets/ui/MedievalSharp.ttf")

	# Attach CanvasLayer and Overlay Control
	var overlay_layer = CanvasLayer.new()
	overlay_layer.name = "AerialOverlayLayer"
	var overlay_ctrl = AerialGridOverlay.new()
	overlay_ctrl.name = "AerialGridOverlay"
	overlay_ctrl.camera = camera
	overlay_ctrl.font = overlay_font
	overlay_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay_ctrl)
	main_node.add_child(overlay_layer)

	# --- 1. CAPTURE CLEAN MASTER ORTHO (Unlabeled) ---
	overlay_ctrl.is_visible_overlay = false
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 375.0
	camera.global_position = Vector3(-36.5, 340.0, 36.5)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)

	for i in range(4):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aerial_master_ortho_clean.png", local_dir + "/aerial_master_ortho_clean.png")

	# --- 2. CAPTURE MASTER ORTHO WITH SECTOR GRID OVERLAY ---
	overlay_ctrl.is_visible_overlay = true
	overlay_ctrl.queue_redraw()
	for i in range(4):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aerial_master_grid_labeled.png", local_dir + "/aerial_master_grid_labeled.png")

	# --- 3. CAPTURE ANGLED BIRDS-EYE PERSPECTIVE (Clean Natural Terrain) ---
	overlay_ctrl.is_visible_overlay = false
	overlay_ctrl.queue_redraw()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 52.0
	camera.global_position = Vector3(-36.5, 240.0, 260.0)
	camera.look_at(Vector3(-36.5, 0.0, 25.0), Vector3.UP)
	for i in range(4):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aerial_perspective_birds_eye.png", local_dir + "/aerial_perspective_birds_eye.png")

	# --- 4. CAPTURE 4 HIGH-RES REGIONAL QUADRANTS (Close-Ups, Clean) ---
	var quadrants = [
		{
			"name": "quadrant_NW_whisperwood_oakhaven",
			"pos": Vector3(-95.0, 220.0, -50.0),
			"size": 185.0
		},
		{
			"name": "quadrant_NE_crypt_crags_watermill",
			"pos": Vector3(55.0, 220.0, -50.0),
			"size": 185.0
		},
		{
			"name": "quadrant_SW_port_naval_archipelago",
			"pos": Vector3(-95.0, 220.0, 120.0),
			"size": 195.0
		},
		{
			"name": "quadrant_SE_citadel_swamp_siege",
			"pos": Vector3(55.0, 220.0, 120.0),
			"size": 195.0
		}
	]

	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	for q in quadrants:
		camera.size = q["size"]
		camera.global_position = q["pos"]
		for i in range(4):
			await tree.process_frame
		_save_viewport_image(tree, out_dir + "/" + q["name"] + ".png", local_dir + "/" + q["name"] + ".png")

	# --- 5. GROUND PERSPECTIVE & TOP-DOWN CAMERA COMPARISON SCREENSHOTS ---
	camera.near = 0.08
	camera.far = 380.0
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 55.0

	# A. Sector C4 Combined-Arms Land Siege Battle (Close-up Action View)
	camera.global_position = Vector3(35.0, 10.5, 118.0)
	camera.look_at(Vector3(35.0, 1.2, 162.0), Vector3.UP)
	for i in range(4):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/ground_battle_c4_clash.png", local_dir + "/ground_battle_c4_clash.png")

	# B. Sector B1 Relocated Sylva's Rest & Open Western Ocean
	camera.global_position = Vector3(-46.0, 9.5, -56.0)
	camera.look_at(Vector3(-46.0, 1.0, -88.0), Vector3.UP)
	for i in range(4):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/sector_b1_whisperwood_enclave.png", local_dir + "/sector_b1_whisperwood_enclave.png")

	# --- 6. GAMEPLAY HUD, STORY GUIDE & TOP-DOWN CAMERA EVALUATION SHOTS ---
	if hud: hud.visible = true
	if cam_ui: cam_ui.visible = true

	# Shot 6A: Oakhaven Hub — Action-RPG Camera + Storyline Guide Pop-Up ON (Chapter I)
	GameManager.set_story_guide_enabled(true)
	if player:
		player.global_position = Vector3(0.0, 0.0, 4.0)
	main_node.call("apply_camera_preset", 0, true) # ACTION_RPG
	for i in range(5):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_hub_action_rpg_with_story_guide.png", local_dir + "/aa_hub_action_rpg_with_story_guide.png")

	# Complete Chapter I to showcase Character Progression Rewards (Lv.2 + Max HP + Attack + Chapter II)
	GameManager.complete_current_campaign_step()

	# Shot 6B: Oakhaven Hub — Top-Down Camera Mode (82° Pitch, 26.5m Dist) + Level-Up & Chapter II Guide
	main_node.call("apply_camera_preset", 4, true) # TOP_DOWN
	for i in range(5):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_hub_top_down_camera_view.png", local_dir + "/aa_hub_top_down_camera_view.png")

	# Trigger Combined-Arms Charge & Siege Barrage in Sector C4 for live combat shots
	var b_ctrls = tree.get_nodes_in_group("battlefield_controller")
	if b_ctrls.size() > 0:
		b_ctrls[0].call("command_all_charge")
		b_ctrls[0].call("command_cavalry_and_siege")
		b_ctrls[0].call("command_all_volley")

	for i in range(12):
		await tree.physics_frame

	# Shot 6C: Massive Battle #1 (Combined-Arms Land Siege) — Action-RPG View looking South across both clashing armies
	GameManager.set_story_guide_enabled(true)
	if player:
		player.global_position = Vector3(35.0, 0.0, 148.5)
	main_node.call("apply_camera_preset", 0, true) # ACTION_RPG
	main_node.set("target_cam_yaw", 180.0)
	main_node.set("cam_yaw", 180.0)
	camera.global_position = Vector3(35.0, 9.8, 136.5)
	camera.look_at(Vector3(35.0, 1.2, 156.0), Vector3.UP)
	if b_ctrls.size() > 0:
		b_ctrls[0].call("command_cavalry_and_siege")
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_massive_battle_1_land_siege_action_view.png", local_dir + "/aa_massive_battle_1_land_siege_action_view.png")

	# Shot 6D: Massive Battle #1 (Combined-Arms Land Siege) — Top-Down Camera View (with Guide toggled OFF [H] for full tactical view)
	GameManager.set_story_guide_enabled(false)
	if player:
		player.global_position = Vector3(35.0, 0.0, 155.0)
	main_node.call("apply_camera_preset", 4, true) # TOP_DOWN
	main_node.set("target_cam_yaw", 180.0)
	main_node.set("cam_yaw", 180.0)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_massive_battle_1_land_siege_top_down.png", local_dir + "/aa_massive_battle_1_land_siege_top_down.png")

	# Advance campaign to Chapter IV & re-enable Story Guide Pop-Up
	GameManager.complete_current_campaign_step()
	GameManager.complete_current_campaign_step()
	GameManager.set_story_guide_enabled(true)

	# Trigger Port Blackwater Sea Warfare Cannon Barrage & Beachhead Charge
	var p_ctrls = tree.get_nodes_in_group("port_sea_warfare")
	if p_ctrls.size() > 0:
		p_ctrls[0].call("command_marines_charge")
		p_ctrls[0].call("command_coastal_cannon_barrage")
		p_ctrls[0].call("command_marines_volley")

	for i in range(12):
		await tree.physics_frame

	# Shot 6E: Massive Battle #2 (Port Blackwater Seaside Ship Warfare) — Action-RPG View looking West toward the Harbor & Armada
	if player:
		player.global_position = Vector3(-56.0, 0.0, 78.0)
	main_node.call("apply_camera_preset", 0, true) # ACTION_RPG
	main_node.set("target_cam_yaw", 90.0)
	main_node.set("cam_yaw", 90.0)
	camera.global_position = Vector3(-44.0, 9.8, 78.0)
	camera.look_at(Vector3(-68.0, 1.2, 78.0), Vector3.UP)
	if p_ctrls.size() > 0:
		p_ctrls[0].call("command_coastal_cannon_barrage")
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_massive_battle_2_port_sea_warfare_action_view.png", local_dir + "/aa_massive_battle_2_port_sea_warfare_action_view.png")

	# Shot 6F: Massive Battle #2 (Port Blackwater Seaside Ship Warfare) — Top-Down Camera View (Guide toggled OFF [H])
	GameManager.set_story_guide_enabled(false)
	if player:
		player.global_position = Vector3(-64.0, 0.0, 78.0)
	main_node.call("apply_camera_preset", 4, true) # TOP_DOWN
	main_node.set("target_cam_yaw", 90.0)
	main_node.set("cam_yaw", 90.0)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/aa_massive_battle_2_port_sea_warfare_top_down.png", local_dir + "/aa_massive_battle_2_port_sea_warfare_top_down.png")

	# Shot 6G: Sector C1 — Abbey of the Silver Dawn, Sacred Aura, Braziers & Patrols
	GameManager.set_story_guide_enabled(true)
	if player:
		player.global_position = Vector3(4.0, 0.0, -84.0)
	main_node.call("apply_camera_preset", 0, true) # ACTION_RPG
	camera.global_position = Vector3(4.0, 9.5, -72.0)
	camera.look_at(Vector3(4.0, 1.5, -96.0), Vector3.UP)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/sector_c1_abbey_of_silver_dawn.png", local_dir + "/sector_c1_abbey_of_silver_dawn.png")

	# Shot 6H: Sector B4 — Southwatch Coastal Supply Depot, Cavalry Remount Corral & Watchtowers
	if player:
		player.global_position = Vector3(-30.0, 0.0, 136.0)
	camera.global_position = Vector3(-16.0, 11.0, 120.0)
	camera.look_at(Vector3(-34.0, 1.5, 148.0), Vector3.UP)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/sector_b4_southwatch_depot_and_cavalry.png", local_dir + "/sector_b4_southwatch_depot_and_cavalry.png")

	# Shot 6I: Sector D2 — Eastbrook Orchard, Windmill, Wayfarer's Inn & Ploughed Furrows
	if player:
		player.global_position = Vector3(96.0, 0.0, -14.0)
	camera.global_position = Vector3(80.0, 10.5, -2.0)
	camera.look_at(Vector3(104.0, 1.5, -18.0), Vector3.UP)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/sector_d2_eastbrook_orchard_and_windmill.png", local_dir + "/sector_d2_eastbrook_orchard_and_windmill.png")

	# Shot 6J: Sector D4 — Southern Fenlands Ruined Keep, Fireflies & Smoke FX
	if player:
		player.global_position = Vector3(84.0, 0.0, 132.0)
	camera.global_position = Vector3(76.0, 11.0, 122.0)
	camera.look_at(Vector3(98.0, 1.8, 152.0), Vector3.UP)
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/sector_d4_southern_fenlands_keep.png", local_dir + "/sector_d4_southern_fenlands_keep.png")

	# Shot 6K: Opening Title Screen with Live 3D Kingdom Panorama & "Created by daryl.created@gmail.com"
	if player:
		player.global_position = Vector3(0.0, 0.0, 4.0)
	main_node.call("apply_camera_preset", 0, true)
	if hud and hud.has_method("open_opening_title_screen"):
		hud.call("open_opening_title_screen")
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/opening_title_screen.png", local_dir + "/opening_title_screen.png")

	# Shot 6L: In-Game [ESC] Pause & Settings Menu
	if hud and hud.get("main_menu"):
		hud.main_menu.call("_on_continue_pressed")
		hud.main_menu.call("_toggle_settings_subpanel")
		hud.call("open_pause_menu")
	for i in range(6):
		await tree.process_frame
	_save_viewport_image(tree, out_dir + "/pause_settings_menu.png", local_dir + "/pause_settings_menu.png")
	if hud and hud.has_method("close_pause_menu"):
		hud.call("close_pause_menu")

	overlay_layer.queue_free()
	print("==================================================================")
	print("   AERIAL MAPPING COMPLETE: ALL SECTOR MAPS GENERATED   ")
	print("==================================================================")
	tree.quit(0)

static func _save_viewport_image(tree: SceneTree, brain_path: String, local_path: String) -> void:
	var img = tree.root.get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png(brain_path)
		var l_abs = ProjectSettings.globalize_path(local_path)
		img.save_png(l_abs)
		print(" -> Saved Aerial Map: " + brain_path + " (err=" + str(err) + ")")
