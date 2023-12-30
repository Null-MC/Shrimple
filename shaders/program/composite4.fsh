#define RENDER_OPAQUE_SSAO
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform usampler2D BUFFER_DEFERRED_DATA;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;
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

    #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
        uniform float alphaTestRef;
    #endif
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/effects/ssao.glsl"

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
    float depth = textureLod(depthtex1, texcoord, 0).r;
    vec4 final = vec4(1.0);

    if (depth < 1.0) {
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        //#ifdef DEFERRED_BUFFER_ENABLED
            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(gl_FragCoord.xy), 0);
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texViewNormal = deferredTexture.rgb;

            if (any(greaterThan(texViewNormal, EPSILON3))) {
                texViewNormal = normalize(texViewNormal * 2.0 - 1.0);
                texViewNormal = mat3(gbufferModelView) * texViewNormal;
            }
        // #else
        //     vec3 texViewNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
        // #endif

        float occlusion = GetSpiralOcclusion(texcoord, viewPos, texViewNormal);

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            float fogF = 0.0;
            
            #if SKY_TYPE == SKY_TYPE_CUSTOM
                #ifdef WORLD_WATER_ENABLED
                    if (isEyeInWater == 1) {
                        float fogDist = length(localPos);
                        fogF = GetCustomWaterFogFactor(fogDist);
                    }
                    else {
                #endif
                    float fogDist = GetShapedFogDistance(localPos);
                    fogF = GetCustomFogFactor(fogDist);
                #ifdef WORLD_WATER_ENABLED
                    }
                #endif
            #elif SKY_TYPE == SKY_TYPE_VANILLA
                //fogF = GetVanillaFogFactor(localPos);
                fogF = unpackUnorm4x8(deferredData.b).a;
            #endif

            occlusion *= 1.0 - fogF;
        #endif

        final.a = 1.0 - occlusion;
    }

    outAO = final;
}
