extends Node

static func run_audit(main_node: Node3D, out_prefix: String = "before") -> void:
	print("==================================================================")
	print("   WORLD ENVIRONMENT VISUAL SCREENSHOT & SPATIAL AUDIT (" + out_prefix + ")")
	print("==================================================================")
	var tree = main_node.get_tree()
	await tree.process_frame
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame

	var camera: Camera3D = main_node.get("camera")
	var hud: CanvasLayer = main_node.get("hud")
	var cam_ui: Control = main_node.get("camera_ui_container")
	var player: Node3D = main_node.get("player")

	# Lock camera control in Main.gd during screenshot capture
	main_node.set_physics_process(false)
	if hud:
		hud.visible = false
	if cam_ui:
		cam_ui.visible = false
	if player:
		player.visible = false

	var out_dir = "C:/Users/daryl/.gemini/antigravity/brain/640c2dd3-f80b-4056-8054-fea3906ae403"
	DirAccess.make_dir_recursive_absolute(out_dir)

	# 1. Print Native Model Dimensions & Audit Scene Overlaps
	if out_prefix == "before":
		_print_building_model_metrics()
	_audit_scene_overlaps(main_node.get("current_room"))

	var views = [
		{
			"name": "01_overview_central",
			"cam_pos": Vector3(0.0, 95.0, 75.0),
			"look_at": Vector3(0.0, 0.0, 20.0),
			"fov": 60.0
		},
		{
			"name": "02_port_blackwater_overview",
			"cam_pos": Vector3(-38.0, 32.0, 96.0),
			"look_at": Vector3(-72.0, 0.0, 66.0),
			"fov": 55.0
		},
		{
			"name": "03_port_ships_and_piers",
			"cam_pos": Vector3(-52.0, 18.0, 92.0),
			"look_at": Vector3(-80.0, 1.0, 68.0),
			"fov": 50.0
		},
		{
			"name": "04_oakhaven_town_and_market",
			"cam_pos": Vector3(8.0, 26.0, 34.0),
			"look_at": Vector3(-12.0, 1.0, 14.0),
			"fov": 52.0
		},
		{
			"name": "05_east_village_and_watermill",
			"cam_pos": Vector3(44.0, 26.0, 34.0),
			"look_at": Vector3(24.0, 1.0, 13.0),
			"fov": 52.0
		},
		{
			"name": "06_sunnydale_farmlands_pasture",
			"cam_pos": Vector3(12.0, 24.0, 56.0),
			"look_at": Vector3(31.0, 1.0, 36.0),
			"fov": 52.0
		},
		{
			"name": "07_castle_citadel_and_siege",
			"cam_pos": Vector3(28.0, 30.0, 88.0),
			"look_at": Vector3(0.0, 2.0, 56.0),
			"fov": 55.0
		},
		{
			"name": "08_greenhollow_village",
			"cam_pos": Vector3(-30.0, 22.0, 0.0),
			"look_at": Vector3(-50.0, 1.0, -20.0),
			"fov": 50.0
		},
		{
			"name": "09_whisperwood_forest_enclave",
			"cam_pos": Vector3(-56.0, 26.0, -40.0),
			"look_at": Vector3(-80.0, 1.0, -64.0),
			"fov": 52.0
		},
		{
			"name": "10_khar_drakken_crags_mines",
			"cam_pos": Vector3(50.0, 30.0, -36.0),
			"look_at": Vector3(80.0, 2.0, -68.0),
			"fov": 55.0
		},
		{
			"name": "11_weeping_fen_swamp",
			"cam_pos": Vector3(56.0, 26.0, 62.0),
			"look_at": Vector3(84.0, 0.0, 88.0),
			"fov": 52.0
		}
	]

	var orig_fov = camera.fov
	for v in views:
		camera.fov = v["fov"]
		camera.global_position = v["cam_pos"]
		camera.look_at(v["look_at"], Vector3.UP)
		await tree.process_frame
		await tree.process_frame
		await RenderingServer.frame_post_draw
		var img = main_node.get_viewport().get_texture().get_image()
		var file_path = out_dir + "/" + out_prefix + "_" + v["name"] + ".png"
		var err = img.save_png(file_path)
		print(" -> Saved screenshot: ", file_path, " (err=", err, ")")

	camera.fov = orig_fov
	print("==================================================================")
	print("   SCREENSHOT CAPTURE COMPLETE")
	print("==================================================================")
	tree.quit(0)

static func _get_combined_aabb(node: Node3D, root_inv: Transform3D) -> AABB:
	var first = true
	var total = AABB()
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var vi = child as VisualInstance3D
		if not vi or vi is Label3D or vi is Light3D or vi is CPUParticles3D:
			continue
		var local_aabb = vi.get_aabb()
		if local_aabb.size == Vector3.ZERO:
			continue
		var rel_xform = root_inv * vi.global_transform
		var transformed_aabb = rel_xform * local_aabb
		if first:
			total = transformed_aabb
			first = false
		else:
			total = total.merge(transformed_aabb)
	return total

