#define RENDER_DEFERRED_RT_LIGHT
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform usampler2D BUFFER_DEFERRED_PRE;
uniform usampler2D BUFFER_DEFERRED_POST;
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

	float depth = textureLod(depthtex0, texcoord, 0).r;
	outDepth = vec4(vec3(depth), 1.0);

	if (depth < 1.0) {
		ivec2 deferredTexcoord = ivec2(texcoord * viewSize);
		uvec2 deferredPreGB = texelFetch(BUFFER_DEFERRED_PRE, deferredTexcoord, 0).gb;
        uint deferredPostG = texelFetch(BUFFER_DEFERRED_POST, deferredTexcoord, 0).g;
		vec3 localNormal = unpackUnorm4x8(deferredPreGB.r).rgb;
		vec4 deferredLighting = unpackUnorm4x8(deferredPreGB.g);

		vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

		vec3 blockLight;
		vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;
		vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
		vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));

		localNormal = normalize(localNormal * 2.0 - 1.0);

		blockLight = GetFinalBlockLighting(localPos, localNormal, deferredLighting.x);
        blockLight += SampleHandLight(localPos, localNormal);
		blockLight += deferredLighting.a;

        float deferredFogA = unpackUnorm4x8(deferredPostG).a;
        blockLight *= 1.0 - deferredFogA;

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
					blockLight = mix(blockLight, blockLightPrev, 0.9);
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
