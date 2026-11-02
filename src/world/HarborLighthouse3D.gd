class_name HarborLighthouse3D
extends Node3D

## HarborLighthouse3D
## Massive coastal stone lighthouse situated at North Headland promontory.
## Features a rotating high-intensity maritime beacon, catwalk platform, and interactive foghorn.

@export var rotation_speed: float = 0.85
@export var beacon_energy: float = 8.0
@export var beacon_range: float = 75.0

var _lantern_pivot: Node3D = null
var _beam_spotlight: SpotLight3D = null
var _beam_cone_mesh: MeshInstance3D = null
var _omni_light: OmniLight3D = null
var _interact_area: Area3D = null

var _has_blown_horn: bool = false
var interact_prompt: String = "[E] Sound Lighthouse Foghorn"

func _ready() -> void:
	add_to_group("harbor_structures")
	add_to_group("interactable")
	_build_lighthouse_structure()

func _build_lighthouse_structure() -> void:
	# 1. Base Tower GLB or procedural cylindrical tower
	var tower_model = null
	if ResourceLoader.exists("res://assets/ships/tower-complete-large.glb"):
		var scene = load("res://assets/ships/tower-complete-large.glb")
		if scene:
			tower_model = scene.instantiate()
			tower_model.scale = Vector3(2.0, 2.8, 2.0)
			add_child(tower_model)
	
	if not tower_model:
		# Fallback procedural stone tower
		var body_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 2.4
		cyl.bottom_radius = 3.8
		cyl.height = 14.0
		body_mesh.mesh = cyl
		body_mesh.position.y = 7.0
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.65, 0.60) # granite stone
		mat.roughness = 0.9
		body_mesh.material_override = mat
		add_child(body_mesh)

	# Static collision body for tower base
	var static_body = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 3.6
	cyl_shape.height = 14.0
	col_shape.shape = cyl_shape
	col_shape.position.y = 7.0
	static_body.add_child(col_shape)
	add_child(static_body)

	# 2. Lantern Room & Balcony at height ~14.0m
	var balcony = MeshInstance3D.new()
	var bal_cyl = CylinderMesh.new()
	bal_cyl.top_radius = 3.2
	bal_cyl.bottom_radius = 3.2
	bal_cyl.height = 0.5
	balcony.mesh = bal_cyl
	balcony.position.y = 14.0
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	balcony.material_override = wood_mat
	add_child(balcony)

	# Glass lantern room housing
	var glass_mesh = MeshInstance3D.new()
	var glass_cyl = CylinderMesh.new()
	glass_cyl.top_radius = 2.0
	glass_cyl.bottom_radius = 2.0
	glass_cyl.height = 2.5
	glass_mesh.mesh = glass_cyl
	glass_mesh.position.y = 15.5
	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.35)
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.2
	glass_mesh.material_override = glass_mat
	add_child(glass_mesh)

	# Roof cone
	var roof = MeshInstance3D.new()
	var roof_cone = CylinderMesh.new()
	roof_cone.top_radius = 0.05
	roof_cone.bottom_radius = 2.6
	roof_cone.height = 2.0
	roof.mesh = roof_cone
	roof.position.y = 17.75
	var copper_mat = StandardMaterial3D.new()
	copper_mat.albedo_color = Color(0.22, 0.45, 0.38) # weathered copper
	roof.material_override = copper_mat
	add_child(roof)

	# 3. Rotating Lantern Pivot & Beams
	_lantern_pivot = Node3D.new()
	_lantern_pivot.name = "LanternPivot"
	_lantern_pivot.position.y = 15.5
	add_child(_lantern_pivot)

	# Emissive central lamp core
	var lamp_core = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	lamp_core.mesh = sphere
	var emissive_mat = StandardMaterial3D.new()
	emissive_mat.albedo_color = Color(1.0, 0.95, 0.7)
	emissive_mat.emission_enabled = true
	emissive_mat.emission = Color(1.0, 0.92, 0.6)
	emissive_mat.emission_energy_multiplier = 4.0
	lamp_core.material_override = emissive_mat
	_lantern_pivot.add_child(lamp_core)

	# Primary maritime rotating spotlight beam
	_beam_spotlight = SpotLight3D.new()
	_beam_spotlight.light_color = Color(1.0, 0.94, 0.7)
	_beam_spotlight.light_energy = beacon_energy
	_beam_spotlight.spot_range = beacon_range
	_beam_spotlight.spot_angle = 24.0
	_beam_spotlight.spot_attenuation = 0.6
	_beam_spotlight.shadow_enabled = true
	_beam_spotlight.position = Vector3(0.0, 0.0, 0.5)
	_beam_spotlight.rotation_degrees.x = -6.0 # angled down toward the bay
	_lantern_pivot.add_child(_beam_spotlight)

	# Opposite counter-beam (dual beam lighthouse)
	var back_spotlight = SpotLight3D.new()
	back_spotlight.light_color = Color(1.0, 0.94, 0.7)
	back_spotlight.light_energy = beacon_energy * 0.75
	back_spotlight.spot_range = beacon_range * 0.8
	back_spotlight.spot_angle = 26.0
	back_spotlight.spot_attenuation = 0.6
	back_spotlight.position = Vector3(0.0, 0.0, -0.5)
	back_spotlight.rotation_degrees = Vector3(-6.0, 180.0, 0.0)
	_lantern_pivot.add_child(back_spotlight)

	# Visual volumetric light cone
	_beam_cone_mesh = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.2
	cone.bottom_radius = 6.0
	cone.height = 36.0
	_beam_cone_mesh.mesh = cone
	_beam_cone_mesh.position = Vector3(0.0, -1.8, 18.0)
	_beam_cone_mesh.rotation_degrees.x = 84.0
	var beam_mat = StandardMaterial3D.new()
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.albedo_color = Color(1.0, 0.95, 0.7, 0.18)
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_cone_mesh.material_override = beam_mat
	_lantern_pivot.add_child(_beam_cone_mesh)

	# Local ambient omni light
	_omni_light = OmniLight3D.new()
	_omni_light.light_color = Color(1.0, 0.9, 0.65)
	_omni_light.light_energy = 3.0
	_omni_light.omni_range = 10.0
	_omni_light.position.y = 15.5
	add_child(_omni_light)

	# 4. Foghorn Horn Bells on catwalk
	var horn_mesh = MeshInstance3D.new()
	var horn_cyl = CylinderMesh.new()
	horn_cyl.top_radius = 0.8
	horn_cyl.bottom_radius = 0.25
	horn_cyl.height = 1.6
	horn_mesh.mesh = horn_cyl
	horn_mesh.position = Vector3(0.0, 1.2, 3.2)
	horn_mesh.rotation_degrees.x = 90.0
	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.25)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.3
	horn_mesh.material_override = brass_mat
	add_child(horn_mesh)

	# 5. Interactive Foghorn Area at base / catwalk
	_interact_area = Area3D.new()
	_interact_area.name = "FoghornInteractArea"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4.5, 3.5, 4.5)
	col.shape = box
	col.position = Vector3(0.0, 1.5, 3.5)
	_interact_area.add_child(col)
	_interact_area.collision_layer = 1
	_interact_area.collision_mask = 1
	add_child(_interact_area)

