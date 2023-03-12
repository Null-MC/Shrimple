#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D BUFFER_DEFERRED_LIGHTING;
uniform sampler2D BUFFER_DEFERRED_NORMAL;
uniform sampler2D TEX_LIGHTMAP;

#if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform int frameCounter;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
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
layout(location = 0) out vec3 outLight;
layout(location = 1) out float outDepth;

void main() {
	vec2 viewSize = vec2(viewWidth, viewHeight);
	vec2 bufferSize = viewSize / exp2(DYN_LIGHT_RES);

    //vec2 offset = mod(gl_FragCoord.xy - 0.5, 2);// / viewSize;
	//ivec2 iTex = ivec2((gl_FragCoord.xy - 0.5) * exp2(DYN_LIGHT_RES) + offset);
	ivec2 iTex = ivec2(gl_FragCoord.xy * exp2(DYN_LIGHT_RES));
	float depth = texelFetch(depthtex0, iTex, 0).r;

	if (depth < 1.0) {
		vec3 deferredLighting = texelFetch(BUFFER_DEFERRED_LIGHTING, iTex, 0).rgb;
		vec3 localNormal = texelFetch(BUFFER_DEFERRED_NORMAL, iTex, 0).rgb;

		vec3 clipPos = vec3(gl_FragCoord.xy / bufferSize, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

		localNormal = normalize(localNormal * 2.0 - 1.0);

		vec3 blockLight = GetFinalBlockLighting(localPos, localNormal, deferredLighting.x);
        blockLight += SampleHandLight(localPos, localNormal);
		blockLight += saturate((deferredLighting.x - (0.5/16.0)) * (16.0/15.0));

		outLight = blockLight;
		outDepth = depth;
		//outDepth = linearizeDepthFast(depth, near, far);
	}
	else {
		outLight = vec3(0.0);
		outDepth = 1.0;
	}
}
