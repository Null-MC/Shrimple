#define RENDER_OPAQUE_SSAO_APPLY
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D texSSAO;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float farPlane;
uniform float near;
uniform float far;

uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;

    uniform float rainStrength;
    uniform float weatherStrength;
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
        uniform mat4 dhProjectionInverse;
        uniform float dhNearPlane;
        uniform float dhFarPlane;
    #endif

    #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
        uniform float alphaTestRef;
    #endif
#endif

#include "/lib/sampling/depth.glsl"

#ifdef SKY_BORDER_FOG_ENABLED
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"
    #endif

    #include "/lib/fog/fog_common.glsl"

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
    #endif

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
    ivec2 iTexDepth = ivec2(texcoord * viewSize);
    float depth = texelFetch(depthtex0, iTexDepth, 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);
    mat4 projectionInv = gbufferProjectionInverse;

    #ifdef DISTANT_HORIZONS
        float dhDepth = texelFetch(dhDepthTex, iTexDepth, 0).r;
        float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

        if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            projectionInv = dhProjectionInverse;
            depthL = dhDepthL;
            depth = dhDepth;
        }
    #endif

    float occlusion = 1.0;

    if (depth < 1.0) {
        occlusion = textureLod(texSSAO, texcoord, 0).r;

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;

            vec3 viewPos = unproject(projectionInv, clipPos);
            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

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
                #else
                    float fogF = GetVanillaFogFactor(localPos);
                #endif

                occlusion = mix(occlusion, 1.0, fogF);

                // occlusion = 1.0 - occlusion;
                // occlusion *= 1.0 - fogF;
                // occlusion = 1.0 - occlusion;
            #endif
        #endif
    }

    outAO = vec4(occlusion);
}
