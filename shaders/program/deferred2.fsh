#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform sampler2D BUFFER_DEFERRED_NORMAL;
uniform sampler2D BUFFER_DEFERRED_LIGHTING;
uniform sampler2D BUFFER_DEFERRED_FOG;
uniform sampler2D BUFFER_DEFERRED_SHADOW;
uniform sampler2D BUFFER_BLOCKLIGHT;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D TEX_LIGHTMAP;

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindness;

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif
#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/bilateral_gaussian.glsl"

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/buffers/lighting.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/dynamic.glsl"
#include "/lib/lighting/collisions.glsl"
#include "/lib/lighting/tracing.glsl"
#include "/lib/lighting/dynamic_blocks.glsl"

#include "/lib/world/fog.glsl"
#include "/lib/lighting/basic.glsl"

#ifdef TONEMAP_ENABLED
    #include "/lib/post/tonemap.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 iTex = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, iTex, 0).r;
    vec3 final;

    if (depth < 1.0) {
        vec2 viewSize = vec2(viewWidth, viewHeight);

        vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;
        //vec3 localNormal = texelFetch(BUFFER_DEFERRED_NORMAL, iTex, 0).rgb;
        vec3 deferredLighting = texelFetch(BUFFER_DEFERRED_LIGHTING, iTex, 0).rgb;
        vec4 deferredFog = texelFetch(BUFFER_DEFERRED_FOG, iTex, 0);
        vec3 deferredShadow = texelFetch(BUFFER_DEFERRED_SHADOW, iTex, 0).rgb;

        float linearDepth = linearizeDepthFast(depth, near, far);
        const vec3 sigma = vec3(3.0, 3.0, 0.002) / linearDepth;

        #ifdef DYN_LIGHT_BLUR
            const float lightBufferScale = rcp(exp2(DYN_LIGHT_RES));
            vec2 lightBufferSize = viewSize * lightBufferScale;
            vec3 blockLight = BilateralGaussianDepthBlurRGB_7x(texcoord, BUFFER_BLOCKLIGHT, lightBufferScale, BUFFER_LIGHT_DEPTH, lightBufferSize, linearDepth, sigma);
        #else
            #if DYN_LIGHT_RES == 0
                vec3 blockLight = texelFetch(BUFFER_BLOCKLIGHT, iTex, 0).rgb;
            #else
                vec3 blockLight = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
            #endif
        #endif

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec3 albedo = RGBToLinear(deferredColor);
        final = GetFinalLighting(albedo, blockLight, deferredShadow, viewPos, deferredLighting.xy, deferredLighting.z);

        vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
        final = mix(final, fogColorFinal, deferredFog.a);
    }
    else {
        #ifdef WORLD_SKY_ENABLED
            final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
            final = RGBToLinear(final);
        #else
            final = RGBToLinear(fogColor) * WorldBrightnessF;
        #endif
    }

    #ifdef TONEMAP_ENABLED
        final = tonemap_Tech(final);
    #endif

    outFinal = LinearToRGB(final);
}
