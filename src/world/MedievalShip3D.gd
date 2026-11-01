extends Node3D
class_name MedievalShip3D

@export var ship_name: String = "The Sea Sovereign"
@export var is_rowboat: bool = false
@export var sail_color: Color = Color(0.92, 0.88, 0.78)
@export var has_gangplank: bool = true

var _hull_pivot: Node3D = null
var _wave_time: float = 0.0
var _creak_timer: float = 0.0
var _left_oar: Node3D = null
var _right_oar: Node3D = null
var _crew_anims: Array = []

func _ready() -> void:
	add_to_group("medieval_ship")
	add_to_group("interactable")
	_wave_time = randf_range(0.0, 20.0)
	_creak_timer = randf_range(0.0, 4.5)
	_hull_pivot = Node3D.new()
	_hull_pivot.name = "HullBuoyancyPivot"
	add_child(_hull_pivot)

	if is_rowboat:
		_build_rowboat()
	else:
		_build_medieval_cog()
	_build_interaction()

func _build_medieval_cog() -> void:
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.28, 0.18, 0.11)
	hull_mat.roughness = 0.88

	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.38, 0.26, 0.16)
	deck_mat.roughness = 0.85

	var mast_mat = StandardMaterial3D.new()
	mast_mat.albedo_color = Color(0.32, 0.22, 0.13)
	mast_mat.roughness = 0.85

	# 1. Lower Keel & Tapered Timber Hull (16m long x 5.2m beam)
	var hull_main = MeshInstance3D.new()
	var hm_mesh = BoxMesh.new()
	hm_mesh.size = Vector3(5.2, 2.2, 12.5)
	hm_mesh.material = hull_mat
	hull_main.mesh = hm_mesh
	hull_main.position = Vector3(0.0, 0.6, 0.0)
	_hull_pivot.add_child(hull_main)

	# Bow Prow (Pointed forward wedge)
	var prow = MeshInstance3D.new()
	var pr_mesh = PrismMesh.new()
	pr_mesh.size = Vector3(5.0, 3.6, 2.4)
	pr_mesh.material = hull_mat
	prow.mesh = pr_mesh
	prow.position = Vector3(0.0, 0.8, -7.8)
	prow.rotation_degrees.x = -90.0
	_hull_pivot.add_child(prow)

	# Main Weather Deck
	var deck = MeshInstance3D.new()
	var dk_mesh = BoxMesh.new()
	dk_mesh.size = Vector3(5.4, 0.24, 13.0)
	dk_mesh.material = deck_mat
	deck.mesh = dk_mesh
	deck.position = Vector3(0.0, 1.75, 0.0)
	_hull_pivot.add_child(deck)

	# Port & Starboard Gunwale Bulwarks
	for side_x in [-2.6, 2.6]:
		var gunwale = MeshInstance3D.new()
		var gw_mesh = BoxMesh.new()
		gw_mesh.size = Vector3(0.22, 0.9, 12.6)
		gw_mesh.material = hull_mat
		gunwale.mesh = gw_mesh
		gunwale.position = Vector3(side_x, 2.2, 0.0)
		_hull_pivot.add_child(gunwale)

	# 2. High Sterncastle (Aft Quarterdeck Cabin, Z in [3.5, 6.8])
	var stern = MeshInstance3D.new()
	var st_mesh = BoxMesh.new()
	st_mesh.size = Vector3(5.4, 2.4, 3.8)
	st_mesh.material = hull_mat
	stern.mesh = st_mesh
	stern.position = Vector3(0.0, 2.8, 4.8)
	_hull_pivot.add_child(stern)

	# Sterncastle Quarterdeck Floor & Railings
	var q_deck = MeshInstance3D.new()
	var qd_mesh = BoxMesh.new()
	qd_mesh.size = Vector3(5.6, 0.2, 4.0)
	qd_mesh.material = deck_mat
	q_deck.mesh = qd_mesh
	q_deck.position = Vector3(0.0, 4.05, 4.8)
	_hull_pivot.add_child(q_deck)

	# 3. Forecastle Platform (Forward Bow Deck, Z in [-6.5, -4.0])
	var f_castle = MeshInstance3D.new()
	var fc_mesh = BoxMesh.new()
	fc_mesh.size = Vector3(4.6, 1.4, 2.8)
	fc_mesh.material = hull_mat
	f_castle.mesh = fc_mesh
	f_castle.position = Vector3(0.0, 2.3, -5.2)
	_hull_pivot.add_child(f_castle)

	# 4. Towering Mainmast (13.5m high) & Foremast (9.5m high)
	var mainmast = MeshInstance3D.new()
	var mm_mesh = CylinderMesh.new()
	mm_mesh.top_radius = 0.16
	mm_mesh.bottom_radius = 0.28
	mm_mesh.height = 13.0
	mm_mesh.material = mast_mat
	mainmast.mesh = mm_mesh
	mainmast.position = Vector3(0.0, 8.0, -0.4)
	_hull_pivot.add_child(mainmast)

	# Crow's Nest Lookout Basket atop Mainmast
	var crows_nest = MeshInstance3D.new()
	var cn_mesh = CylinderMesh.new()
	cn_mesh.top_radius = 0.85
	cn_mesh.bottom_radius = 0.65
	cn_mesh.height = 0.9
	cn_mesh.material = hull_mat
	crows_nest.mesh = cn_mesh
	crows_nest.position = Vector3(0.0, 12.6, -0.4)
	_hull_pivot.add_child(crows_nest)

	# Yardarm Crossbeams & Billowing Square Sails
	var flag_shader = load("res://shaders/waving_flag.gdshader")
	var sail_mat: Material = null
	if flag_shader:
		var sm = ShaderMaterial.new()
		sm.shader = flag_shader
		sail_mat = sm
	else:
		var std = StandardMaterial3D.new()
		std.albedo_color = sail_color
		std.cull_mode = BaseMaterial3D.CULL_DISABLED
		sail_mat = std

	for sail_y in [6.2, 10.2]:
		var yard = MeshInstance3D.new()
		var yd_mesh = CylinderMesh.new()
		yd_mesh.top_radius = 0.10
		yd_mesh.bottom_radius = 0.10
		yd_mesh.height = 6.6
		yd_mesh.material = mast_mat
		yard.mesh = yd_mesh
		yard.position = Vector3(0.0, sail_y + 1.4, -0.55)
		yard.rotation_degrees.z = 90.0
		_hull_pivot.add_child(yard)

		var sail = MeshInstance3D.new()
		var sl_mesh = BoxMesh.new()
		sl_mesh.size = Vector3(6.2, 2.8, 0.12)
		sl_mesh.material = sail_mat
		sail.mesh = sl_mesh
		sail.position = Vector3(0.0, sail_y, -0.75)
		_hull_pivot.add_child(sail)

	# Pennant Flag flying atop the Mainmast peak
	var flag_scene = load("res://assets/overworld/flag_blue.gltf")
	if flag_scene:
		var pennant = flag_scene.instantiate()
		pennant.scale = Vector3.ONE * 2.2
		pennant.position = Vector3(0.0, 14.2, -0.4)
		_hull_pivot.add_child(pennant)

	# 5. Deck Cargo Dressing (Barrels, Crates, Lanterns)
	var barrel_scene = load("res://assets/overworld/barrel.gltf")
	if barrel_scene:
		for b_pos in [Vector3(-1.6, 1.85, 1.2), Vector3(-1.6, 1.85, 2.1), Vector3(1.6, 1.85, -1.5)]:
			var b = barrel_scene.instantiate()
			b.scale = Vector3.ONE * 1.3
			b.position = b_pos
			_hull_pivot.add_child(b)

	var crate_scene = load("res://assets/overworld/crate_A_big.gltf")
	if crate_scene:
		var c = crate_scene.instantiate()
		c.scale = Vector3.ONE * 1.4
		c.position = Vector3(1.5, 1.85, 1.5)
		_hull_pivot.add_child(c)

	# Warm Stern Lanterns
	var stern_light = OmniLight3D.new()
	stern_light.light_color = Color(1.0, 0.78, 0.42)
	stern_light.light_energy = 2.0
	stern_light.omni_range = 10.0
	stern_light.position = Vector3(0.0, 4.8, 6.8)
	_hull_pivot.add_child(stern_light)

	# 6. Walkable Deck & Boarding Gangplank Colliders
	var sb = StaticBody3D.new()
	sb.name = "ShipDeckCollider"
	sb.collision_layer = 1
	var deck_col = CollisionShape3D.new()
	var deck_box = BoxShape3D.new()
	deck_box.size = Vector3(5.2, 0.4, 12.5)
	deck_col.shape = deck_box
	deck_col.position = Vector3(0.0, 1.65, 0.0)
	sb.add_child(deck_col)

	if has_gangplank:
		var plank = MeshInstance3D.new()
		var pl_mesh = BoxMesh.new()
		pl_mesh.size = Vector3(4.5, 0.18, 1.8)
		pl_mesh.material = deck_mat
		plank.mesh = pl_mesh
		plank.position = Vector3(3.8, 1.1, 0.0)
		plank.rotation_degrees.z = -16.0
		_hull_pivot.add_child(plank)

		var pl_col = CollisionShape3D.new()
		var pl_box = BoxShape3D.new()
		pl_box.size = Vector3(4.8, 0.25, 2.0)
		pl_col.shape = pl_box
		pl_col.position = Vector3(3.8, 1.1, 0.0)
		pl_col.rotation_degrees.z = -16.0
		sb.add_child(pl_col)

	add_child(sb)

	# Ship Nameplate
	var lbl = Label3D.new()
	lbl.text = "⛵ " + ship_name + " (Medieval Cog)\n[E] Inspect Vessel"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 6.8, 0.0)
	lbl.font_size = 26
	lbl.outline_size = 6
	lbl.modulate = Color(0.95, 0.90, 0.72)
	_hull_pivot.add_child(lbl)

	# 7. Animated Deck Crew (Quartermaster Helmsman & Bow Lookout)
	var helmsman = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue_Hooded.glb", "character", "Helmsman")
	helmsman.scale = Vector3.ONE * 0.54
	helmsman.position = Vector3(0.0, 4.15, 4.2)
	helmsman.rotation_degrees.y = 180.0
	_hull_pivot.add_child(helmsman)
	var hap = helmsman.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if hap:
		_crew_anims.append(hap)
		_play_ship_crew_anim(hap, "Idle")

	var lookout = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Knight.glb", "character", "Lookout")
	lookout.scale = Vector3.ONE * 0.54
	lookout.position = Vector3(0.0, 3.0, -5.0)
	lookout.rotation_degrees.y = 180.0
	_hull_pivot.add_child(lookout)
	var lap = lookout.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if lap:
		_crew_anims.append(lap)
		_play_ship_crew_anim(lap, "Cheer")

