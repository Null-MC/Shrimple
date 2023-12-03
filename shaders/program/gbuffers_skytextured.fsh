#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;

uniform sampler2D gtexture;

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 sunPosition;
#endif

uniform int renderStage;
uniform float rainStrength;
uniform float skyRainStrength;

// uniform vec3 skyColor;
// uniform vec3 fogColor;
// uniform float fogStart;
// uniform float fogEnd;
// uniform int fogShape;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 color = textureLod(gtexture, texcoord, 0) * glcolor;
    color.rgb = RGBToLinear(color.rgb);// * WorldSkyBrightnessF;

    //color.a = saturate(length2(color.rgb) / sqrt(3.0));

    if (renderStage == MC_RENDER_STAGE_SUN) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            vec3 WorldSunLightColor = GetSkySunColor(localSunDirection.y);
        #endif

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            color.rgb *= 40.0 * WorldSunLightColor;
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            color.rgb *= WorldSunLightColor;
        #endif

        color.rgb *= smoothstep(-0.1, 0.1, localSunDirection.y);
    }
    else if (renderStage == MC_RENDER_STAGE_MOON) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            vec3 WorldMoonLightColor = GetSkyMoonColor(localSunDirection.y);
        #endif

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            color.rgb *= 4.0 * WorldMoonLightColor;
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            color.rgb *= WorldMoonLightColor;
        #endif

        color.rgb *= smoothstep(0.1, -0.1, localSunDirection.y);
    }
    else if (renderStage == MC_RENDER_STAGE_CUSTOM_SKY) {
        color.rgb *= WorldSkyBrightnessF;
    }

    //if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
    //    color.rgb *= 2.0;

    #ifndef DEFERRED_BUFFER_ENABLED
        //ApplyPostProcessing(color.rgb);
        color.rgb = LinearToRGB(color.rgb);
    #endif

    // color.rgb += InterleavedGradientNoise(gl_FragCoord.xy) / 256.0;

    // #ifdef WORLD_END
    //     color.rgb *= 10.0;
    // #endif

    outColor0 = color;
}
