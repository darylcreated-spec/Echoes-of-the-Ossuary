extends Node3D
class_name CampfireRestSite3D

@export var site_name: String = "Traveler's Campfire"
var hearth_name: String:
	get: return site_name
	set(v): site_name = v

var _light: OmniLight3D = null
var _flame_particles: CPUParticles3D = null
var _smoke_particles: CPUParticles3D = null
var _flicker_timer: float = 0.0

func _ready() -> void:
	add_to_group("campfire_site")
	add_to_group("interactable")
	_build_campfire_visuals()
	_setup_interaction_area()

func _build_campfire_visuals() -> void:
	# 1. Authentic Medieval Stone Ring Firepit using 3D Rock Models
	for i in range(8):
		var ang = float(i) * (TAU / 8.0)
		var rk_path = "res://assets/overworld/rock_single_A.gltf" if (i % 2 == 0) else "res://assets/overworld/rock_single_B.gltf"
		var stone = AssetLoader.load_or_generate_model(rk_path, "prop", "rock")
		stone.scale = Vector3(0.42, 0.35, 0.42)
		stone.position = Vector3(cos(ang) * 0.92, 0.0, sin(ang) * 0.92)
		stone.rotation_degrees.y = float(i * 45)
		add_child(stone)

	# 2. Charred firewood logs
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.22, 0.15, 0.10)
	wood_mat.roughness = 0.92
	for rot in [35.0, -35.0, 90.0]:
		var log_mesh = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.10
		cm.bottom_radius = 0.11
		cm.height = 1.15
		cm.material = wood_mat
		log_mesh.mesh = cm
		log_mesh.rotation_degrees = Vector3(25.0, rot, 0.0)
		log_mesh.position = Vector3(0.0, 0.22, 0.0)
		add_child(log_mesh)

	# 3. Flame Ember Particles & Textured Brazier Flame
	_flame_particles = CPUParticles3D.new()
	_flame_particles.position = Vector3(0.0, 0.35, 0.0)
	_flame_particles.amount = 24
	_flame_particles.lifetime = 0.75
	_flame_particles.preprocess = 0.5
	_flame_particles.direction = Vector3(0.0, 1.0, 0.0)
	_flame_particles.spread = 22.0
	_flame_particles.gravity = Vector3(0.0, 3.5, 0.0)
	_flame_particles.initial_velocity_min = 1.2
	_flame_particles.initial_velocity_max = 2.4
	
	var ember_mat = StandardMaterial3D.new()
	ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	ember_mat.albedo_color = Color(1.0, 0.58, 0.14, 0.9)
	var fire_tex = load("res://assets/particles/fire_01.png")
	if fire_tex:
		ember_mat.albedo_texture = fire_tex
	var ember_mesh = QuadMesh.new()
	ember_mesh.size = Vector2(0.85, 0.85)
	ember_mesh.material = ember_mat
	_flame_particles.mesh = ember_mesh
	add_child(_flame_particles)

	# 4. Cozy Campfire OmniLight
	_light = OmniLight3D.new()
	_light.position = Vector3(0.0, 0.85, 0.0)
	_light.light_color = Color(1.0, 0.65, 0.25)
	_light.light_energy = 2.2
	_light.omni_range = 8.5
	_light.shadow_enabled = true
	add_child(_light)

	# 5. Surrounding Carved Medieval Benches
	for z_side in [-2.2, 2.2]:
		var bench = AssetLoader.load_or_generate_model("res://assets/overworld/bench_decorated.gltf", "prop", "bench")
		if bench:
			bench.position = Vector3(0.0, 0.0, z_side)
			bench.scale = Vector3.ONE * 1.55
			bench.rotation_degrees.y = 0.0 if z_side < 0 else 180.0
			add_child(bench)

func _process(delta: float) -> void:
	if _light:
		_flicker_timer += delta * 14.0
		_light.light_energy = 2.2 + sin(_flicker_timer * 1.7) * 0.35 + sin(_flicker_timer * 3.1) * 0.2

func _setup_interaction_area() -> void:
	var area = Area3D.new()
	area.name = "CampfireInteractArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactable
	area.collision_mask = 0
	
	var cs = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.8
	cs.shape = sphere
	cs.position.y = 0.6
	area.add_child(cs)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Rest by the Hearth"

func interact(player: Node3D) -> void:
	if not player:
		return
		
	if player.has_method("heal"):
		player.heal(player.max_health)
	
	if "parry_window_timer" in player:
		player.parry_window_timer = 0.0
	if "_mount_cooldown" in player:
		player._mount_cooldown = 0.0

	CombatJuice.show_popup_text(
		player.global_position + Vector3(0, 2.2, 0),
		"🔥 The warmth of the hearth soothes your wounds! Vitality Restored!",
		Color(1.0, 0.85, 0.4)
	)
	
	AudioManager.play_sfx("level_up", 0.06, 1.25)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.8, 0), Color(1.0, 0.7, 0.2))
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🔥 Campfire Rest: Fully Restored Vitality & Cooldowns!")
