extends Node
class_name WeatherManager

# --- ENUMS ---
enum TimePeriod { DAWN, DAY, DUSK, NIGHT }
enum WeatherType { CLEAR, RAIN, COASTAL_MIST, BOG_MURK }

# --- SIGNALS ---
signal time_updated(hour: int, minute: int, time_string: String)
signal period_changed(period_name: String)
signal weather_changed(weather_name: String)

# --- TIME PARAMETERS ---
# 24-hour clock. 8.5 = 8:30 AM
var time_of_day: float = 8.5
# Duration in real seconds for a full 24-hour game day (720s = 12 minutes)
var day_duration_seconds: float = 720.0
var time_scale: float = 1.0
var is_time_paused: bool = false

var current_period: TimePeriod = TimePeriod.DAY
var current_weather: WeatherType = WeatherType.CLEAR
var current_biome: String = "Oakhaven Hub"

# --- SCENE REFERENCES ---
var sun_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null
var player_ref: Node3D = null

# --- PARTICLES & WEATHER FX ---
var rain_particles: GPUParticles3D = null
var rain_splash_particles: GPUParticles3D = null
var _thunder_timer: float = 0.0
var _lightning_light: DirectionalLight3D = null

# --- NOCTURNAL LIGHTS CACHE ---
var _nocturnal_lights: Array[OmniLight3D] = []
var _nocturnal_materials: Array[StandardMaterial3D] = []
var _firefly_emitters: Array[GPUParticles3D] = []

# --- COLOR PRESETS ---
# Procedural Sky: [SkyTop, SkyHorizon, GroundBottom, GroundHorizon]
const SKY_COLORS = {
	TimePeriod.DAWN: [
		Color(0.22, 0.28, 0.44), # Sky top
		Color(0.92, 0.58, 0.38), # Sky horizon (warm rose amber)
		Color(0.12, 0.16, 0.12), # Ground bottom
		Color(0.42, 0.32, 0.22)  # Ground horizon
	],
	TimePeriod.DAY: [
		Color(0.24, 0.46, 0.72), # Sky top (vibrant blue)
		Color(0.70, 0.82, 0.94), # Sky horizon
		Color(0.12, 0.18, 0.10), # Ground bottom
		Color(0.36, 0.48, 0.30)  # Ground horizon
	],
	TimePeriod.DUSK: [
		Color(0.18, 0.15, 0.34), # Sky top (indigo)
		Color(0.94, 0.42, 0.22), # Sky horizon (fiery crimson gold)
		Color(0.08, 0.08, 0.10), # Ground bottom
		Color(0.48, 0.24, 0.16)  # Ground horizon
	],
	TimePeriod.NIGHT: [
		Color(0.04, 0.06, 0.12), # Sky top (deep space obsidian)
		Color(0.08, 0.12, 0.22), # Sky horizon (moonlit navy)
		Color(0.02, 0.03, 0.05), # Ground bottom
		Color(0.06, 0.08, 0.14)  # Ground horizon
	]
}

const SUN_COLORS = {
	TimePeriod.DAWN: Color(1.0, 0.76, 0.52),
	TimePeriod.DAY: Color(1.0, 0.96, 0.90),
	TimePeriod.DUSK: Color(1.0, 0.52, 0.28),
	TimePeriod.NIGHT: Color(0.48, 0.65, 0.95) # Lunar silvery-blue
}

const SUN_ENERGIES = {
	TimePeriod.DAWN: 0.70,
	TimePeriod.DAY: 0.85,
	TimePeriod.DUSK: 0.65,
	TimePeriod.NIGHT: 0.22 # Soft moonlight
}

const AMBIENT_ENERGIES = {
	TimePeriod.DAWN: 0.50,
	TimePeriod.DAY: 0.55,
	TimePeriod.DUSK: 0.45,
	TimePeriod.NIGHT: 0.25
}

