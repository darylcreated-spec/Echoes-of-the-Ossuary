extends Node3D
class_name AncientShrine3D

enum ShrineType {
	DAWN,   # Cathedral Cemetery: +20% Defense & Radiant Aura
	HUNT,   # Whisperwood Forest: +20% Movement Speed
	FORGE   # Khar-Drakken Crags: +25% Critical Hit Damage
}

@export var shrine_type: ShrineType = ShrineType.DAWN
@export var shrine_name: String = "Ancient Waystone Shrine"

var _aura_light: OmniLight3D = null
var _pulse_timer: float = 0.0

func _ready() -> void:
	add_to_group("ancient_shrine")
	add_to_group("interactable")
	_build_shrine_visuals()
	_setup_interaction_area()

func _build_shrine_visuals() -> void:
	# Primary Shrine Mesh
	var model_path = "res://assets/overworld/shrine.gltf"
	if ResourceLoader.exists(model_path):
		var scn = load(model_path)
		if scn:
			var inst = scn.instantiate()
			inst.scale = Vector3.ONE * 2.2
			add_child(inst)
			
	# Candles at base
	var candles_path = "res://assets/overworld/shrine_candles.gltf"
	if ResourceLoader.exists(candles_path):
		var scn_c = load(candles_path)
		if scn_c:
			var inst_c = scn_c.instantiate()
			inst_c.scale = Vector3.ONE * 2.2
			add_child(inst_c)

	# Ethereal Aura Light
	_aura_light = OmniLight3D.new()
	_aura_light.position = Vector3(0.0, 1.8, 0.0)
	_aura_light.omni_range = 7.5
	
	match shrine_type:
		ShrineType.DAWN:
			_aura_light.light_color = Color(1.0, 0.92, 0.55)
		ShrineType.HUNT:
			_aura_light.light_color = Color(0.35, 1.0, 0.65)
		ShrineType.FORGE:
			_aura_light.light_color = Color(1.0, 0.45, 0.20)
			
	_aura_light.light_energy = 2.0
	add_child(_aura_light)

	# Upward Rising Dust/Soul Motes
	var motes = CPUParticles3D.new()
	motes.position = Vector3(0.0, 0.5, 0.0)
	motes.amount = 16
	motes.lifetime = 1.4
	motes.direction = Vector3(0.0, 1.0, 0.0)
	motes.spread = 45.0
	motes.initial_velocity_min = 0.8
	motes.initial_velocity_max = 1.8
	motes.gravity = Vector3.ZERO
	
	var mote_mesh = BoxMesh.new()
	mote_mesh.size = Vector3(0.09, 0.09, 0.09)
	var mote_mat = StandardMaterial3D.new()
	mote_mat.albedo_color = _aura_light.light_color
	mote_mat.emission_enabled = true
	mote_mat.emission = _aura_light.light_color
	mote_mat.emission_energy_multiplier = 3.5
	mote_mesh.material = mote_mat
	motes.mesh = mote_mesh
	add_child(motes)

func _process(delta: float) -> void:
	if _aura_light:
		_pulse_timer += delta * 2.5
		_aura_light.light_energy = 2.0 + sin(_pulse_timer) * 0.45

func _setup_interaction_area() -> void:
	var area = Area3D.new()
	area.name = "ShrineInteractArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactable
	area.collision_mask = 0
	
	var cs = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.6
	cs.shape = sphere
	cs.position.y = 1.0
	area.add_child(cs)
	add_child(area)

func get_prompt_text() -> String:
	match shrine_type:
		ShrineType.DAWN:
			return "[E] Pray at the Altar of Dawn"
		ShrineType.HUNT:
			return "[E] Communion with the Wild Hunter"
		ShrineType.FORGE:
			return "[E] Touch the Sacred Runeforge Waystone"
	return "[E] Pray at Ancient Waystone"

func interact(player: Node3D) -> void:
	var buff_title = ""
	var desc = ""
	var col = Color.WHITE
	
	match shrine_type:
		ShrineType.DAWN:
			buff_title = "✨ Blessing of the Dawn"
			desc = "+20% Damage Resistance & Holy Ward!"
			col = Color(1.0, 0.90, 0.45)
			if player and "defense" in player:
				player.defense = max(player.defense, 12.0)
		ShrineType.HUNT:
			buff_title = "🍃 Blessing of the Wild Hunt"
			desc = "+25% Movement Speed & Agile Stride!"
			col = Color(0.4, 1.0, 0.6)
			if player and "move_speed" in player:
				player.move_speed = 7.5
		ShrineType.FORGE:
			buff_title = "⚒️ Blessing of the Molten Core"
			desc = "+25% Critical Strike Chance!"
			col = Color(1.0, 0.5, 0.2)
			if player and "crit_chance" in player:
				player.crit_chance = 0.45

	CombatJuice.show_popup_text(global_position + Vector3(0, 2.4, 0), buff_title, col)
	AudioManager.play_sfx("soul_pickup", 0.08, 1.2)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.5, 0), col)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("%s: %s" % [buff_title, desc])
