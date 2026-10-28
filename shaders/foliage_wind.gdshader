shader_type spatial;
render_mode cull_disabled, diffuse_toon;

uniform float wind_speed : hint_range(0.5, 8.0) = 2.4;
uniform float wind_strength : hint_range(0.01, 0.5) = 0.08;
uniform float height_threshold : hint_range(0.0, 3.0) = 0.4;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_factor = max(0.0, VERTEX.y - height_threshold);
	
	// Two-frequency natural gust noise
	float gust = sin(TIME * wind_speed + world_pos.x * 0.65 + world_pos.z * 0.45);
	float micro_rustle = cos(TIME * wind_speed * 2.8 + world_pos.y * 1.8) * 0.35;
	
	VERTEX.x += (gust + micro_rustle) * wind_strength * height_factor;
	VERTEX.z += (gust * 0.6) * wind_strength * height_factor;
}

void fragment() {
	// Standard spatial fragment shading preserving mesh vertex colors
	ROUGHNESS = 0.85;
}
