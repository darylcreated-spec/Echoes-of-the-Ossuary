shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.10, 0.42, 0.48, 0.82);
uniform vec4 deep_color : source_color = vec4(0.04, 0.18, 0.32, 0.94);
uniform vec4 foam_color : source_color = vec4(0.85, 0.92, 0.98, 0.40);
uniform float flow_speed : hint_range(0.1, 5.0) = 0.55;
uniform float wave_frequency : hint_range(0.5, 10.0) = 2.4;
uniform float wave_amplitude : hint_range(0.005, 0.2) = 0.025;

void vertex() {
	// Gentle undulating river waves
	float wave1 = sin(TIME * flow_speed * 2.0 + VERTEX.x * wave_frequency) * wave_amplitude;
	float wave2 = cos(TIME * flow_speed * 1.5 + VERTEX.z * wave_frequency * 1.5) * (wave_amplitude * 0.5);
	VERTEX.y += wave1 + wave2;
}

void fragment() {
	// Multi-octave UV scrolling current along river
	vec2 flow_uv1 = UV * vec2(14.0, 1.0) + vec2(TIME * (flow_speed * 0.12), 0.0);
	vec2 flow_uv2 = UV * vec2(20.0, 1.5) + vec2(TIME * (flow_speed * 0.18), TIME * 0.03);
	
	float ripple1 = sin(flow_uv1.x * 6.28 + flow_uv1.y * 3.14);
	float ripple2 = cos(flow_uv2.x * 5.0 - flow_uv2.y * 4.0);
	float ripple_norm = (ripple1 * 0.5 + ripple2 * 0.5) * 0.5 + 0.5;
	
	// Bank distance: 0 in center, 1 at banks
	float bank_dist = abs(UV.y - 0.5) * 2.0;
	vec3 water_col = mix(deep_color.rgb, shallow_color.rgb, pow(bank_dist, 1.8) * 0.6);
	
	// Subtle soft shoreline foam (restricted to outer 6% of the riverbank)
	float edge_foam = smoothstep(0.92, 0.99, bank_dist) * 0.35;
	float crest_foam = smoothstep(0.82, 0.96, ripple_norm) * 0.15;
	float total_foam = clamp(edge_foam + crest_foam, 0.0, 0.5);
	
	ALBEDO = mix(water_col, foam_color.rgb, total_foam);
	ROUGHNESS = mix(0.08, 0.28, total_foam);
	METALLIC = 0.05;
	SPECULAR = 0.65;
	ALPHA = mix(deep_color.a, 0.95, bank_dist * 0.3);
}
