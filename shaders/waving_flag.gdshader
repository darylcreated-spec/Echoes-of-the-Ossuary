shader_type spatial;
render_mode cull_disabled, diffuse_toon;

uniform vec3 wind_direction = vec3(1.0, 0.0, 0.2);
uniform float wave_speed : hint_range(1.0, 10.0) = 4.2;
uniform float wave_frequency : hint_range(1.0, 12.0) = 4.5;
uniform float wave_amplitude : hint_range(0.02, 0.4) = 0.12;

void vertex() {
	// Pinned at UV.x near 0 (flagpole), ripple intensifies outward
	float pin = smoothstep(0.05, 0.45, UV.x);
	float wave1 = sin(TIME * wave_speed + (VERTEX.x + VERTEX.z) * wave_frequency);
	float wave2 = cos(TIME * wave_speed * 1.6 + VERTEX.y * 3.5) * 0.4;
	VERTEX += wind_direction * (wave1 + wave2) * wave_amplitude * pin;
}

void fragment() {
	ROUGHNESS = 0.8;
}
