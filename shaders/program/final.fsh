#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

#if DEBUG_BUFFER == 4
	uniform sampler2D colortex5;
#endif

#ifdef FXAA_ENABLED
	uniform float viewWidth;
	uniform float viewHeight;
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_DEBUG_COUNTS
	#include "/lib/buffers/lighting.glsl"
	#include "/lib/text.glsl"
#endif

#ifdef FXAA_ENABLED
	#include "/lib/fxaa.glsl"
#endif


void main() {
	#if DEBUG_BUFFER == 1
		vec3 color = textureLod(shadowcolor0, texcoord, 0).rgb;
	#elif DEBUG_BUFFER == 2
		vec3 color = textureLod(shadowtex0, texcoord, 0).rrr;
	#elif DEBUG_BUFFER == 3
		vec3 color = textureLod(shadowtex1, texcoord, 0).rrr;
	#elif DEBUG_BUFFER == 4
		vec3 color = textureLod(colortex5, texcoord, 0).rgb;
	#else
		#ifdef FXAA_ENABLED
			vec3 color = FXAA(texcoord);
		#else
			vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
		#endif
	#endif

	#if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_DEBUG_COUNTS
		beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewHeight/2 - 16));

		text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
		text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
		printString((_T, _o, _t, _a, _l, _colon, _space));
		printUnsignedInt(SceneLightCount);
		//printNewLine();

		endText(color);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
