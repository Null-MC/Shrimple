#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

uniform float viewWidth;
uniform float viewHeight;

#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
	uniform sampler2D BUFFER_DEFERRED_COLOR;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_SHADOW
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_FOG
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_TEXTURE
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL
	uniform sampler2D BUFFER_VL;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOCKLIGHT
	uniform sampler2D BUFFER_BLOCKLIGHT;
#elif DEBUG_VIEW == DEBUG_VIEW_SHADOW_COLOR
	uniform sampler2D shadowcolor0;
#endif

#include "/lib/sampling/bayer.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_DEBUG_COUNTS
	#include "/lib/buffers/lighting.glsl"
	#include "/lib/text.glsl"
#endif

#ifdef FXAA_ENABLED
	#include "/lib/post/fxaa.glsl"
#endif


void main() {
	vec2 viewSize = vec2(viewWidth, viewHeight);

	#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
		vec3 color = texelFetch(BUFFER_DEFERRED_COLOR, ivec2(texcoord * viewSize), 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL
		uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(texcoord * viewSize), 0);
		vec3 color = unpackUnorm4x8(deferredData.r).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
		uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(texcoord * viewSize), 0);
		vec3 color = unpackUnorm4x8(deferredData.g).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_SHADOW
		uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(texcoord * viewSize), 0);
		vec3 color = unpackUnorm4x8(deferredData.b).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_FOG
		uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(texcoord * viewSize), 0);
		vec4 fog = unpackUnorm4x8(deferredData.a);
		vec3 color = fog.rgb * fog.a;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_TEXTURE
		uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(texcoord * viewSize), 0);
		vec3 color = unpackUnorm4x8(deferredData.a).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL
		vec3 color = textureLod(BUFFER_VL, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_BLOCKLIGHT
		vec3 color = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
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
		printString((_V, _i, _s, _i, _b, _l, _e, _colon, _space));
		printUnsignedInt(SceneLightCount);
		printLine();
		printString((_T, _o, _t, _a, _l, _colon, _space, _space, _space));
		printUnsignedInt(SceneLightMaxCount);
		printLine();
		printString((_B, _u, _f, _f, _e, _r, _colon, _space, _space));
		printUnsignedInt(DYN_LIGHT_IMG_SIZE);

		endText(color);
	#endif

    //color.rgb += (GetScreenBayerValue() * 2.0 - 1.0) / 255.0;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
