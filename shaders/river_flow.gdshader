shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.12, 0.48, 0.58, 0.88);
uniform vec4 deep_color : source_color = vec4(0.05, 0.22, 0.38, 0.95);
uniform vec4 foam_color : source_color = vec4(0.88, 0.94, 1.0, 0.45);
uniform float flow_speed : hint_range(0.1, 5.0) = 0.65;
uniform float wave_frequency : hint_range(0.5, 10.0) = 2.2;
uniform float wave_amplitude : hint_range(0.005, 0.2) = 0.025;

varying vec2 v_local_xz;

void vertex() {
	v_local_xz = VERTEX.xz;
	// Gentle undulating water waves
	float wave1 = sin(TIME * flow_speed * 2.0 + VERTEX.x * wave_frequency) * wave_amplitude;
	float wave2 = cos(TIME * flow_speed * 1.5 + VERTEX.z * wave_frequency * 1.5) * (wave_amplitude * 0.5);
	VERTEX.y += wave1 + wave2;
}

void fragment() {
	// World-scale UV scrolling current so ripples are crisp at any plane size
	vec2 flow_uv1 = v_local_xz * vec2(0.45, 0.55) + vec2(TIME * (flow_speed * 0.6), 0.0);
	vec2 flow_uv2 = v_local_xz * vec2(0.75, 0.85) + vec2(-TIME * (flow_speed * 0.45), TIME * 0.25);
	
	float ripple1 = sin(flow_uv1.x * 3.14 + cos(flow_uv1.y * 2.5));
	float ripple2 = cos(flow_uv2.x * 2.8 - sin(flow_uv2.y * 3.2));
	float ripple_norm = (ripple1 * 0.5 + ripple2 * 0.5) * 0.5 + 0.5;
	
	// Bank distance: 0 in center, 1 at banks
	float bank_dist = abs(UV.y - 0.5) * 2.0;
	vec3 water_col = mix(deep_color.rgb, shallow_color.rgb, pow(bank_dist, 1.6) * 0.65);
	
	// Subtle soft shoreline foam and wave crests
	float edge_foam = smoothstep(0.90, 0.99, bank_dist) * 0.40;
	float crest_foam = smoothstep(0.78, 0.95, ripple_norm) * 0.22;
	float total_foam = clamp(edge_foam + crest_foam, 0.0, 0.55);
	
	ALBEDO = mix(water_col, foam_color.rgb, total_foam);
	ROUGHNESS = mix(0.25, 0.50, total_foam);
	METALLIC = 0.05;
	SPECULAR = 0.35;
	ALPHA = mix(deep_color.a, 0.96, bank_dist * 0.3);
}
