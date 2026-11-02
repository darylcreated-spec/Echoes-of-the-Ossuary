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
var _helm_wheel: Node3D = null

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
	hull_mat.albedo_color = Color(0.26, 0.17, 0.10)
	hull_mat.roughness = 0.86

	var plank_mat = StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.32, 0.21, 0.13)
	plank_mat.roughness = 0.84

	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.40, 0.28, 0.18)
	deck_mat.roughness = 0.82

	var mast_mat = StandardMaterial3D.new()
	mast_mat.albedo_color = Color(0.30, 0.20, 0.12)
	mast_mat.roughness = 0.85

	var rope_mat = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.48, 0.38)
	rope_mat.roughness = 0.90

	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.18, 0.20, 0.22)
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.45

	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.85, 0.70, 0.22)
	gold_mat.metallic = 0.75
	gold_mat.roughness = 0.30

	# 1. LOWER KEEL & MAIN HULL (16.5m length x 5.6m beam)
	var keel = MeshInstance3D.new()
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(0.6, 0.8, 16.5)
	k_mesh.material = hull_mat
	keel.mesh = k_mesh
	keel.position = Vector3(0.0, -0.2, 0.0)
	_hull_pivot.add_child(keel)

	# Main Hull Body
	var hull_main = MeshInstance3D.new()
	var hm_mesh = BoxMesh.new()
	hm_mesh.size = Vector3(5.6, 2.4, 13.0)
	hm_mesh.material = hull_mat
	hull_main.mesh = hm_mesh
	hull_main.position = Vector3(0.0, 0.7, 0.0)
	_hull_pivot.add_child(hull_main)

	# Timber Rub-Rails / Wales (horizontal protective bands along port and starboard)
	for side_x in [-2.85, 2.85]:
		for rail_y in [0.4, 1.2]:
			var wale = MeshInstance3D.new()
			var w_mesh = BoxMesh.new()
			w_mesh.size = Vector3(0.2, 0.18, 13.4)
			w_mesh.material = plank_mat
			wale.mesh = w_mesh
			wale.position = Vector3(side_x, rail_y, 0.0)
			_hull_pivot.add_child(wale)

	# Bow Prow (Pointed forward timber stem)
	var prow = MeshInstance3D.new()
	var pr_mesh = PrismMesh.new()
	pr_mesh.size = Vector3(5.4, 3.8, 2.8)
	pr_mesh.material = hull_mat
	prow.mesh = pr_mesh
	prow.position = Vector3(0.0, 0.85, -7.9)
	prow.rotation_degrees.x = -90.0
	_hull_pivot.add_child(prow)

	# Curved Bow Stempost & Figurehead (Golden Lion Crest on the Prow)
	var stempost = MeshInstance3D.new()
	var sp_mesh = BoxMesh.new()
	sp_mesh.size = Vector3(0.4, 3.6, 0.6)
	sp_mesh.material = plank_mat
	stempost.mesh = sp_mesh
	stempost.position = Vector3(0.0, 1.8, -9.4)
	stempost.rotation_degrees.x = 24.0
	_hull_pivot.add_child(stempost)

	var figurehead = MeshInstance3D.new()
	var fh_mesh = SphereMesh.new()
	fh_mesh.radius = 0.38
	fh_mesh.height = 0.76
	fh_mesh.material = gold_mat
	figurehead.mesh = fh_mesh
	figurehead.position = Vector3(0.0, 3.2, -9.9)
	_hull_pivot.add_child(figurehead)

	# Bowsprit Spar (Forward jutting mast beam)
	var bowsprit = MeshInstance3D.new()
	var bs_mesh = CylinderMesh.new()
	bs_mesh.top_radius = 0.10
	bs_mesh.bottom_radius = 0.18
	bs_mesh.height = 5.2
	bs_mesh.material = mast_mat
	bowsprit.mesh = bs_mesh
	bowsprit.position = Vector3(0.0, 2.9, -11.0)
	bowsprit.rotation_degrees.x = -72.0
	_hull_pivot.add_child(bowsprit)

	# Heavy Iron Anchor & Chain on Starboard Bow
	var anchor_chain = MeshInstance3D.new()
	var ac_mesh = CylinderMesh.new()
	ac_mesh.top_radius = 0.06
	ac_mesh.bottom_radius = 0.06
	ac_mesh.height = 2.4
	ac_mesh.material = iron_mat
	anchor_chain.mesh = ac_mesh
	anchor_chain.position = Vector3(2.5, 0.6, -7.2)
	anchor_chain.rotation_degrees.x = 18.0
	_hull_pivot.add_child(anchor_chain)

	var anchor = MeshInstance3D.new()
	var anc_mesh = BoxMesh.new()
	anc_mesh.size = Vector3(0.2, 1.4, 0.8)
	anc_mesh.material = iron_mat
	anchor.mesh = anc_mesh
	anchor.position = Vector3(2.6, -0.4, -6.8)
	_hull_pivot.add_child(anchor)

	# 2. MAIN WEATHER DECK & BULWARKS
	var deck = MeshInstance3D.new()
	var dk_mesh = BoxMesh.new()
	dk_mesh.size = Vector3(5.7, 0.25, 13.2)
	dk_mesh.material = deck_mat
	deck.mesh = dk_mesh
	deck.position = Vector3(0.0, 1.85, 0.0)
	_hull_pivot.add_child(deck)

	# Port Bulwark (Full length)
	var port_gw = MeshInstance3D.new()
	var pgw_mesh = BoxMesh.new()
	pgw_mesh.size = Vector3(0.25, 0.95, 12.8)
	pgw_mesh.material = plank_mat
	port_gw.mesh = pgw_mesh
	port_gw.position = Vector3(-2.75, 2.35, 0.0)
	_hull_pivot.add_child(port_gw)

	# Starboard Bulwark (split for boarding gate when gangplank active)
	if has_gangplank:
		for seg_z in [-3.8, 3.8]:
			var stbd_gw = MeshInstance3D.new()
			var sgw_mesh = BoxMesh.new()
			sgw_mesh.size = Vector3(0.25, 0.95, 5.2)
			sgw_mesh.material = plank_mat
			stbd_gw.mesh = sgw_mesh
			stbd_gw.position = Vector3(2.75, 2.35, seg_z)
			_hull_pivot.add_child(stbd_gw)
	else:
		var stbd_gw = MeshInstance3D.new()
		stbd_gw.mesh = pgw_mesh
		stbd_gw.position = Vector3(2.75, 2.35, 0.0)
		_hull_pivot.add_child(stbd_gw)

	# Deck Cargo Hatch with Wood Grating
	var hatch = MeshInstance3D.new()
	var ht_mesh = BoxMesh.new()
	ht_mesh.size = Vector3(2.2, 0.16, 2.6)
	ht_mesh.material = plank_mat
	hatch.mesh = ht_mesh
	hatch.position = Vector3(0.0, 1.95, -2.2)
	_hull_pivot.add_child(hatch)

	# 3. HIGH FORECASTLE PLATFORM (Bow Deck, Z in [-6.5, -4.2])
	var f_castle = MeshInstance3D.new()
	var fc_mesh = BoxMesh.new()
	fc_mesh.size = Vector3(4.8, 1.5, 3.2)
	fc_mesh.material = hull_mat
	f_castle.mesh = fc_mesh
	f_castle.position = Vector3(0.0, 2.5, -5.2)
	_hull_pivot.add_child(f_castle)

	var fc_deck = MeshInstance3D.new()
	var fcd_mesh = BoxMesh.new()
	fcd_mesh.size = Vector3(5.0, 0.22, 3.4)
	fcd_mesh.material = deck_mat
	fc_deck.mesh = fcd_mesh
	fc_deck.position = Vector3(0.0, 3.35, -5.2)
	_hull_pivot.add_child(fc_deck)

	# Forecastle Railings
	for side_x in [-2.4, 2.4]:
		var fc_rail = MeshInstance3D.new()
		var fcr_mesh = BoxMesh.new()
		fcr_mesh.size = Vector3(0.18, 0.85, 3.4)
		fcr_mesh.material = plank_mat
		fc_rail.mesh = fcr_mesh
		fc_rail.position = Vector3(side_x, 3.85, -5.2)
		_hull_pivot.add_child(fc_rail)

	# Forecastle Ladder / Companionway Stairs
	var fc_stairs = MeshInstance3D.new()
	var fcs_mesh = BoxMesh.new()
	fcs_mesh.size = Vector3(1.1, 1.4, 0.3)
	fcs_mesh.material = plank_mat
	fc_stairs.mesh = fcs_mesh
	fc_stairs.position = Vector3(1.6, 2.55, -3.4)
	fc_stairs.rotation_degrees.x = -38.0
	_hull_pivot.add_child(fc_stairs)

	# 4. STEPPED STERNCASLE & CAPTAIN'S CABIN (Aft Quarterdeck, Z in [3.4, 7.2])
	var stern = MeshInstance3D.new()
	var st_mesh = BoxMesh.new()
	st_mesh.size = Vector3(5.7, 2.5, 4.2)
	st_mesh.material = hull_mat
	stern.mesh = st_mesh
	stern.position = Vector3(0.0, 2.9, 5.0)
	_hull_pivot.add_child(stern)

	# Glowing Transom Windows on Aft Transom
	var win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color(1.0, 0.88, 0.45)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.78, 0.35)
	win_mat.emission_energy_multiplier = 1.8

	for wx in [-1.6, 0.0, 1.6]:
		var win = MeshInstance3D.new()
		var w_mesh = BoxMesh.new()
		w_mesh.size = Vector3(0.9, 0.9, 0.15)
		w_mesh.material = win_mat
		win.mesh = w_mesh
		win.position = Vector3(wx, 3.1, 7.15)
		_hull_pivot.add_child(win)

	# Quarterdeck Floor & Railings
	var q_deck = MeshInstance3D.new()
	var qd_mesh = BoxMesh.new()
	qd_mesh.size = Vector3(5.9, 0.22, 4.4)
	qd_mesh.material = deck_mat
	q_deck.mesh = qd_mesh
	q_deck.position = Vector3(0.0, 4.25, 5.0)
	_hull_pivot.add_child(q_deck)

	for side_x in [-2.85, 2.85]:
		var q_rail = MeshInstance3D.new()
		var qr_mesh = BoxMesh.new()
		qr_mesh.size = Vector3(0.2, 0.9, 4.4)
		qr_mesh.material = plank_mat
		q_rail.mesh = qr_mesh
		q_rail.position = Vector3(side_x, 4.8, 5.0)
		_hull_pivot.add_child(q_rail)

	# Transom Stern Railing
	var aft_rail = MeshInstance3D.new()
	var ar_mesh = BoxMesh.new()
	ar_mesh.size = Vector3(5.9, 0.9, 0.2)
	ar_mesh.material = plank_mat
	aft_rail.mesh = ar_mesh
	aft_rail.position = Vector3(0.0, 4.8, 7.15)
	_hull_pivot.add_child(aft_rail)

	# Stern Quarterdeck Stairs
	var q_stairs = MeshInstance3D.new()
	var qs_mesh = BoxMesh.new()
	qs_mesh.size = Vector3(1.2, 2.2, 0.35)
	qs_mesh.material = plank_mat
	q_stairs.mesh = qs_mesh
	q_stairs.position = Vector3(-1.7, 3.0, 2.7)
	q_stairs.rotation_degrees.x = 42.0
	_hull_pivot.add_child(q_stairs)

	# Wooden Ship's Rudder mounted to sternpost below waterline
	var rudder = MeshInstance3D.new()
	var rd_mesh = BoxMesh.new()
	rd_mesh.size = Vector3(0.3, 2.6, 1.4)
	rd_mesh.material = plank_mat
	rudder.mesh = rd_mesh
	rudder.position = Vector3(0.0, 0.4, 7.7)
	_hull_pivot.add_child(rudder)

	# Ship's Steering Wheel / Helm Station on Quarterdeck
	var helm_post = MeshInstance3D.new()
	var hp_mesh = CylinderMesh.new()
	hp_mesh.top_radius = 0.14
	hp_mesh.bottom_radius = 0.18
	hp_mesh.height = 1.05
	hp_mesh.material = mast_mat
	helm_post.mesh = hp_mesh
	helm_post.position = Vector3(0.0, 4.85, 4.6)
	_hull_pivot.add_child(helm_post)

	_helm_wheel = Node3D.new()
	_helm_wheel.position = Vector3(0.0, 5.35, 4.5)
	var wheel_rim = MeshInstance3D.new()
	var wr_mesh = TorusMesh.new()
	wr_mesh.inner_radius = 0.42
	wr_mesh.outer_radius = 0.55
	wr_mesh.material = gold_mat
	wheel_rim.mesh = wr_mesh
	wheel_rim.rotation_degrees.x = 90.0
	_helm_wheel.add_child(wheel_rim)
	for spk in [0.0, 45.0, 90.0, 135.0]:
		var spoke = MeshInstance3D.new()
		var sp_m = CylinderMesh.new()
		sp_m.top_radius = 0.04
		sp_m.bottom_radius = 0.04
		sp_m.height = 1.2
		sp_m.material = mast_mat
		spoke.mesh = sp_m
		spoke.rotation_degrees.z = spk
		_helm_wheel.add_child(spoke)
	_hull_pivot.add_child(_helm_wheel)

	# 5. DUAL-MASTED RIG: TOWERING MAINMAST & FOREMAST
	# Mainmast (14.2m)
	var mainmast = MeshInstance3D.new()
	var mm_mesh = CylinderMesh.new()
	mm_mesh.top_radius = 0.16
	mm_mesh.bottom_radius = 0.30
	mm_mesh.height = 14.2
	mm_mesh.material = mast_mat
	mainmast.mesh = mm_mesh
	mainmast.position = Vector3(0.0, 8.5, 0.4)
	_hull_pivot.add_child(mainmast)

	# Crow's Nest Lookout Basket
	var crows_nest = MeshInstance3D.new()
	var cn_mesh = CylinderMesh.new()
	cn_mesh.top_radius = 0.95
	cn_mesh.bottom_radius = 0.70
	cn_mesh.height = 1.0
	cn_mesh.material = hull_mat
	crows_nest.mesh = cn_mesh
	crows_nest.position = Vector3(0.0, 13.4, 0.4)
	_hull_pivot.add_child(crows_nest)

	# Foremast (9.8m)
	var foremast = MeshInstance3D.new()
	var fm_mesh = CylinderMesh.new()
	fm_mesh.top_radius = 0.12
	fm_mesh.bottom_radius = 0.22
	fm_mesh.height = 9.8
	fm_mesh.material = mast_mat
	foremast.mesh = fm_mesh
	foremast.position = Vector3(0.0, 6.4, -4.8)
	_hull_pivot.add_child(foremast)

	# Rigging Shrouds & Ratlines (Port & Starboard Rope Ladders)
	for side_x in [-2.7, 2.7]:
		for shroud_z in [-0.6, 1.4]:
			var shroud = MeshInstance3D.new()
			var sh_m = CylinderMesh.new()
			sh_m.top_radius = 0.03
			sh_m.bottom_radius = 0.03
			sh_m.height = 11.8
			sh_m.material = rope_mat
			shroud.mesh = sh_m
			var target_top = Vector3(0.0, 13.2, 0.4)
			var base_pt = Vector3(side_x, 2.3, shroud_z)
			shroud.position = (target_top + base_pt) * 0.5
			shroud.look_at_from_position(shroud.position, target_top, Vector3.FORWARD)
			shroud.rotation_degrees.x += 90.0
			_hull_pivot.add_child(shroud)

	# Yardarm Crossbeams & Billowing Cloth Sails
	var flag_shader = load("res://shaders/waving_flag.gdshader")
	var sail_mat: Material = null
	if flag_shader:
		var sm = ShaderMaterial.new()
		sm.shader = flag_shader
		sm.set_shader_parameter("flag_color", sail_color)
		sail_mat = sm
	else:
		var std = StandardMaterial3D.new()
		std.albedo_color = sail_color
		std.cull_mode = BaseMaterial3D.CULL_DISABLED
		sail_mat = std

	# Main Course & Main Topsail
	for sail_spec in [Vector3(6.8, 6.4, 3.0), Vector3(10.6, 5.2, 2.6)]:
		var sy = sail_spec.x
		var yw = sail_spec.y
		var sh = sail_spec.z

		var yard = MeshInstance3D.new()
		var yd_mesh = CylinderMesh.new()
		yd_mesh.top_radius = 0.10
		yd_mesh.bottom_radius = 0.10
		yd_mesh.height = yw + 0.6
		yd_mesh.material = mast_mat
		yard.mesh = yd_mesh
		yard.position = Vector3(0.0, sy + sh * 0.5, 0.25)
		yard.rotation_degrees.z = 90.0
		_hull_pivot.add_child(yard)

		var sail = MeshInstance3D.new()
		var sl_mesh = BoxMesh.new()
		sl_mesh.size = Vector3(yw, sh, 0.12)
		sl_mesh.material = sail_mat
		sail.mesh = sl_mesh
		sail.position = Vector3(0.0, sy, 0.05)
		_hull_pivot.add_child(sail)

	# Foresail on Foremast
	var f_yard = MeshInstance3D.new()
	var fyd_mesh = CylinderMesh.new()
	fyd_mesh.top_radius = 0.08
	fyd_mesh.bottom_radius = 0.08
	fyd_mesh.height = 4.8
	fyd_mesh.material = mast_mat
	f_yard.mesh = fyd_mesh
	f_yard.position = Vector3(0.0, 7.8, -4.95)
	f_yard.rotation_degrees.z = 90.0
	_hull_pivot.add_child(f_yard)

	var f_sail = MeshInstance3D.new()
	var fs_mesh = BoxMesh.new()
	fs_mesh.size = Vector3(4.4, 2.5, 0.10)
	fs_mesh.material = sail_mat
	f_sail.mesh = fs_mesh
	f_sail.position = Vector3(0.0, 6.4, -5.1)
	_hull_pivot.add_child(f_sail)

	# Triangular Jib Sail on Bowsprit
	var jib = MeshInstance3D.new()
	var jib_mesh = PrismMesh.new()
	jib_mesh.size = Vector3(0.1, 4.2, 5.6)
	jib_mesh.material = sail_mat
	jib.mesh = jib_mesh
	jib.position = Vector3(0.0, 5.2, -8.2)
	jib.rotation_degrees.x = -65.0
	_hull_pivot.add_child(jib)

	# Pennant Flag flying atop Mainmast peak
	var flag_scene = load("res://assets/overworld/flag_blue.gltf")
	if flag_scene:
		var pennant = flag_scene.instantiate()
		pennant.scale = Vector3.ONE * 2.4
		pennant.position = Vector3(0.0, 15.2, 0.4)
		_hull_pivot.add_child(pennant)

	# 6. DECK CARGO DRESSING & WARM STERN LANTERNS
	var barrel_scene = load("res://assets/overworld/barrel.gltf")
	if barrel_scene:
		for b_pos in [Vector3(-1.8, 1.95, 0.8), Vector3(-1.8, 1.95, 1.7), Vector3(1.7, 1.95, -1.2)]:
			var b = barrel_scene.instantiate()
			b.scale = Vector3.ONE * 1.3
			b.position = b_pos
			_hull_pivot.add_child(b)

	var crate_scene = load("res://assets/overworld/crate_A_big.gltf")
	if crate_scene:
		var c = crate_scene.instantiate()
		c.scale = Vector3.ONE * 1.4
		c.position = Vector3(1.6, 1.95, 1.2)
		_hull_pivot.add_child(c)

	# Warm Stern Lanterns
	var stern_light = OmniLight3D.new()
	stern_light.light_color = Color(1.0, 0.78, 0.42)
	stern_light.light_energy = 2.4
	stern_light.omni_range = 12.0
	stern_light.position = Vector3(0.0, 5.2, 7.3)
	_hull_pivot.add_child(stern_light)

	# 7. WALKABLE DECK & BOARDING GANGPLANK COLLIDERS
	var sb = StaticBody3D.new()
	sb.name = "ShipDeckCollider"
	sb.collision_layer = 1
	var deck_col = CollisionShape3D.new()
	var deck_box = BoxShape3D.new()
	deck_box.size = Vector3(5.6, 0.4, 13.0)
	deck_col.shape = deck_box
	deck_col.position = Vector3(0.0, 1.75, 0.0)
	sb.add_child(deck_col)

	if has_gangplank:
		var plank = MeshInstance3D.new()
		var pl_mesh = BoxMesh.new()
		pl_mesh.size = Vector3(3.8, 0.18, 1.6)
		pl_mesh.material = deck_mat
		plank.mesh = pl_mesh
		plank.position = Vector3(3.6, 1.05, 0.0)
		plank.rotation_degrees.z = -14.0
		_hull_pivot.add_child(plank)

		var pl_col = CollisionShape3D.new()
		var pl_box = BoxShape3D.new()
		pl_box.size = Vector3(4.2, 0.25, 1.8)
		pl_col.shape = pl_box
		pl_col.position = Vector3(3.6, 1.05, 0.0)
		pl_col.rotation_degrees.z = -14.0
		sb.add_child(pl_col)

	add_child(sb)

	# 8. HIGH-VISIBILITY MEDIEVAL NAMEPLATE
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 7.2, 0.0)
	AssetLoader.style_world_label3d(lbl, "⛵ " + ship_name + "\n[E] Inspect Vessel", 40, Color(1.0, 0.94, 0.72))
	_hull_pivot.add_child(lbl)

	# 9. ANIMATED DECK CREW (Helmsman, Bow Lookout, Deck Sailor)
	var helmsman = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue_Hooded.glb", "character", "Helmsman")
	helmsman.scale = Vector3.ONE * 0.54
	helmsman.position = Vector3(0.0, 4.35, 4.0)
	helmsman.rotation_degrees.y = 180.0
	_hull_pivot.add_child(helmsman)
	var hap = helmsman.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if hap:
		_crew_anims.append(hap)
		_play_ship_crew_anim(hap, "Interact")

	var lookout = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Knight.glb", "character", "Lookout")
	lookout.scale = Vector3.ONE * 0.54
	lookout.position = Vector3(0.0, 3.45, -5.4)
	lookout.rotation_degrees.y = 180.0
	_hull_pivot.add_child(lookout)
	var lap = lookout.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if lap:
		_crew_anims.append(lap)
		_play_ship_crew_anim(lap, "Cheer")

	var sailor = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Barbarian.glb", "character", "Sailor")
	sailor.scale = Vector3.ONE * 0.52
	sailor.position = Vector3(1.2, 1.95, -0.6)
	sailor.rotation_degrees.y = 90.0
	_hull_pivot.add_child(sailor)
	var sap = sailor.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if sap:
		_crew_anims.append(sap)
		_play_ship_crew_anim(sap, "PickUp")

	# 10. Deck Cannons & Cannonball Ammunition Stacks
	var cannon_scene = load("res://assets/ships/cannon.glb")
	if cannon_scene:
		for c_z in [-3.5, 0.0, 3.5]:
			# Port battery
			var c_port = cannon_scene.instantiate()
			c_port.scale = Vector3.ONE * 1.6
			c_port.position = Vector3(-2.25, 1.85, c_z)
			c_port.rotation_degrees.y = -90.0
			_hull_pivot.add_child(c_port)
			# Starboard battery
			var c_star = cannon_scene.instantiate()
			c_star.scale = Vector3.ONE * 1.6
			c_star.position = Vector3(2.25, 1.85, c_z)
			c_star.rotation_degrees.y = 90.0
			_hull_pivot.add_child(c_star)

	var ball_scene = load("res://assets/ships/cannon-ball.glb")
	if ball_scene:
		for b_z in [-2.0, 2.0]:
			var balls = ball_scene.instantiate()
			balls.scale = Vector3.ONE * 1.3
			balls.position = Vector3(0.0, 1.85, b_z)
			_hull_pivot.add_child(balls)

	# 11. Ocean Hull Wake & White Churn Foam Sprites along Port & Starboard Waterline
	_build_ocean_wake_vfx(2.6, 13.0)

