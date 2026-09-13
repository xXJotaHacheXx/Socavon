shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

uniform float rejilla : hint_range(8.0, 256.0) = 80.0;
uniform sampler2D textura : source_color, hint_default_white, filter_nearest, repeat_enable;
uniform vec4 tinte : source_color = vec4(1.0);

varying vec2 uv_pasada;
varying float w_pasada;


void vertex() {
	vec4 pos_vista = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 pos_clip = PROJECTION_MATRIX * pos_vista;

	float w = max(abs(pos_clip.w), 0.0001);
	pos_clip.xy = round(pos_clip.xy / w * rejilla) / rejilla * w;
	POSITION = pos_clip;

	w_pasada = w;
	uv_pasada = UV * w;
}


void fragment() {
	vec2 uv = uv_pasada / w_pasada;
	ALBEDO = texture(textura, uv).rgb * tinte.rgb;
}