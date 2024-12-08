#define RENDER_DEBUG
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

// uniform sampler2D colortex0;

#if WATER_DEPTH_LAYERS > 1 && defined WATER_MULTIDEPTH_DEBUG
	uniform sampler2D depthtex0;
#endif

#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
	uniform sampler2D BUFFER_DEFERRED_COLOR;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL_GEO
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING2
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_WATER_SHADOW
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL_TEX
	uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_ROUGH_METAL
	uniform usampler2D BUFFER_DEFERRED_DATA;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL_SCATTER
	uniform sampler2D BUFFER_VL_SCATTER;
#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL_TRANSMIT
	uniform sampler2D BUFFER_VL_TRANSMIT;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOCK_DIFFUSE
    uniform sampler2D texDiffuseRT;

    #ifdef LIGHTING_TRACED_ACCUMULATE
	    uniform sampler2D texDiffuseRT_alt;
	#endif
#elif DEBUG_VIEW == DEBUG_VIEW_BLOCK_SPECULAR
	uniform sampler2D BUFFER_BLOCK_SPECULAR;
#elif DEBUG_VIEW == DEBUG_VIEW_SHADOWS
	#ifdef DEBUG_TRANSPARENT
		uniform sampler2D BUFFER_DEFERRED_SHADOW;
	#else
		uniform sampler2D texShadowSSS;
	#endif
#elif DEBUG_VIEW == DEBUG_VIEW_SSS
	#ifdef DEBUG_TRANSPARENT
		uniform sampler2D BUFFER_DEFERRED_SHADOW;
	#else
		uniform sampler2D texShadowSSS;
	#endif
#elif DEBUG_VIEW == DEBUG_VIEW_SSAO
	uniform sampler2D texSSAO;
#elif DEBUG_VIEW == DEBUG_VIEW_VELOCITY
	uniform sampler2D BUFFER_VELOCITY;
#elif DEBUG_VIEW == DEBUG_VIEW_SHADOW_MAP
	uniform sampler2D shadowcolor0;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOOM_TILES
	uniform sampler2D BUFFER_BLOOM_TILES;
#elif DEBUG_VIEW == DEBUG_VIEW_DEPTH_TILES
	uniform sampler2D texDepthNear;
#elif DEBUG_VIEW == DEBUG_VIEW_SKY_IRRADIANCE
	uniform sampler2D texSky;
	uniform sampler2D texSkyIrradiance;
#endif

uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;
uniform float farPlane;
uniform float near;
uniform float far;

#if WATER_DEPTH_LAYERS > 1 && defined WATER_MULTIDEPTH_DEBUG
	uniform mat4 gbufferProjectionInverse;
	uniform int isEyeInWater;
#endif

#ifdef DISTANT_HORIZONS
	uniform float dhFarPlane;
#endif

#include "/lib/utility/text.glsl"

#if DEBUG_VIEW == DEBUG_VIEW_DEPTH_TILES
	#include "/lib/sampling/depth.glsl"
#endif

#ifdef IRIS_FEATURE_SSBO
	#if LIGHTING_MODE != LIGHTING_MODE_NONE && defined DYN_LIGHT_DEBUG_COUNTS
		#include "/lib/buffers/light_voxel.glsl"
	#endif

    #if WATER_DEPTH_LAYERS > 1 && defined WATER_MULTIDEPTH_DEBUG
        #include "/lib/buffers/water_depths.glsl"
        #include "/lib/water/water_depths_read.glsl"
    #endif
#endif