static func _print_building_model_metrics() -> void:
	print("\n--- NATIVE 3D MODEL METRICS (Unscaled) ---")
	var paths = [
		"res://assets/overworld/crypt.gltf",
		"res://assets/overworld/building_blacksmith_blue.gltf",
		"res://assets/overworld/building_church_blue.gltf",
		"res://assets/overworld/building_tavern_blue.gltf",
		"res://assets/overworld/building_market_blue.gltf",
		"res://assets/overworld/building_archeryrange_blue.gltf",
		"res://assets/overworld/building_watermill_blue.gltf",
		"res://assets/overworld/building_windmill_blue.gltf",
		"res://assets/overworld/building_home_A_blue.gltf",
		"res://assets/overworld/building_home_B_blue.gltf",
		"res://assets/overworld/building_well_blue.gltf",
		"res://assets/overworld/building_castle_blue.gltf",
		"res://assets/overworld/building_tower_catapult_blue.gltf",
		"res://assets/overworld/building_barracks_blue.gltf",
		"res://assets/overworld/building_lumbermill_blue.gltf",
		"res://assets/overworld/building_mine_blue.gltf",
		"res://assets/overworld/building_grain.gltf",
		"res://assets/overworld/building_bridge_A.gltf",
		"res://assets/overworld/building_bridge_B.gltf",
		"res://assets/overworld/wall_straight.gltf",
		"res://assets/overworld/arch.gltf",
		"res://assets/overworld/arch_gate.gltf"
	]
	for p in paths:
		var s = load(p)
		if s:
			var inst = s.instantiate() as Node3D
			var aabb = AABB()
			var first = true
			for vi in inst.find_children("*", "MeshInstance3D", true, false):
				var mi = vi as MeshInstance3D
				if mi and mi.mesh:
					var ma = mi.transform * mi.mesh.get_aabb()
					if first:
						aabb = ma
						first = false
					else:
						aabb = aabb.merge(ma)
			print("  ", p.get_file(), " -> pos:", snapped(aabb.position, Vector3(0.01,0.01,0.01)), " size:", snapped(aabb.size, Vector3(0.01,0.01,0.01)))
			inst.free()

static func _audit_scene_overlaps(room: Node3D) -> void:
	if not room:
		return
	print("\n--- AUDITING WORLD STRUCTURES & OVERLAPS ---")
	var items = []
	for child in room.get_children():
		if not (child is Node3D):
			continue
		var c3 = child as Node3D
		if c3.position.y < -20.0:
			continue # Skip subterranean interiors
		var n = c3.name
		if "Grass" in n or "River" in n or "Ocean" in n or "Swamp" in n or "Sand" in n or "Collider" in n or "Barrier" in n:
			continue
		var aabb = _get_combined_aabb(c3, Transform3D.IDENTITY)
		if aabb.size.length() > 0.1 and aabb.size.x < 100.0 and aabb.size.z < 100.0:
			# Filter out flat floor tiles/paths for structure overlap checks
			if aabb.size.y > 1.2:
				items.append({"name": n, "pos": c3.global_position, "aabb": aabb})

	print("Total vertical structures/props/trees/ships/actors audited: ", items.size())
	var overlap_count = 0
	for i in range(items.size()):
		for j in range(i + 1, items.size()):
			var a = items[i]
			var b = items[j]
			# Shrink AABB slightly by 0.25m to ignore intentional touching (like walls/fences)
			var box_a = a["aabb"].grow(-0.35)
			var box_b = b["aabb"].grow(-0.35)
			if box_a. size.x > 0 and box_a.size.y > 0 and box_a.size.z > 0 and box_b.size.x > 0 and box_b.size.y > 0 and box_b.size.z > 0:
				if box_a.intersects(box_b):
					# Ignore fence-to-fence or rock-to-rock
					if ("fence" in a["name"].to_lower() and "fence" in b["name"].to_lower()) or ("wall" in a["name"].to_lower() and "wall" in b["name"].to_lower()):
						continue
					overlap_count += 1
					if overlap_count <= 60:
						print("  [OVERLAP] ", a["name"], " at ", snapped(a["pos"], Vector3(0.1,0.1,0.1)), " (size ", snapped(a["aabb"].size, Vector3(0.1,0.1,0.1)), ") <-> ", b["name"], " at ", snapped(b["pos"], Vector3(0.1,0.1,0.1)), " (size ", snapped(b["aabb"].size, Vector3(0.1,0.1,0.1)), ")")
	print("Total significant AABB overlaps detected: ", overlap_count)
