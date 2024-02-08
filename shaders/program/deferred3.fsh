#define RENDER_OPAQUE_SSAO_APPLY
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform sampler2D colortex12;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;

    uniform float rainStrength;
    uniform float skyRainStrength;
    uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef SKY_BORDER_FOG_ENABLED
    #ifdef WORLD_WATER_ENABLED
        uniform vec3 WaterAbsorbColor;
        uniform vec3 WaterScatterColor;
        uniform float waterDensitySmooth;
    #endif

    #ifdef WORLD_WATER_ENABLED
        uniform int isEyeInWater;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhModelViewInverse;
        uniform mat4 dhProjectionInverse;
        uniform float dhNearPlane;
        uniform float dhFarPlane;
    #endif

    #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
        uniform float alphaTestRef;
    #endif
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/gaussian.glsl"

#ifdef SKY_BORDER_FOG_ENABLED
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"
    #endif

    #include "/lib/fog/fog_common.glsl"
    #include "/lib/world/sky.glsl"

    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
    #endif

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        #include "/lib/fog/fog_custom.glsl"
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif
#endif


float BilateralGaussianDepthBlur_5x(const in vec2 texcoord, const in float linearDepth) {
    const float g_sigmaXY = 3.0;
    const float g_sigmaV = 0.2;

    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    float accum = 0.0;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigmaXY, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigmaXY, ix);
            
            vec2 sampleTex = texcoord + vec2(ix, iy) * pixelSize;

            ivec2 iTexBlend = ivec2(sampleTex * viewSize);
            float sampleValue = texelFetch(colortex12, iTexBlend, 0).r;

            ivec2 iTexDepth = ivec2(sampleTex * viewSize);
            float sampleDepth = texelFetch(depthtex1, iTexDepth, 0).r;
            float sampleLinearDepth = linearizeDepthFast(sampleDepth, near, far);

            if (sampleDepth >= 1.0) {
                sampleDepth = texelFetch(dhDepthTex, iTexDepth, 0).r;
                sampleLinearDepth = linearizeDepthFast(sampleDepth, dhNearPlane, dhFarPlane);
            }
                        
            float fv = Gaussian(g_sigmaV, abs(sampleLinearDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return 0.0;
    return accum / total;
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = texelFetch(depthtex1, ivec2(texcoord * viewSize), 0).r;
    float linearDepth = linearizeDepthFast(depth, near, far);
    float occlusion = 0.0;

    #ifdef DISTANT_HORIZONS
        bool isDepthDh = false;
        if (depth >= 1.0) {
            depth = texelFetch(dhDepthTex, ivec2(texcoord * viewSize), 0).r;
            linearDepth = linearizeDepthFast(depth, dhNearPlane, dhFarPlane);
            isDepthDh = true;
        }
    #endif

    if (depth < 1.0) {
        //occlusion = textureLod(colortex12, texcoord, 0).r;

        occlusion = BilateralGaussianDepthBlur_5x(texcoord, linearDepth);
        // occlusion = textureLod(colortex12, texcoord, 0).r;

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
            vec3 viewPos, localPos;

            if (isDepthDh) {
                viewPos = unproject(dhProjectionInverse * vec4(clipPos, 1.0));
                localPos = (dhModelViewInverse * vec4(viewPos, 1.0)).xyz;
            }
            else {
                viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
                localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            }
    
            #ifdef SKY_BORDER_FOG_ENABLED
                #if SKY_TYPE == SKY_TYPE_CUSTOM
                    float fogDist = length(viewPos);

                    float fogF;
                    #ifdef WORLD_WATER_ENABLED
                        if (isEyeInWater == 1) {
                            fogF = GetCustomWaterFogFactor(fogDist);
                        }
                        else {
                    #endif

                        fogF = GetCustomFogFactor(fogDist);

                    #ifdef WORLD_WATER_ENABLED
                        }
                    #endif

                    occlusion *= 1.0 - fogF;
                #elif SKY_TYPE == SKY_TYPE_VANILLA
                    occlusion *= 1.0 - GetVanillaFogFactor(localPos);
                #endif
            #endif
        #endif
    }

    outAO = vec4(1.0 - occlusion);
}
