#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec2 viewSize;
// uniform float viewHeight;
// uniform float viewWidth;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

uniform int isEyeInWater;
uniform float rainStrength;
uniform float skyRainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform float blindnessSmooth;
uniform int renderStage;

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/noise.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec2 texcoord = gl_FragCoord.xy / viewSize;
    
    vec3 clipPos = vec3(texcoord * 2.0 - 1.0, 1.0);
    vec3 viewPos = (gbufferProjectionInverse * vec4(clipPos, 1.0)).xyz;

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #endif

    vec4 final;
    if (renderStage == MC_RENDER_STAGE_STARS) {
        final = starData;

        if (starData.a > 0.5) {
            vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);

            #if SKY_TYPE == SKY_TYPE_CUSTOM
                float bright = hash13(localViewDir * 0.2);
                float temp = _pow2(bright) * 8000.0 + 2000.0;

                bright *= (_pow3(bright) * 4.0) * WorldSunBrightnessF;
                bright *= smoothstep(0.02, -0.16, localSunDirection.y);

                final.rgb = blackbody(temp) * bright;
                final.a = min(bright, 1.0);
            #endif
        }
    }
    else {
        final.a = 1.0;

        vec3 viewDir = normalize(viewPos);
        vec3 upDir = normalize(upPosition);
        float viewUpF = dot(viewDir, upDir);

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            final.rgb = GetCustomSkyColor(localSunDirection.y, viewUpF);
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            final.rgb = GetVanillaFogColor(fogColor, viewUpF);
            final.rgb = RGBToLinear(final.rgb);
        #endif

        #ifndef DH_COMPAT_ENABLED
            final.rgb *= WorldSkyBrightnessF;
        #endif
    }

    //final.rgb *= 1.0 - blindnessSmooth;

    #ifdef DH_COMPAT_ENABLED
        final.rgb = LinearToRGB(final.rgb);
    #elif !defined DEFERRED_BUFFER_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE != CLOUDS_CUSTOM
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 0) {
        #endif

            vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(far, vlLight, AirScatterF, AirExtinctF);
            final.rgb = final.rgb * scatterTransmit.a + scatterTransmit.rgb;

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif
    
    outFinal = final;
}