func _ready() -> void:
	add_to_group("weather_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Defer linking until Main tree is fully built
	call_deferred("_setup_environment_references")
	call_deferred("_setup_rain_system")
	call_deferred("_collect_nocturnal_elements")

func _setup_environment_references() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	
	sun_light = root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	world_env = root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	player_ref = get_tree().get_first_node_in_group("player") as Node3D
	
	if sun_light:
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = 0.03
	
	# Create lightning flash light
	if not _lightning_light and root:
		_lightning_light = DirectionalLight3D.new()
		_lightning_light.name = "LightningFlash"
		_lightning_light.light_color = Color(0.9, 0.95, 1.0)
		_lightning_light.light_energy = 0.0
		_lightning_light.visible = false
		root.add_child(_lightning_light)
		
	_apply_time_and_lighting(0.0)

func _setup_rain_system() -> void:
	# 1. Main falling rain particle cascade
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainCascade"
	rain_particles.amount = 550
	rain_particles.lifetime = 1.4
	rain_particles.explosiveness = 0.0
	rain_particles.randomness = 0.25
	rain_particles.visible = false
	
	var r_mat = ParticleProcessMaterial.new()
	r_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	r_mat.emission_box_extents = Vector3(26.0, 1.0, 26.0)
	r_mat.direction = Vector3(-0.15, -1.0, -0.05).normalized()
	r_mat.spread = 4.0
	r_mat.initial_velocity_min = 18.0
	r_mat.initial_velocity_max = 24.0
	r_mat.scale_min = 0.6
	r_mat.scale_max = 1.2
	r_mat.color = Color(0.75, 0.85, 0.95, 0.6)
	rain_particles.process_material = r_mat
	
	# Rain drop mesh: slender elongated capsule
	var drop_mesh = CylinderMesh.new()
	drop_mesh.top_radius = 0.015
	drop_mesh.bottom_radius = 0.015
	drop_mesh.height = 0.55
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	mat.roughness = 0.1
	drop_mesh.material = mat
	rain_particles.draw_pass_1 = drop_mesh
	
	add_child(rain_particles)

func _collect_nocturnal_elements() -> void:
	_nocturnal_lights.clear()
	_nocturnal_materials.clear()
	_firefly_emitters.clear()
	
	# Gather all street lantern lights and camp torches
	var nodes = get_tree().get_nodes_in_group("nocturnal_lights")
	for n in nodes:
		if n is OmniLight3D:
			_nocturnal_lights.append(n)
			
	# Also find all post lanterns placed across the overworld
	var all_lights = get_tree().root.find_children("*", "OmniLight3D", true, false)
	for l in all_lights:
		if l.name.begins_with("Lantern") or l.name == "TorchLight" or (l.get_parent() and "lantern" in l.get_parent().name.to_lower()):
			if not l in _nocturnal_lights:
				_nocturnal_lights.append(l)
				
	# Firefly particle emitters in biomes
	var all_gpu = get_tree().root.find_children("*", "GPUParticles3D", true, false)
	for p in all_gpu:
		if "firefl" in p.name.to_lower():
			_firefly_emitters.append(p)

func _process(delta: float) -> void:
	if not is_time_paused:
		# Advance time of day
		var hours_per_sec = 24.0 / max(day_duration_seconds, 1.0)
		time_of_day = fmod(time_of_day + delta * hours_per_sec * time_scale, 24.0)
		
	_apply_time_and_lighting(delta)
	_update_regional_biome_and_weather(delta)
	_update_weather_fx(delta)

func _apply_time_and_lighting(delta: float) -> void:
	# Calculate period
	var prev_period = current_period
	if time_of_day >= 5.0 and time_of_day < 7.5:
		current_period = TimePeriod.DAWN
	elif time_of_day >= 7.5 and time_of_day < 17.5:
		current_period = TimePeriod.DAY
	elif time_of_day >= 17.5 and time_of_day < 20.0:
		current_period = TimePeriod.DUSK
	else:
		current_period = TimePeriod.NIGHT
		
	if current_period != prev_period:
		var p_name = _get_period_name(current_period)
		period_changed.emit(p_name)
		
	# Emit time signal
	var hour_int = int(time_of_day)
	var min_int = int(fmod(time_of_day * 60.0, 60.0))
	var time_str = "%02d:%02d %s" % [
		(12 if hour_int % 12 == 0 else hour_int % 12),
		min_int,
		"PM" if hour_int >= 12 else "AM"
	]
	time_updated.emit(hour_int, min_int, time_str)
	
	# Orbit Sun / Moon
	# Full 360 degree rotation across 24h
	# 12:00 = peak elevation (sun highest)
	# 00:00 = lowest elevation (moon highest opposite)
	if sun_light:
		var sun_angle_deg = (time_of_day / 24.0) * 360.0 - 90.0 # 0 at 6AM sunrise, 90 at noon, 180 at 6PM sunset
		var elevation: float = sin(deg_to_rad(sun_angle_deg)) * 62.0
		var azimuth: float = cos(deg_to_rad(sun_angle_deg)) * 45.0 + 35.0
		
		# If at night, moon illuminates smoothly
		var is_night = (current_period == TimePeriod.NIGHT)
		var target_elev = elevation if not is_night else max(24.0, abs(elevation) * 0.7)
		var target_azim = azimuth if not is_night else azimuth + 180.0
		
		sun_light.rotation_degrees = Vector3(-target_elev, target_azim, 0.0)
		
		# Interpolate light color & energy
		var target_col: Color = SUN_COLORS[current_period]
		var target_energy: float = SUN_ENERGIES[current_period]
		
		# Modulate during rain
		if current_weather == WeatherType.RAIN:
			target_col = target_col.lerp(Color(0.65, 0.72, 0.8), 0.5)
			target_energy *= 0.65
			
		sun_light.light_color = sun_light.light_color.lerp(target_col, clamp(delta * 4.0, 0.05, 1.0))
		sun_light.light_energy = lerp(sun_light.light_energy, target_energy, clamp(delta * 4.0, 0.05, 1.0))

	# Update WorldEnvironment Sky and Ambient Lighting
	if world_env and world_env.environment:
		var env = world_env.environment
		var colors = SKY_COLORS[current_period]
		
		# Update Procedural Sky
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky = env.sky.sky_material as ProceduralSkyMaterial
			sky.sky_top_color = sky.sky_top_color.lerp(colors[0], clamp(delta * 2.5, 0.05, 1.0))
			sky.sky_horizon_color = sky.sky_horizon_color.lerp(colors[1], clamp(delta * 2.5, 0.05, 1.0))
			sky.ground_bottom_color = sky.ground_bottom_color.lerp(colors[2], clamp(delta * 2.5, 0.05, 1.0))
			sky.ground_horizon_color = sky.ground_horizon_color.lerp(colors[3], clamp(delta * 2.5, 0.05, 1.0))
			
		var amb_energy: float = AMBIENT_ENERGIES[current_period]
		if current_weather == WeatherType.RAIN:
			amb_energy *= 0.75
		env.ambient_light_energy = lerp(env.ambient_light_energy, amb_energy, clamp(delta * 2.5, 0.05, 1.0))
		
	# Update Nocturnal Street Lanterns & Torches
	_update_nocturnal_lighting(delta)

func _update_nocturnal_lighting(delta: float) -> void:
	var is_dark = (current_period == TimePeriod.DUSK or current_period == TimePeriod.NIGHT)
	var target_light_energy: float = 1.6 if is_dark else 0.0
	
	for light in _nocturnal_lights:
		if is_instance_valid(light):
			# Add subtle fire/oil flicker when active
			var flicker = 0.0
			if is_dark:
				var time = Time.get_ticks_msec() * 0.003 + light.get_instance_id() * 0.1
				flicker = sin(time * 8.0) * 0.15 + sin(time * 19.3) * 0.08
			light.light_energy = lerp(light.light_energy, target_light_energy + flicker, clamp(delta * 5.0, 0.05, 1.0))
			light.visible = (light.light_energy > 0.05)

	# Fireflies active at dusk and night
	for ff in _firefly_emitters:
		if is_instance_valid(ff):
			ff.emitting = is_dark

func _update_regional_biome_and_weather(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node3D
		if not player_ref:
			return
			
	var pos = player_ref.global_position
	var prev_biome = current_biome
	var prev_weather = current_weather
	
	# Determine biome based on player coordinates
	if pos.x < -60.0 and pos.z > 46.0:
		current_biome = "Port Blackwater"
		current_weather = WeatherType.COASTAL_MIST
	elif pos.x > 40.0 and pos.z > 40.0:
		current_biome = "Weeping Fen"
		current_weather = WeatherType.BOG_MURK
	elif pos.x > 45.0 and pos.z < -20.0:
		current_biome = "Khar-Drakken Crags"
		current_weather = WeatherType.CLEAR
	elif pos.x < -40.0 and pos.z < -20.0:
		current_biome = "Whisperwood Enclave"
		current_weather = WeatherType.CLEAR
	elif pos.x > 8.0 and pos.z > 5.0 and pos.z < 45.0:
		current_biome = "Sunnydale Farmlands"
		# Dynamic gentle rain in farmlands during specific time windows
		if fmod(time_of_day, 8.0) >= 6.0 and fmod(time_of_day, 8.0) <= 7.2:
			current_weather = WeatherType.RAIN
		else:
			current_weather = WeatherType.CLEAR
	else:
		current_biome = "Oakhaven Town"
		# Occasional rain shower in town
		if fmod(time_of_day, 12.0) >= 10.0 and fmod(time_of_day, 12.0) <= 11.2:
			current_weather = WeatherType.RAIN
		else:
			current_weather = WeatherType.CLEAR
			
	if current_weather != prev_weather:
		weather_changed.emit(_get_weather_name(current_weather))
		_on_weather_transition(current_weather)

func _on_weather_transition(new_weather: WeatherType) -> void:
	if not world_env or not world_env.environment:
		return
	var env = world_env.environment
	
	match new_weather:
		WeatherType.CLEAR:
			env.fog_enabled = false
			AudioManager.stop_weather_ambience(1.5)
			if rain_particles:
				rain_particles.visible = false
				
		WeatherType.RAIN:
			env.fog_enabled = true
			env.fog_light_color = Color(0.48, 0.55, 0.65)
			env.fog_density = 0.008
			if rain_particles:
				rain_particles.visible = true
			AudioManager.play_weather_ambience("rain_loop", -18.0, 1.2)
			
		WeatherType.COASTAL_MIST:
			env.fog_enabled = true
			env.fog_light_color = Color(0.62, 0.72, 0.82)
			env.fog_density = 0.009
			if rain_particles:
				rain_particles.visible = false
			AudioManager.play_weather_ambience("ocean_swell", -20.0, 1.5)
			
		WeatherType.BOG_MURK:
			env.fog_enabled = true
			env.fog_light_color = Color(0.18, 0.28, 0.16) # Murky peat moss green
			env.fog_density = 0.022
			if rain_particles:
				rain_particles.visible = false
			AudioManager.stop_weather_ambience(1.2)

func _update_weather_fx(delta: float) -> void:
	# Update rain emitter position to follow player/camera
	if rain_particles and rain_particles.visible and player_ref and is_instance_valid(player_ref):
		rain_particles.global_position = player_ref.global_position + Vector3(0, 14.0, 0)
		
		# Occasional rolling thunder & subtle lightning flash during rain
		_thunder_timer -= delta
		if _thunder_timer <= 0.0:
			_thunder_timer = randf_range(16.0, 32.0)
			_trigger_thunder_and_lightning()

func _trigger_thunder_and_lightning() -> void:
	AudioManager.play_sfx("thunder_rumble", 0.12, -8.0)
	if _lightning_light:
		_lightning_light.visible = true
		_lightning_light.light_energy = 3.5
		var tw = create_tween()
		tw.tween_property(_lightning_light, "light_energy", 0.0, 0.22)
		tw.chain().tween_callback(func(): _lightning_light.visible = false)

# --- PUBLIC HELPER METHODS ---

func advance_to_time(target_hour: float) -> void:
	time_of_day = fmod(target_hour, 24.0)
	_apply_time_and_lighting(0.0)

func cycle_time_preset() -> void:
	# Cycle between 08:30 (Morning) -> 13:00 (Noon) -> 18:30 (Dusk) -> 23:30 (Night)
	if time_of_day < 8.0 or time_of_day >= 22.0:
		advance_to_time(8.5)
	elif time_of_day >= 8.0 and time_of_day < 12.0:
		advance_to_time(13.0)
	elif time_of_day >= 12.0 and time_of_day < 18.0:
		advance_to_time(18.5)
	else:
		advance_to_time(23.0)

func force_weather(w_type: WeatherType) -> void:
	current_weather = w_type
	_on_weather_transition(w_type)
	weather_changed.emit(_get_weather_name(w_type))

func get_formatted_time() -> String:
	var hour_int = int(time_of_day)
	var min_int = int(fmod(time_of_day * 60.0, 60.0))
	return "%02d:%02d %s" % [
		(12 if hour_int % 12 == 0 else hour_int % 12),
		min_int,
		"PM" if hour_int >= 12 else "AM"
	]

func get_weather_display_string() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "☀️ Clear Skies" if current_period != TimePeriod.NIGHT else "🌙 Starry Night"
		WeatherType.RAIN:
			return "🌧️ Gentle Rain"
		WeatherType.COASTAL_MIST:
			return "🌫️ Sea Mist"
		WeatherType.BOG_MURK:
			return "🪰 Swamp Murk"
		_:
			return "Clear"

func _get_period_name(period: TimePeriod) -> String:
	match period:
		TimePeriod.DAWN: return "Dawn"
		TimePeriod.DAY: return "Day"
		TimePeriod.DUSK: return "Dusk"
		TimePeriod.NIGHT: return "Night"
		_: return "Day"

func _get_weather_name(w: WeatherType) -> String:
	match w:
		WeatherType.CLEAR: return "Clear"
		WeatherType.RAIN: return "Rain"
		WeatherType.COASTAL_MIST: return "Coastal Mist"
		WeatherType.BOG_MURK: return "Bog Murk"
		_: return "Clear"
