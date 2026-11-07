shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.11, 0.44, 0.56, 0.90);
uniform vec4 deep_color : source_color = vec4(0.04, 0.19, 0.36, 0.96);
uniform vec4 foam_color : source_color = vec4(0.86, 0.94, 1.0, 0.50);
uniform float flow_speed : hint_range(0.1, 5.0) = 0.65;
uniform float wave_frequency : hint_range(0.5, 10.0) = 2.0;
uniform float wave_amplitude : hint_range(0.005, 0.2) = 0.025;

varying vec2 v_world_xz;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float water_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void vertex() {
	v_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float wave1 = sin(TIME * flow_speed * 2.0 + VERTEX.x * wave_frequency + VERTEX.z * 0.7) * wave_amplitude;
	float wave2 = cos(TIME * flow_speed * 1.5 - VERTEX.z * wave_frequency * 1.3 + VERTEX.x * 0.5) * (wave_amplitude * 0.55);
	VERTEX.y += wave1 + wave2;
}

void fragment() {
	vec2 uv1 = v_world_xz * 0.16 + vec2(TIME * flow_speed * 0.35, TIME * 0.18);
	vec2 uv2 = v_world_xz * 0.31 + vec2(-TIME * flow_speed * 0.25, -TIME * 0.22);
	vec2 uv3 = v_world_xz * 0.68 + vec2(TIME * 0.15, -TIME * 0.28);

	float n1 = water_noise(uv1);
	float n2 = water_noise(uv2 * 1.4 + vec2(n1 * 0.8));
	float n3 = water_noise(uv3);
	float swell = (n1 * 0.45 + n2 * 0.35 + n3 * 0.20);

	float bank_dist = max(abs(UV.y - 0.5) * 2.0, smoothstep(0.35, 0.50, UV.x));
	vec3 water_col = mix(deep_color.rgb, shallow_color.rgb, clamp(pow(bank_dist, 1.5) * 0.65 + swell * 0.35, 0.0, 1.0));

	float edge_foam = smoothstep(0.88, 0.99, bank_dist) * 0.45;
	float crest_foam = smoothstep(0.68, 0.84, swell) * 0.28;
	float total_foam = clamp(edge_foam + crest_foam, 0.0, 0.60);

	ALBEDO = mix(water_col, foam_color.rgb, total_foam);
	ROUGHNESS = mix(0.18, 0.48, total_foam);
	METALLIC = 0.06;
	SPECULAR = 0.45;
	ALPHA = mix(deep_color.a, 0.96, bank_dist * 0.3);
}
