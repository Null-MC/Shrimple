#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D BUFFER_DEFERRED_LIGHTING;
uniform sampler2D BUFFER_DEFERRED_NORMAL;
uniform sampler2D BUFFER_BLOCKLIGHT;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D TEX_LIGHTMAP;

#if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform float frameTime;
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

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 5,6 */
layout(location = 0) out vec4 outLight;
layout(location = 1) out vec4 outDepth;

void main() {
	//vec2 viewSize = vec2(viewWidth, viewHeight);
	//vec2 bufferSize = viewSize / exp2(DYN_LIGHT_RES);

	float depth = textureLod(depthtex0, texcoord, 0).r;
	outDepth = vec4(vec3(depth), 1.0);

	if (depth < 1.0) {
		vec4 deferredLighting = textureLod(BUFFER_DEFERRED_LIGHTING, texcoord, 0);
		vec3 localNormal = textureLod(BUFFER_DEFERRED_NORMAL, texcoord, 0).rgb;

		vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        //float lightmapBlock = saturate((deferredLighting.x - (0.5/16.0)) * (16.0/15.0));

		vec3 blockLight;
		vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;
		vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
		vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));

		localNormal = normalize(localNormal * 2.0 - 1.0);

		blockLight = GetFinalBlockLighting(localPos, localNormal, deferredLighting.x);
        blockLight += SampleHandLight(localPos, localNormal);

        //vec3 lightColor = GetSceneBlockLightColor();
        //int blockId = int(deferredLighting.a * 255.0 + 0.5);
        //uint blockType = GetBlockType(blockId);
        //float lightLevel = GetSceneBlockLightLevel(blockType) / 15.0;
		blockLight += deferredLighting.a;

		#if DYN_LIGHT_PENUMBRA > 0
			vec3 uvPrev = clipPosPrev * 0.5 + 0.5;
			if (all(greaterThanEqual(uvPrev.xy, vec2(0.0))) && all(lessThan(uvPrev.xy, vec2(1.0)))) {
				float depthPrev = textureLod(BUFFER_LIGHT_DEPTH, uvPrev.xy, 0).r;

				//float linearDepth = linearizeDepthFast(depth, near, far);
				//float linearDepthPrev = linearizeDepthFast(depthPrev, near, far);
				//float linearDepth = length(viewPos);
				//float linearDepthPrev = length(viewPosPrev);

				//float depthWeight = saturate(200.0 * abs(linearDepth - linearDepthPrev));
				//outLight = vec4(vec3(abs(linearDepth - linearDepthPrev)), 1.0);
				//outLight = vec4(vec3(step(abs(uvPrev.z - depthPrev), 0.001)), 1.0);
				//return;

				if (abs(uvPrev.z - depthPrev) < 0.0001) {
					//float time = exp(-6.0 * frameTime);

					vec3 blockLightPrev = textureLod(BUFFER_BLOCKLIGHT, uvPrev.xy, 0).rgb;
					blockLight = mix(blockLight, blockLightPrev, 0.92);
				}
			}
		#endif

		outLight = vec4(blockLight, 1.0);
	}
	else {
		outLight = vec4(0.0);
	}
}