func _build_ocean_wake_vfx(half_beam: float, length: float) -> void:
	for side_x in [-half_beam, half_beam]:
		var wake = CPUParticles3D.new()
		wake.name = "WaterlineWake_%s" % ("Port" if side_x < 0 else "Starboard")
		wake.position = Vector3(side_x, 0.05, 0.0)
		wake.amount = 14
		wake.lifetime = 1.6
		wake.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		wake.emission_box_extents = Vector3(0.35, 0.02, length * 0.45)
		wake.direction = Vector3(side_x * 0.5, 0.0, 0.5).normalized()
		wake.spread = 28.0
		wake.gravity = Vector3.ZERO
		wake.initial_velocity_min = 0.2
		wake.initial_velocity_max = 0.6
		wake.scale_amount_min = 0.8
		wake.scale_amount_max = 2.0
		wake.color = Color(0.92, 0.96, 1.0, 0.65)

		var wake_mat = StandardMaterial3D.new()
		wake_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wake_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wake_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		var tex = load("res://assets/particles/twirl_01.png")
		if not tex:
			tex = load("res://assets/particles/smoke_01.png")
		if tex:
			wake_mat.albedo_texture = tex
		var q_m = QuadMesh.new()
		q_m.size = Vector2(0.95, 0.95)
		q_m.material = wake_mat
		wake.mesh = q_m
		_hull_pivot.add_child(wake)

