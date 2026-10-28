shader_type spatial;
render_mode specular_toon;

uniform vec4 shallow_color : source_color = vec4(0.22, 0.58, 0.78, 0.90);
uniform vec4 deep_color : source_color = vec4(0.08, 0.28, 0.52, 0.95);
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 1.0);
uniform float flow_speed : hint_range(0.1, 5.0) = 0.85;
uniform float wave_frequency : hint_range(0.5, 10.0) = 3.5;
uniform float wave_amplitude : hint_range(0.01, 0.5) = 0.04;

void vertex() {
	// Subtle undulating river waves
	float wave1 = sin(TIME * flow_speed * 2.5 + VERTEX.x * wave_frequency) * wave_amplitude;
	float wave2 = cos(TIME * flow_speed * 1.8 + VERTEX.z * wave_frequency * 1.2) * (wave_amplitude * 0.6);
	VERTEX.y += wave1 + wave2;
}

void fragment() {
	// Multi-octave UV scrolling current along river
	vec2 flow_uv1 = UV + vec2(TIME * (flow_speed * 0.15), 0.0);
	vec2 flow_uv2 = UV + vec2(TIME * (flow_speed * 0.22), TIME * 0.04);
	
	float ripple = sin(flow_uv1.x * 28.0 + flow_uv1.y * 14.0) * cos(flow_uv2.x * 20.0 - flow_uv2.y * 18.0);
	float ripple_norm = ripple * 0.5 + 0.5;
	
	// Gradient from bank to deep channel
	float bank_dist = abs(UV.y - 0.5) * 2.0; // 0 in center, 1 at banks
	vec3 water_col = mix(deep_color.rgb, shallow_color.rgb, bank_dist * 0.7);
	
	// Riverbank foam crests
	float foam = smoothstep(0.72, 0.96, bank_dist) + (ripple_norm * 0.25 * step(0.65, bank_dist));
	foam = clamp(foam, 0.0, 1.0);
	
	ALBEDO = mix(water_col, foam_color.rgb, foam * 0.65);
	ROUGHNESS = mix(0.12, 0.45, foam);
	METALLIC = 0.2;
	SPECULAR = 0.75;
	ALPHA = mix(deep_color.a, 0.98, foam);
}
