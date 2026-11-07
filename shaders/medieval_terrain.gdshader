shader_type spatial;
render_mode specular_schlick_ggx;

varying vec2 v_world_xz;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * value_noise(p);
		p = p * 2.03 + vec2(17.1, 31.7);
		a *= 0.5;
	}
	return v;
}

float dist_to_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

void vertex() {
	v_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 wp = v_world_xz;
	float n_macro = fbm(wp * 0.045);
	float n_mid   = fbm(wp * 0.22);
	float n_micro = value_noise(wp * 1.85);

	// 1. Base Lush Medieval Meadow Grass (Dappled emerald, clover & warm sunlit pasture)
	vec3 grass_dark  = vec3(0.14, 0.31, 0.12);
	vec3 grass_lush  = vec3(0.22, 0.43, 0.17);
	vec3 grass_warm  = vec3(0.32, 0.47, 0.20);
	vec3 col = mix(grass_dark, grass_lush, smoothstep(0.25, 0.75, n_macro));
	col = mix(col, grass_warm, smoothstep(0.45, 0.85, n_mid) * 0.55);
	col *= (0.88 + 0.24 * n_micro);
	float rough = 0.88;

	// 2. Whisperwood Forest Enclave (Sector B1 & NW B2: Mossy Woodland Floor)
	float forest_mask = smoothstep(-10.0, -28.0, wp.x) * smoothstep(-25.0, -52.0, wp.y);
	vec3 moss_col = mix(vec3(0.11, 0.26, 0.12), vec3(0.24, 0.34, 0.16), n_mid);
	col = mix(col, moss_col, forest_mask * 0.75);

	// 3. Khar-Drakken Highland Crags & Iron Mines (Sector D1: Slate Rock & Basalt Earth)
	float crag_mask = smoothstep(46.0, 68.0, wp.x) * smoothstep(-28.0, -48.0, wp.y);
	vec3 slate_col = mix(vec3(0.29, 0.28, 0.27), vec3(0.40, 0.37, 0.33), n_mid);
	slate_col = mix(slate_col, vec3(0.22, 0.20, 0.18), smoothstep(0.6, 0.85, n_micro));
	col = mix(col, slate_col, crag_mask * 0.82);
	rough = mix(rough, 0.78, crag_mask);

	// 4. Golden Ploughed Farmlands (Sunnydale in Sector B3 & Eastbrook in Sector D2)
	float sunnydale_crop = smoothstep(-46.0, -40.0, wp.x) * (1.0 - smoothstep(-22.0, -16.0, wp.x))
	                     * smoothstep(42.0, 48.0, wp.y) * (1.0 - smoothstep(88.0, 94.0, wp.y));
	float eastbrook_crop = smoothstep(76.0, 82.0, wp.x) * (1.0 - smoothstep(118.0, 124.0, wp.x))
	                     * smoothstep(-32.0, -26.0, wp.y) * (1.0 - smoothstep(6.0, 12.0, wp.y));
	float crop_mask = clamp(sunnydale_crop + eastbrook_crop, 0.0, 1.0);
	if (crop_mask > 0.01) {
		float furrow = sin(wp.x * 3.8 + n_mid * 1.2) * 0.5 + 0.5;
		vec3 soil_col = vec3(0.28, 0.21, 0.13);
		vec3 wheat_col = vec3(0.62, 0.50, 0.22);
		vec3 field_col = mix(soil_col, wheat_col, smoothstep(0.2, 0.8, furrow));
		col = mix(col, field_col, crop_mask * 0.78);
	}

	// 5. Weeping Fen & Southern Estuary Marsh (Sector D3 & D4: Peaty Bog & Sedge)
	float fen_mask = smoothstep(45.0, 62.0, wp.x) * smoothstep(38.0, 54.0, wp.y);
	vec3 bog_col = mix(vec3(0.12, 0.21, 0.13), vec3(0.24, 0.26, 0.16), n_mid);
	col = mix(col, bog_col, fen_mask * 0.80);
	rough = mix(rough, 0.62, fen_mask * 0.6);

	// 6. Sector C4 Siege Battlefield Earthworks (Trampled War-Scorched Loam)
	float siege_mask = smoothstep(-4.0, 10.0, wp.x) * (1.0 - smoothstep(62.0, 74.0, wp.x))
	                 * smoothstep(122.0, 134.0, wp.y) * (1.0 - smoothstep(186.0, 198.0, wp.y));
	vec3 siege_col = mix(vec3(0.26, 0.25, 0.18), vec3(0.35, 0.30, 0.21), n_mid);
	col = mix(col, siege_col, siege_mask * 0.72);

	// 7. Connected Realm Road & Cobblestone Highway Network
	float d_hwy = dist_to_segment(wp, vec2(0.0, -122.0), vec2(0.0, 128.0));
	d_hwy = min(d_hwy, dist_to_segment(wp, vec2(0.0, 128.0), vec2(35.0, 155.0)));
	d_hwy = min(d_hwy, dist_to_segment(wp, vec2(35.0, 155.0), vec2(35.0, 196.0)));
	d_hwy = min(d_hwy, dist_to_segment(wp, vec2(-22.0, -2.0), vec2(22.0, -2.0)));

	float d_country = dist_to_segment(wp, vec2(0.0, -18.0), vec2(-50.0, -20.0));
	d_country = min(d_country, dist_to_segment(wp, vec2(-50.0, -20.0), vec2(-48.0, -96.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-48.0, -96.0), vec2(0.0, -96.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(0.0, -96.0), vec2(84.0, -78.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(0.0, -18.0), vec2(56.0, -24.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(56.0, -24.0), vec2(84.0, -78.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(56.0, -24.0), vec2(106.0, -16.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-18.0, -18.0), vec2(-18.0, 36.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(0.0, 34.0), vec2(-18.0, 34.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-18.0, 34.0), vec2(-34.0, 64.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-34.0, 64.0), vec2(-52.0, 68.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-50.0, 96.0), vec2(-32.0, 144.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(-32.0, 144.0), vec2(35.0, 155.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(18.0, 65.0), vec2(66.0, 68.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(66.0, 68.0), vec2(96.0, 156.0)));
	d_country = min(d_country, dist_to_segment(wp, vec2(35.0, 155.0), vec2(96.0, 156.0)));

	// Render Country Dirt Roads (Packed earth with gravel edges)
	float dirt_shoulder = 1.0 - smoothstep(1.6, 3.0, d_country + (n_mid - 0.5) * 0.7);
	float dirt_core     = 1.0 - smoothstep(0.0, 1.8, d_country + (n_micro - 0.5) * 0.4);
	vec3 dirt_col = mix(vec3(0.36, 0.28, 0.19), vec3(0.46, 0.37, 0.26), n_micro);
	col = mix(col, dirt_col * 0.85, dirt_shoulder * 0.65);
	col = mix(col, dirt_col, dirt_core * 0.92);
	rough = mix(rough, 0.82, dirt_core);

	// Render Royal Cobblestone Highways (Ashlar cobbles + mortar lines)
	float hwy_shoulder = 1.0 - smoothstep(2.0, 3.4, d_hwy + (n_mid - 0.5) * 0.5);
	float hwy_core     = 1.0 - smoothstep(0.0, 2.2, d_hwy + (n_micro - 0.5) * 0.25);
	if (hwy_shoulder > 0.01) {
		vec2 cobble_uv = wp * 2.4;
		vec2 c_grid = abs(fract(cobble_uv) - 0.5);
		float mortar = smoothstep(0.40, 0.48, max(c_grid.x, c_grid.y));
		float stone_var = hash21(floor(cobble_uv));
		vec3 stone_col = mix(vec3(0.44, 0.43, 0.40), vec3(0.56, 0.54, 0.50), stone_var);
		stone_col = mix(stone_col, vec3(0.22, 0.21, 0.19), mortar * 0.75);
		col = mix(col, dirt_col, hwy_shoulder * 0.75);
		col = mix(col, stone_col, hwy_core * 0.95);
		rough = mix(rough, 0.72, hwy_core);
	}

	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = 0.02;
	SPECULAR = 0.22;
}
