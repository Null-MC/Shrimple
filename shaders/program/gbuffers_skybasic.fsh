#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float viewHeight;
uniform float viewWidth;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

uniform int isEyeInWater;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform float blindness;

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
#endif

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

#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec2 texcoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    
    vec3 clipPos = vec3(texcoord * 2.0 - 1.0, 1.0);
    vec3 viewPos = (gbufferProjectionInverse * vec4(clipPos, 1.0)).xyz;

    vec3 color;
    if (starData.a > 0.5) {
        color = starData.rgb;
    }
    else {
        vec3 viewDir = normalize(viewPos);
        vec3 upDir = normalize(upPosition);
        float viewUpF = dot(viewDir, upDir);

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        #endif

        #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
            color = GetCustomSkyColor(localSunDirection.y, viewUpF);
        #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
            color = GetVanillaFogColor(fogColor, viewUpF);
            color = RGBToLinear(color);
        #endif
    }

    //color *= 1.0 - blindness;

    #ifdef DH_COMPAT_ENABLED
        color = LinearToRGB(color);
    #else
        color *= WorldSkyBrightnessF;
    #endif
    
    outFinal = vec4(color, 1.0);
}
