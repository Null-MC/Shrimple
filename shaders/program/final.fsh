#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
	uniform sampler2D BUFFER_DEFERRED_COLOR;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL
	uniform sampler2D BUFFER_DEFERRED_NORMAL;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
	uniform sampler2D BUFFER_DEFERRED_LIGHTING;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_FOG
	uniform sampler2D BUFFER_DEFERRED_FOG;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_BLOCKLIGHT
	uniform sampler2D BUFFER_BLOCKLIGHT;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_SHADOW
	uniform sampler2D BUFFER_DEFERRED_SHADOW;
#elif DEBUG_VIEW == DEBUG_VIEW_SHADOW_COLOR
	uniform sampler2D shadowcolor0;
#endif

#ifdef FXAA_ENABLED
	uniform float viewWidth;
	uniform float viewHeight;
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_DEBUG_COUNTS
	#include "/lib/buffers/lighting.glsl"
	#include "/lib/text.glsl"
#endif

#ifdef FXAA_ENABLED
	#include "/lib/post/fxaa.glsl"
#endif


void main() {
	#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
		vec3 color = textureLod(BUFFER_DEFERRED_COLOR, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL
		vec3 color = textureLod(BUFFER_DEFERRED_NORMAL, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
		vec3 color = textureLod(BUFFER_DEFERRED_LIGHTING, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_FOG
		vec3 color = textureLod(BUFFER_DEFERRED_FOG, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_BLOCKLIGHT
		vec3 color = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_SHADOW
		vec3 color = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_SHADOW_COLOR
		vec3 color = textureLod(shadowcolor0, texcoord, 0).rgb;
	#else
		#ifdef FXAA_ENABLED
			vec3 color = FXAA(texcoord);
		#else
			vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
		#endif
	#endif

	#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_DEBUG_COUNTS
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
