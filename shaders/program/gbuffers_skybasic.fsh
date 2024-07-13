#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if SKY_STARS == STARS_VANILLA
    in vec4 starData;
#endif

#if SKY_STARS == STARS_FANCY
    uniform sampler2D noisetex;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec2 viewSize;
// uniform float viewHeight;
uniform float viewWidth;
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

#if SKY_STARS == STARS_FANCY
    uniform int worldTime;
    uniform float sunAngle;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform vec3 previousCameraPosition;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/utility/matrix.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/sky.glsl"

#include "/lib/fog/fog_common.glsl"

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/fog/fog_water_custom.glsl"
    #endif
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#if SKY_STARS == STARS_FANCY
    #include "/lib/sky/stars.glsl"
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
    vec2 texcoord = gl_FragCoord.xy / viewSize;
    
    vec3 clipPos = vec3(texcoord * 2.0 - 1.0, 1.0);
    vec3 viewPos = (gbufferProjectionInverse * vec4(clipPos, 1.0)).xyz;

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #endif

    vec3 viewDir = normalize(viewPos);
    vec3 upDir = normalize(upPosition);
    float viewUpF = dot(viewDir, upDir);

    vec4 final = vec4(1.0);

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        final.rgb = GetCustomSkyColor(localSunDirection.y, viewUpF);
    #else
        final.rgb = GetVanillaFogColor(fogColor, viewUpF);
        final.rgb = RGBToLinear(final.rgb);
    #endif

    final.rgb *= Sky_BrightnessF;

    #if SKY_STARS == STARS_FANCY
        vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
        vec3 starViewDir = getStarViewDir(localViewDir);
        vec3 starLight = GetStarLight(starViewDir);

        #if SKY_CLOUD_TYPE != CLOUDS_CUSTOM
            starLight *= 1.0 - 0.8 * skyRainStrength;
        #endif

        float moonUpF = smoothstep(-0.1, 0.2, -localSunDirection.y);
        final.rgb += starLight * (moonUpF * Sky_BrightnessF);
    #elif SKY_STARS == STARS_VANILLA
        if (renderStage == MC_RENDER_STAGE_STARS) {
            final = starData;
            final.rgb *= Sky_MoonBrightnessF;
        }
    #endif

    //final.rgb *= 1.0 - blindnessSmooth;

    #if !defined DEFERRED_BUFFER_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE <= CLOUDS_VANILLA
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 0) {
        #endif

            vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(far, vlLight, AirScatterColor, AirExtinctColor);
            final.rgb = final.rgb * scatterTransmit.a + scatterTransmit.rgb;

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif
    
    outFinal = final;

    #ifdef EFFECT_TAA_ENABLED
        vec3 velocity = vec3(0.0);

        if (renderStage == MC_RENDER_STAGE_STARS)
            velocity = cameraPosition - previousCameraPosition;

        outVelocity = vec4(velocity, 0.0);
    #endif
}
