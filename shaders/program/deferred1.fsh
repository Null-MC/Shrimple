#define RENDER_DEFERRED_RT_LIGHT
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_BLOCKLIGHT;
uniform sampler2D BUFFER_LIGHT_NORMAL;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D TEX_LIGHTMAP;

#if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
    uniform sampler2D shadowcolor0;
#endif

uniform float frameTime;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform bool firstPersonCamera;
uniform vec3 eyePosition;

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 3,4,5 */
layout(location = 0) out vec4 outLight;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outDepth;

void main() {
	vec2 viewSize = vec2(viewWidth, viewHeight);
	//vec2 bufferSize = viewSize / exp2(DYN_LIGHT_RES);
	const int resScale = int(exp2(DYN_LIGHT_RES));

	//ivec2 offset;
	vec2 pixelSize = rcp(viewSize);
	//offset.x += (int(gl_FragCoord.x)) % 2;
	//offset.y += (int(gl_FragCoord.y) /2) % 2;

	vec2 tex2 = texcoord;// - 0.5 * resScale * pixelSize;

	float depth = textureLod(depthtex0, tex2, 0).r;
	outDepth = vec4(vec3(depth), 1.0);

	if (depth < 1.0) {
		#if DYN_LIGHT_RES == 0
			ivec2 deferredTexcoord = ivec2(tex2 * viewSize);
	        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, deferredTexcoord, 0);
			vec3 localNormal = unpackUnorm4x8(deferredData.r).rgb;
			vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
		#else
			ivec2 deferredTexcoord = ivec2(tex2 * viewSize - 0.5) - resScale/2;
	        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, deferredTexcoord, 0);
	        uvec4 deferredData2 = texelFetchOffset(BUFFER_DEFERRED_DATA, deferredTexcoord, 0, ivec2(resScale, 0));
	        uvec4 deferredData3 = texelFetchOffset(BUFFER_DEFERRED_DATA, deferredTexcoord, 0, ivec2(0, resScale));
	        uvec4 deferredData4 = texelFetchOffset(BUFFER_DEFERRED_DATA, deferredTexcoord, 0, ivec2(resScale, resScale));

			vec3 localNormal = unpackUnorm4x8(deferredData.r).rgb;
			vec3 localNormal2 = unpackUnorm4x8(deferredData2.r).rgb;
			vec3 localNormal3 = unpackUnorm4x8(deferredData3.r).rgb;
			vec3 localNormal4 = unpackUnorm4x8(deferredData4.r).rgb;

			vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
			vec4 deferredLighting2 = unpackUnorm4x8(deferredData2.g);
			vec4 deferredLighting3 = unpackUnorm4x8(deferredData3.g);
			vec4 deferredLighting4 = unpackUnorm4x8(deferredData4.g);

			vec2 pf = fract(tex2 * (viewSize / resScale));

			vec4 deferredLightingX1 = mix(deferredLighting, deferredLighting2, pf.x);
			vec4 deferredLightingX2 = mix(deferredLighting3, deferredLighting4, pf.x);
			deferredLighting = mix(deferredLightingX1, deferredLightingX2, pf.y);
			
			vec3 localNormalX1 = mix(localNormal, localNormal2, pf.x);
			vec3 localNormalX2 = mix(localNormal3, localNormal4, pf.x);
			localNormal = mix(localNormalX1, localNormalX2, pf.y);
		#endif

		localNormal = normalize(localNormal * 2.0 - 1.0);

		vec4 deferredFog = unpackUnorm4x8(deferredData.a);

		vec3 clipPos = vec3(tex2, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

		vec3 blockLight;
		vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;
		vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
		vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));

		blockLight = GetFinalBlockLighting(localPos, localNormal, deferredLighting.x);
        blockLight += SampleHandLight(localPos, localNormal);
		blockLight += deferredLighting.a;

        blockLight *= 1.0 - deferredFog.a;

		#if DYN_LIGHT_PENUMBRA > 0
			vec3 uvPrev = clipPosPrev * 0.5 + 0.5;
			if (all(greaterThanEqual(uvPrev.xy, vec2(0.0))) && all(lessThan(uvPrev.xy, vec2(1.0)))) {
				vec3 normalPrev = textureLod(BUFFER_LIGHT_NORMAL, uvPrev.xy, 0).rgb;
				float depthPrev = textureLod(BUFFER_LIGHT_DEPTH, uvPrev.xy, 0).r;

				normalPrev = normalize(normalPrev * 2.0 - 1.0);
	            float normalWeight = 1.0 - dot(localNormal, normalPrev);

	            float depthLinear = linearizeDepthFast(uvPrev.z, near, far);
	            float depthPrevLinear = linearizeDepthFast(depthPrev, near, far);

				if (abs(depthLinear - depthPrevLinear) < 0.06 && normalWeight < 0.1) {
					//float time = exp(-6.0 * frameTime);

					vec3 blockLightPrev = textureLod(BUFFER_BLOCKLIGHT, uvPrev.xy, 0).rgb;
					//float weight = 0.02;

					float lum = luminance(blockLight);
					float lumPrev = luminance(blockLightPrev);
					//float lumDiff = lum - lumPrev;
					//if (lumDiff >  0.2) weight = 0.3;
					//if (lumDiff < -0.1) weight = 0.2;

					float weight = smoothstep(abs(lum - lumPrev), 0.0, 0.08) * 0.3 + 0.04;

					blockLight = mix(blockLight, blockLightPrev, 1.0 - weight);
				}
			}
		#endif

		outLight = vec4(blockLight, 1.0);
		outNormal = vec4(localNormal * 0.5 + 0.5, 1.0);
	}
	else {
		outLight = vec4(0.0, 0.0, 0.0, 1.0);
		outNormal = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
