#define RENDER_OPAQUE_SSAO_APPLY
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform sampler2D colortex12;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
    uniform vec3 fogColor;
    uniform float fogStart;
    uniform float fogEnd;
    uniform int fogShape;

    uniform float rainStrength;
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

    #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
        uniform float alphaTestRef;
    #endif
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bilateral_gaussian.glsl"

#ifdef SKY_BORDER_FOG_ENABLED
    #include "/lib/fog/fog_common.glsl"

    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
    #endif

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        #include "/lib/fog/fog_custom.glsl"
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = texelFetch(depthtex1, ivec2(texcoord * viewSize), 0).r;
    float occlusion = 0.0;

    if (depth < 1.0) {
        //occlusion = textureLod(colortex12, texcoord, 0).r;

        float linearDepth = linearizeDepthFast(depth, near, far);
        occlusion = BilateralGaussianDepthBlur_5x(texcoord, colortex12, viewSize, depthtex1, viewSize, linearDepth, 0.2);

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
            vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
            vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            
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
    }

    outAO = vec4(1.0 - occlusion);
}
