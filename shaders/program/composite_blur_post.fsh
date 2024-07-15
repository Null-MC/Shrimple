#define RENDER_TRANSLUCENT_BLUR_POST
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifndef EFFECT_TAA_ENABLED
    const bool colortex0MipmapEnabled = true;
#endif

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D BUFFER_FINAL;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
    uniform sampler2D dhDepthTex1;
#endif

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;
uniform float farPlane;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float weatherStrength;

// #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
//     uniform float centerDepthSmooth;
// #endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if EFFECT_BLUR_RADIUS_BLIND > 0
    uniform float blindnessSmooth;
#endif

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/gaussian.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef WORLD_WATER_ENABLED
    #include "/lib/lighting/hg.glsl"
    #include "/lib/world/water.glsl"
#endif

#include "/lib/effects/blur.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, uv, 0).r;
    // float depth = textureLod(depthtex0, texcoord, 0.0).r;

    float depthL = linearizeDepthFast(depth, near, farPlane);

    #ifdef DISTANT_HORIZONS
        mat4 projectionInv = gbufferProjectionInverse;

        // float dhDepth = textureLod(dhDepthTex, texcoord, 0).r;
        float dhDepth = texelFetch(dhDepthTex, uv, 0).r;
        float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

        if (dhDepthL < depthL || depth >= 1.0) {
            depth = dhDepth;
            depthL = dhDepthL;
            projectionInv = dhProjectionInverse;
        }

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(projectionInv, clipPos);
    #else
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
    #endif

    float viewDist = length(viewPos);

    vec3 color = GetBlur(texcoord, depthL, 0.0, viewDist, isEyeInWater == 1);

    outFinal = vec4(color, 1.0);
}
