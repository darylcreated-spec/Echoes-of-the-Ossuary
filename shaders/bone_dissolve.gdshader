shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 albedo_color : source_color = vec4(0.85, 0.82, 0.75, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.06;
uniform vec4 edge_color : source_color = vec4(0.1, 0.9, 0.8, 1.0);
uniform float edge_emission_energy : hint_range(0.0, 10.0) = 4.0;
uniform float noise_scale : hint_range(1.0, 50.0) = 12.0;

// Simple procedural 3D noise function so no external texture is required
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 p = floor(x);
	vec3 w = fract(x);
	vec3 u = w * w * (3.0 - 2.0 * w);
	
	float n = mix(mix(mix(hash(p + vec3(0.0,0.0,0.0)), hash(p + vec3(1.0,0.0,0.0)), u.x),
	                  mix(hash(p + vec3(0.0,1.0,0.0)), hash(p + vec3(1.0,1.0,0.0)), u.x), u.y),
	              mix(mix(hash(p + vec3(0.0,0.0,1.0)), hash(p + vec3(1.0,0.0,1.0)), u.x),
	                  mix(hash(p + vec3(0.0,1.0,1.0)), hash(p + vec3(1.0,1.0,1.0)), u.x), u.y), u.z);
	return n;
}

varying vec3 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (dissolve_amount <= 0.001) {
		vec4 base_tex = texture(texture_albedo, UV);
		ALBEDO = albedo_color.rgb * base_tex.rgb;
		ROUGHNESS = 0.8;
		return;
	}
	
	float n = noise(world_vertex * noise_scale);
	// Adjust dissolve threshold
	float threshold = dissolve_amount;
	
	if (n < threshold) {
		discard;
	}
	
	vec4 base_tex = texture(texture_albedo, UV);
	vec3 base_color = albedo_color.rgb * base_tex.rgb;
	
	// Check if near the burning edge
	if (n < threshold + edge_width) {
		float edge_factor = 1.0 - ((n - threshold) / edge_width);
		ALBEDO = mix(base_color, edge_color.rgb, edge_factor);
		EMISSION = edge_color.rgb * edge_factor * edge_emission_energy;
	} else {
		ALBEDO = base_color;
		EMISSION = vec3(0.0);
	}
	
	ROUGHNESS = 0.8;
}
