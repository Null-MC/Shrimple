#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

uniform sampler2D gcolor;

//in vec2 texcoord;


void main() {
	vec3 color = texelFetch(gcolor, ivec2(gl_FragCoord.xy), 0).rgb;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
