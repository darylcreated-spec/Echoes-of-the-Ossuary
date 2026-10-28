shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base_tex = texture(texture_albedo, UV);
	vec3 base_color = albedo_color.rgb * base_tex.rgb;
	
	// Mix base color with flash color based on flash intensity
	ALBEDO = mix(base_color, flash_color.rgb, flash_intensity);
	EMISSION = flash_color.rgb * (flash_intensity * 0.8);
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