void main() {
	//vec2 viewSize = vec2(viewWidth, viewHeight);

	ivec2 uv = ivec2(texcoord * viewSize);

	#if DEBUG_VIEW == DEBUG_VIEW_DEFERRED_COLOR
		vec3 color = texelFetch(BUFFER_DEFERRED_COLOR, uv, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL_GEO
		uint deferredDataR = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).r;
		vec3 color = unpackUnorm4x8(deferredDataR).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING
		uint deferredDataG = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).g;
		vec3 color = vec3(unpackUnorm4x8(deferredDataG).rg, 0.0);
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_LIGHTING2
		uint deferredDataG = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).g;
		vec3 color = vec3(unpackUnorm4x8(deferredDataG).ba, 0.0);
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_WATER_SHADOW
		uint deferredDataB = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).b;
		vec3 color = unpackUnorm4x8(deferredDataB).rgb;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_NORMAL_TEX
        vec3 color = textureLod(BUFFER_DEFERRED_NORMAL_TEX, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_ROUGH_METAL
		uint deferredDataA = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).a;
		vec3 color = unpackUnorm4x8(deferredDataA).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL_SCATTER
		vec3 color = textureLod(BUFFER_VL_SCATTER, texcoord, 0).rgb;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_DEFERRED_VL_TRANSMIT
		vec3 color = textureLod(BUFFER_VL_TRANSMIT, texcoord, 0).rgb;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_BLOCK_DIFFUSE
        #ifdef HAS_LIGHTING_TRACED_SOFTSHADOWS
            bool altFrame = (frameCounter % 2) == 0;
            vec3 color = texelFetch(altFrame ? texDiffuseRT_alt : texDiffuseRT, uv, 0).rgb;
        #else
			vec3 color = texelFetch(texDiffuseRT, uv, 0).rgb;
        #endif
	#elif DEBUG_VIEW == DEBUG_VIEW_BLOCK_SPECULAR
		vec3 color = textureLod(BUFFER_BLOCK_SPECULAR, texcoord, 0).rgb;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_SHADOWS
		#ifdef DEBUG_TRANSPARENT
			vec3 color = texelFetch(BUFFER_DEFERRED_SHADOW, ivec2(texcoord * viewSize), 0).rgb;
		#else
			vec3 color = texelFetch(texShadowSSS, ivec2(texcoord * viewSize), 0).rgb;
		#endif
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_SSS
		#ifdef DEBUG_TRANSPARENT
			vec3 color = texelFetch(BUFFER_DEFERRED_SHADOW, ivec2(texcoord * viewSize), 0).aaa;
		#else
			vec3 color = texelFetch(texShadowSSS, ivec2(texcoord * viewSize), 0).aaa;
		#endif
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_SSAO
		vec3 color = textureLod(texSSAO, texcoord, 0).rrr;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_VELOCITY
		vec4 velocity = textureLod(BUFFER_VELOCITY, texcoord, 0);
		vec3 color = (velocity.xyz * 100.0 + 0.5) * (1.0 - velocity.w);
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_SHADOW_MAP
		vec3 color = textureLod(shadowcolor0, texcoord, 0).rgb;
	#elif DEBUG_VIEW == DEBUG_VIEW_BLOOM_TILES
		vec3 color = textureLod(BUFFER_BLOOM_TILES, texcoord, 0).rgb;
		color /= color + 1.0;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_DEPTH_TILES
		vec3 color = vec3(0.0);
		if (texcoord.x < 0.5 && texcoord.y < 0.75)
			color = texelFetch(texDepthNear, ivec2(gl_FragCoord.xy), 0).rrr;
		color = LinearToRGB(color);
	#elif DEBUG_VIEW == DEBUG_VIEW_SKY_IRRADIANCE
		vec3 color = textureLod(texSkyIrradiance, texcoord * vec2(1.0, -1.0) + vec2(0.0, 1.0), 0).rgb;
		// color = color / (color + 1.0);
		color = LinearToRGB(color);
	#endif

	#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE && defined DYN_LIGHT_DEBUG_COUNTS
		beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewHeight/2 - 24));

		text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
		text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);

		printString((_V, _i, _s, _i, _b, _l, _e, _colon, _space));
		printUnsignedInt(SceneLightCount);
		printLine();

		printString((_T, _o, _t, _a, _l, _colon, _space, _space, _space));
		printUnsignedInt(SceneLightMaxCount);
		printLine();

		printString((_S, _S, _B, _O, _colon, _space, _space, _space, _space));
		printUnsignedInt(DYN_LIGHT_SSBO_SIZE);
		printString((_m, _b));
		printLine();

		printString((_L, _i, _g, _h, _t, _colon, _space, _space, _space));
		printUnsignedInt(DYN_LIGHT_IMG_SIZE);
		printString((_x));
		printLine();

		printString((_B, _l, _o, _c, _k, _colon, _space, _space, _space));
		printUnsignedInt(DYN_LIGHT_BLOCK_IMG_SIZE);
		printString((_x));

		endText(color);
	#endif

	#if WATER_DEPTH_LAYERS > 1 && defined WATER_MULTIDEPTH_DEBUG
		beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewHeight/2 - 24));

		text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
		text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
		text.fpPrecision = 4;

		ivec2 center = ivec2(viewSize * 0.5);
        uint waterUV = uint(center.y * viewSize.x + center.x);

		// printString((_C, _o, _u, _n, _t, _colon, _space));
		// printUnsignedInt(WaterDepths[waterUV].Count);
		// printLine();

		const uint charIndices[7] = uint[](_0, _1, _2, _3, _4, _5, _6);

        float waterDepth[WATER_DEPTH_LAYERS+1];
		GetAllWaterDepths(waterUV, waterDepth);

		for (int i = 0; i <= WATER_DEPTH_LAYERS; i++) {
			printString((_D, _i, _s, _t, _space, charIndices[i], _colon, _space));
			printFloat(waterDepth[i]);
			printLine();
		}

		endText(color);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
