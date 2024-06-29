#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
} vIn;

uniform sampler2D gtexture;

uniform int renderStage;
uniform float rainStrength;
uniform float skyRainStrength;
uniform int frameCounter;

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 sunPosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif


#ifdef EFFECT_TAA_ENABLED
    /* RENDERTARGETS: 0,7 */
    layout(location = 0) out vec4 outFinal;
    layout(location = 1) out vec4 outVelocity;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
    vec4 color = textureLod(gtexture, vIn.texcoord, 0);

    #if SKY_CLOUD_TYPE == CLOUD_TYPE_VANILLA
        color.rgb *= vIn.color.rgb;
    #endif

    color.rgb = RGBToLinear(color.rgb);// * Sky_BrightnessF;

    //color.a = saturate(length2(color.rgb) / sqrt(3.0));

    // try and reduce amount of velocity pixels affected
    if (luminance(color.rgb) * color.a < (0.5/255.0)) {discard; return;}

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #endif

    if (renderStage == MC_RENDER_STAGE_SUN) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 WorldSunLightColor = GetSkySunColor(localSunDirection.y);
        #endif

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            color.rgb *= 10.0 * WorldSunLightColor * Sky_SunBrightnessF;
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            color.rgb *= 10.0 * Sky_BrightnessF;
        #endif

        color.rgb *= smoothstep(-0.1, 0.1, localSunDirection.y);
    }
    else if (renderStage == MC_RENDER_STAGE_MOON) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 WorldMoonLightColor = GetSkyMoonColor(localSunDirection.y);
        #endif

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            color.rgb *= 4.0 * WorldMoonLightColor;
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            color.rgb *= Sky_BrightnessF;
        #endif

        color.rgb *= smoothstep(0.1, -0.1, localSunDirection.y);
    }
    else {
        #ifndef WORLD_END
            color.rgb *= Sky_BrightnessF;
        #endif
    }

    // #ifdef WORLD_END
    //     color.rgb *= Sky_BrightnessF;
    // #endif

    //if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
    //    color.rgb *= 2.0;

    // color.rgb += InterleavedGradientNoise(gl_FragCoord.xy) / 256.0;

    // #ifdef WORLD_END
    //     color.rgb *= 10.0;
    // #endif

    outFinal = color;

    #ifdef EFFECT_TAA_ENABLED
        vec3 velocity = cameraPosition - previousCameraPosition;

        outVelocity = vec4(velocity, 0.0);
    #endif
}