func _process(delta: float) -> void:
	if _lantern_pivot:
		_lantern_pivot.rotate_y(rotation_speed * delta)

func interact(player: Node) -> void:
	sound_foghorn(player)

func sound_foghorn(player: Node = null) -> void:
	AudioManager.play_sfx_at_position("fog_horn", global_position, 85.0, 0.05, 4.0)
	
	# Spawn steam/fog puff from brass horn
	_spawn_foghorn_steam()

	if not _has_blown_horn:
		_has_blown_horn = true
		if GameManager.has_method("add_echoes"):
			GameManager.add_echoes(10)
		HUD.show_notification("Lighthouse Foghorn sounded! Echoes awakened along the bay (+10 Echoes)")
	else:
		HUD.show_notification("The deep harbor foghorn bellows across the choppy waters.")

func _spawn_foghorn_steam() -> void:
	for i in range(12):
		var puff = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = randf_range(0.3, 0.6)
		sphere.height = sphere.radius * 2.0
		puff.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.9, 0.92, 0.95, 0.5)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = mat
		get_tree().current_scene.add_child(puff)
		puff.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 1.2, 4.0)
		
		var tw = puff.create_tween()
		var target_pos = puff.global_position + Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.5), randf_range(2.0, 6.0))
		tw.tween_property(puff, "global_position", target_pos, 1.4)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.4)
		tw.tween_callback(puff.queue_free)
