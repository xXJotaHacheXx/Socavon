shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

uniform float rejilla : hint_range(8.0, 256.0) = 80.0;
uniform float escala : hint_range(0.1, 2.0) = 0.5;
uniform sampler2D textura_pared : source_color, hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform sampler2D textura_piso : source_color, hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform sampler2D textura_techo : source_color, hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform vec4 tinte : source_color = vec4(1.0);

varying vec3 pos_mundo;
varying vec3 normal_mundo;


void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;

	vec4 pos_clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	float w = max(abs(pos_clip.w), 0.0001);
	pos_clip.xy = round(pos_clip.xy / w * rejilla) / rejilla * w;
	POSITION = pos_clip;
}


void fragment() {
	vec3 p = pos_mundo * escala;
	vec3 n = normalize(normal_mundo);
	vec3 a = abs(n);

	vec3 color;
	if (a.y > 0.5) {
		color = n.y > 0.0 ? texture(textura_piso, p.xz).rgb
						  : texture(textura_techo, p.xz).rgb;
	} else if (a.x > a.z) {
		color = texture(textura_pared, vec2(p.z, -p.y)).rgb;
	} else {
		color = texture(textura_pared, vec2(p.x, -p.y)).rgb;
	}

	ALBEDO = color * tinte.rgb;
}