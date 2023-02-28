#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

uniform float viewWidth;
uniform float viewHeight;

#ifdef FXAA_ENABLED
	#include "/lib/fxaa.glsl"
#endif


void main() {
	#ifdef FXAA_ENABLED
		vec3 color = FXAA(texcoord);
	#else
		vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