func _build_rowboat() -> void:
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.23, 0.14)
	wood_mat.roughness = 0.88

	var hull = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(1.6, 0.65, 3.8)
	h_mesh.material = wood_mat
	hull.mesh = h_mesh
	hull.position = Vector3(0.0, 0.25, 0.0)
	_hull_pivot.add_child(hull)

	for bench_z in [-0.9, 0.0, 0.9]:
		var bench = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(1.5, 0.12, 0.35)
		b_mesh.material = wood_mat
		bench.mesh = b_mesh
		bench.position = Vector3(0.0, 0.55, bench_z)
		_hull_pivot.add_child(bench)

	# Articulated Rowing Oars on Port & Starboard Gunwales
	_left_oar = Node3D.new()
	_left_oar.position = Vector3(-0.8, 0.62, 0.0)
	var lo_mesh = MeshInstance3D.new()
	var oar_box = BoxMesh.new()
	oar_box.size = Vector3(1.9, 0.08, 0.16)
	oar_box.material = wood_mat
	lo_mesh.mesh = oar_box
	lo_mesh.position = Vector3(-0.75, -0.15, 0.0)
	lo_mesh.rotation_degrees.z = 16.0
	_left_oar.add_child(lo_mesh)
	_hull_pivot.add_child(_left_oar)

	_right_oar = Node3D.new()
	_right_oar.position = Vector3(0.8, 0.62, 0.0)
	var ro_mesh = MeshInstance3D.new()
	ro_mesh.mesh = oar_box
	ro_mesh.position = Vector3(0.75, -0.15, 0.0)
	ro_mesh.rotation_degrees.z = -16.0
	_right_oar.add_child(ro_mesh)
	_hull_pivot.add_child(_right_oar)

	# Animated Harbor Oarsman on Center Bench
	var rower = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue.glb", "character", "Rower")
	rower.scale = Vector3.ONE * 0.48
	rower.position = Vector3(0.0, 0.55, 0.0)
	_hull_pivot.add_child(rower)
	var rap = rower.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if rap:
		_crew_anims.append(rap)
		_play_ship_crew_anim(rap, "Interact")

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 3.2 if is_rowboat else 7.5
	col.shape = sp
	col.position = Vector3(0.0, 1.5, 0.0)
	area.add_child(col)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Inspect " + ship_name

