extends Area3D
class_name DescentSigil

var _has_triggered: bool = false
var _time: float = 0.0

var _outer_ring: MeshInstance3D = null
var _inner_disc: MeshInstance3D = null
var _core_disc: MeshInstance3D = null
var _beacon_beam: MeshInstance3D = null
var _beacon_light: OmniLight3D = null
var _label: Label3D = null

func _ready() -> void:
	name = "DescentSigil"
	add_to_group("descent_sigil")
	collision_layer = 1 << 5 # Layer 6: Interactable
	collision_mask = 1 << 1  # Layer 2: Player
	
	_build_collision()
	_build_visuals()
	
	body_entered.connect(_on_body_entered)

func _build_collision() -> void:
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.4
	shape.height = 3.5
	col.shape = shape
	col.position.y = 1.75
	add_child(col)

func _build_visuals() -> void:
	# 1. Outer Glowing Runic Ring
	_outer_ring = MeshInstance3D.new()
	var outer_cyl = CylinderMesh.new()
	outer_cyl.top_radius = 2.4
	outer_cyl.bottom_radius = 2.4
	outer_cyl.height = 0.08
	_outer_ring.mesh = outer_cyl
	
	var mat_outer = StandardMaterial3D.new()
	mat_outer.albedo_color = Color(0.1, 0.85, 1.0, 0.8)
	mat_outer.emission_enabled = true
	mat_outer.emission = Color(0.15, 0.9, 1.0)
	mat_outer.emission_energy_multiplier = 3.2
	_outer_ring.material_override = mat_outer
	_outer_ring.position.y = 0.04
	add_child(_outer_ring)

	# 2. Inner Rotating Runic Disc
	_inner_disc = MeshInstance3D.new()
	var inner_cyl = CylinderMesh.new()
	inner_cyl.top_radius = 1.7
	inner_cyl.bottom_radius = 1.7
	inner_cyl.height = 0.10
	_inner_disc.mesh = inner_cyl
	
	var mat_inner = StandardMaterial3D.new()
	mat_inner.albedo_color = Color(0.2, 0.95, 1.0)
	mat_inner.emission_enabled = true
	mat_inner.emission = Color(0.25, 0.95, 1.0)
	mat_inner.emission_energy_multiplier = 4.0
	_inner_disc.material_override = mat_inner
	_inner_disc.position.y = 0.05
	add_child(_inner_disc)

	# 3. Bright White-Cyan Core Well
	_core_disc = MeshInstance3D.new()
	var core_cyl = CylinderMesh.new()
	core_cyl.top_radius = 0.9
	core_cyl.bottom_radius = 0.9
	core_cyl.height = 0.12
	_core_disc.mesh = core_cyl
	
	var mat_core = StandardMaterial3D.new()
	mat_core.albedo_color = Color(0.85, 1.0, 1.0)
	mat_core.emission_enabled = true
	mat_core.emission = Color(0.85, 1.0, 1.0)
	mat_core.emission_energy_multiplier = 5.0
	_core_disc.material_override = mat_core
	_core_disc.position.y = 0.06
	add_child(_core_disc)

	# 4. Giant Vertical Beacon Beam of Soul Light
	_beacon_beam = MeshInstance3D.new()
	var beam_cyl = CylinderMesh.new()
	beam_cyl.top_radius = 1.8
	beam_cyl.bottom_radius = 2.3
	beam_cyl.height = 6.0
	_beacon_beam.mesh = beam_cyl
	
	var mat_beam = StandardMaterial3D.new()
	mat_beam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_beam.albedo_color = Color(0.15, 0.88, 1.0, 0.32)
	mat_beam.emission_enabled = true
	mat_beam.emission = Color(0.2, 0.9, 1.0)
	mat_beam.emission_energy_multiplier = 2.4
	mat_beam.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beacon_beam.material_override = mat_beam
	_beacon_beam.position.y = 3.0
	add_child(_beacon_beam)

	# 5. Radiant Pulsing OmniLight3D
	_beacon_light = OmniLight3D.new()
	_beacon_light.light_color = Color(0.15, 0.95, 1.0)
	_beacon_light.light_energy = 4.5
	_beacon_light.omni_range = 12.0
	_beacon_light.position = Vector3(0, 1.5, 0)
	add_child(_beacon_light)

	# 6. Prominent Floating 3D Billboard Text
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.double_sided = true
	_label.font_size = 56
	_label.outline_size = 14
	_label.outline_modulate = Color(0.01, 0.03, 0.08, 1.0)
	_label.modulate = Color(0.35, 1.0, 0.95)
	_label.position.y = 3.0
	
	if GameManager.current_floor == 0:
		_label.text = "▼ STEP HERE TO DESCEND ▼\n[ ENTER OSSUARY — FLOOR 1 ]"
	elif GameManager.current_floor >= 4:
		_label.text = "▼ STEP HERE TO DESCEND ▼\n[ ENTER WARDEN'S LAIR — FLOOR 5 ]"
	else:
		_label.text = "▼ STEP HERE TO DESCEND ▼\n[ PROCEED TO FLOOR " + str(GameManager.current_floor + 1) + " ]"
		
	add_child(_label)

func _physics_process(delta: float) -> void:
	if _has_triggered:
		return
		
	_time += delta
	
	# Rotate Runic Rings
	if _inner_disc:
		_inner_disc.rotation.y += delta * 1.5
	if _outer_ring:
		_outer_ring.rotation.y -= delta * 0.7
		
	# Pulsing Light & Floating Text Bob
	if _beacon_light:
		_beacon_light.light_energy = 4.2 + sin(_time * 3.8) * 1.5
	if _label:
		_label.position.y = 3.0 + sin(_time * 3.5) * 0.18

	# Immediate step-on trigger: check overlapping player body every frame
	for b in get_overlapping_bodies():
		if (b.is_in_group("player") or b.name == "Player") and not _has_triggered:
			trigger_descent()
			return

func _on_body_entered(body: Node3D) -> void:
	if (body.is_in_group("player") or body.name == "Player") and not _has_triggered:
		trigger_descent()

func interact(_player: Node3D = null) -> void:
	if not _has_triggered:
		trigger_descent()

func trigger_descent() -> void:
	if _has_triggered:
		return
	_has_triggered = true
	
	# Visual & Audio burst
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.0, 0), Color(0.2, 1.0, 0.95))
	CombatJuice.add_trauma(0.25)
	AudioManager.play_sfx("descent_sigil", 0.05, 2.5)
	
	if GameManager.current_floor == 0:
		GameManager.start_new_run()
	else:
		GameManager.advance_chamber()
		
	# Rebuild floor room
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("load_current_floor_room"):
		main.load_current_floor_room()
