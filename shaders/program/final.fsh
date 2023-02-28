#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

#ifdef FXAA_ENABLED
	uniform float viewWidth;
	uniform float viewHeight;

	#include "/lib/fxaa.glsl"
#endif


void main() {
	#if DEBUG_SHADOW_BUFFER == 1
		vec3 color = textureLod(shadowcolor0, texcoord, 0).rgb;
	#elif DEBUG_SHADOW_BUFFER == 2
		vec3 color = textureLod(shadowtex0, texcoord, 0).rrr;
	#elif DEBUG_SHADOW_BUFFER == 3
		vec3 color = textureLod(shadowtex1, texcoord, 0).rrr;
	#else
		#ifdef FXAA_ENABLED
			vec3 color = FXAA(texcoord);
		#else
			vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
		#endif
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