func interact(_player: Node = null) -> void:
	AudioManager.play_sfx_at_position("ship_creak", global_position, 36.0, 0.08, 0.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		var desc = "Harbor rowboat plying the Port Blackwater shoals." if is_rowboat else "High-seas medieval cog moored at Port Blackwater. Walk up the boarding gangplank to explore the weather deck!"
		hud.show_toast("⛵ " + ship_name + ": " + desc)

func _play_ship_crew_anim(ap: AnimationPlayer, keyword: String) -> void:
	if not ap:
		return
	var anims = ap.get_animation_list()
	var chosen = ""
	for candidate in [keyword.to_lower(), "idle", "interact", "cheer"]:
		for a in anims:
			if candidate in a.to_lower():
				chosen = a
				break
		if chosen != "":
			break
	if chosen == "" and anims.size() > 0:
		chosen = anims[0]
	if chosen != "":
		var res = ap.get_animation(chosen)
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
		ap.play(chosen, 0.2)

func _process(delta: float) -> void:
	_wave_time += delta
	_creak_timer += delta
	if _creak_timer >= 5.2:
		_creak_timer = 0.0
		AudioManager.play_sfx_at_position("ship_creak", global_position, 28.0, 0.1, -8.0)

	for ap in _crew_anims:
		if is_instance_valid(ap) and not ap.is_playing():
			_play_ship_crew_anim(ap, "Idle")

	if _hull_pivot:
		_hull_pivot.position.y = sin(_wave_time * 1.6) * 0.12
		_hull_pivot.rotation_degrees.z = sin(_wave_time * 1.2) * 1.8
		_hull_pivot.rotation_degrees.x = cos(_wave_time * 0.9) * 1.2

	if _left_oar and _right_oar:
		var row_sweep = sin(_wave_time * 2.8) * 28.0
		var row_dip = cos(_wave_time * 2.8) * 10.0
		_left_oar.rotation_degrees.y = row_sweep
		_left_oar.rotation_degrees.z = row_dip
		_right_oar.rotation_degrees.y = -row_sweep
		_right_oar.rotation_degrees.z = -row_dip