func _build_rowboat() -> void:
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.24, 0.15)
	wood_mat.roughness = 0.85

	var plank_mat = StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.44, 0.30, 0.18)
	plank_mat.roughness = 0.82

	# Hull Main Shell
	var hull = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(1.8, 0.70, 4.0)
	h_mesh.material = wood_mat
	hull.mesh = h_mesh
	hull.position = Vector3(0.0, 0.28, 0.0)
	_hull_pivot.add_child(hull)

	# Stem and Stern Knees (Tapered ends)
	for end_z in [-2.1, 2.1]:
		var stem = MeshInstance3D.new()
		var st_m = PrismMesh.new()
		st_m.size = Vector3(1.7, 0.9, 0.6)
		st_m.material = wood_mat
		stem.mesh = st_m
		stem.position = Vector3(0.0, 0.35, end_z)
		stem.rotation_degrees.x = -90.0 if end_z < 0 else 90.0
		_hull_pivot.add_child(stem)

	# Gunwale rails & Rowlocks
	for side_x in [-0.92, 0.92]:
		var gw = MeshInstance3D.new()
		var gw_m = BoxMesh.new()
		gw_m.size = Vector3(0.12, 0.22, 4.2)
		gw_m.material = plank_mat
		gw.mesh = gw_m
		gw.position = Vector3(side_x, 0.65, 0.0)
		_hull_pivot.add_child(gw)

	# Benches (Thwarts)
	for bench_z in [-1.0, 0.0, 1.0]:
		var bench = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(1.65, 0.12, 0.40)
		b_mesh.material = plank_mat
		bench.mesh = b_mesh
		bench.position = Vector3(0.0, 0.55, bench_z)
		_hull_pivot.add_child(bench)

	# Articulated Rowing Oars on Port & Starboard Gunwales
	_left_oar = Node3D.new()
	_left_oar.position = Vector3(-0.95, 0.65, 0.0)
	var lo_mesh = MeshInstance3D.new()
	var oar_box = BoxMesh.new()
	oar_box.size = Vector3(2.1, 0.08, 0.18)
	oar_box.material = plank_mat
	lo_mesh.mesh = oar_box
	lo_mesh.position = Vector3(-0.85, -0.15, 0.0)
	lo_mesh.rotation_degrees.z = 16.0
	_left_oar.add_child(lo_mesh)
	_hull_pivot.add_child(_left_oar)

	_right_oar = Node3D.new()
	_right_oar.position = Vector3(0.95, 0.65, 0.0)
	var ro_mesh = MeshInstance3D.new()
	ro_mesh.mesh = oar_box
	ro_mesh.position = Vector3(0.85, -0.15, 0.0)
	ro_mesh.rotation_degrees.z = -16.0
	_right_oar.add_child(ro_mesh)
	_hull_pivot.add_child(_right_oar)

	# High-Visibility Medieval Boat Label
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 2.6, 0.0)
	AssetLoader.style_world_label3d(lbl, "🛶 " + ship_name + "\n[E] Inspect Boat", 34, Color(1.0, 0.94, 0.72))
	_hull_pivot.add_child(lbl)

	# Animated Harbor Oarsman on Center Bench
	var rower = AssetLoader.load_or_generate_model("res://assets/characters/adventurers/Rogue.glb", "character", "Rower")
	rower.scale = Vector3.ONE * 0.50
	rower.position = Vector3(0.0, 0.55, 0.0)
	_hull_pivot.add_child(rower)
	var rap = rower.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if rap:
		_crew_anims.append(rap)
		_play_ship_crew_anim(rap, "Interact")

	# Rowboat Waterline Wake Foam
	_build_ocean_wake_vfx(0.9, 4.0)

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 3.6 if is_rowboat else 8.0
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
	for candidate in [keyword.to_lower(), "idle", "interact", "cheer", "pickup"]:
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

	if _helm_wheel:
		_helm_wheel.rotation_degrees.y = sin(_wave_time * 0.8) * 18.0

	if _left_oar and _right_oar:
		var row_sweep = sin(_wave_time * 2.8) * 28.0
		var row_dip = cos(_wave_time * 2.8) * 10.0
		_left_oar.rotation_degrees.y = row_sweep
		_left_oar.rotation_degrees.z = row_dip
		_right_oar.rotation_degrees.y = -row_sweep
		_right_oar.rotation_degrees.z = -row_dip
