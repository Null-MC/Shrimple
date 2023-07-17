#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float viewHeight;
uniform float viewWidth;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float far;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform int isEyeInWater;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform float blindness;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#ifdef DH_COMPAT_ENABLED
    #include "/lib/post/saturation.glsl"
    #include "/lib/post/tonemap.glsl"
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
        //float viewUpF = dot(viewDir, gbufferModelView[1].xyz);

        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            #if defined DEFERRED_BUFFER_ENABLED && defined DEFER_TRANSLUCENT
                vec3 skyColorFinal = RGBToLinear(skyColor);
                vec3 fogColor = GetCustomSkyFogColor(localSunDirection.y);
                color = GetSkyFogColor(skyColorFinal, fogColor, viewUpF);
            #else
                if (isEyeInWater == 1) {
                    color = GetCustomWaterFogColor(localSunDirection.y);
                }
                else {
                    vec3 skyColorFinal = RGBToLinear(skyColor);
                    vec3 fogColor = GetCustomSkyFogColor(localSunDirection.y);
                    color = GetSkyFogColor(skyColorFinal, fogColor, viewUpF);
                }
            #endif
        #elif WORLD_FOG_MODE == FOG_MODE_VANILLA
            color = GetVanillaFogColor(fogColor, viewUpF);
            color = RGBToLinear(color);
        #else
            color = RGBToLinear(skyColor);
        #endif
    }

    color *= 1.0 - blindness;

    #ifdef DH_COMPAT_ENABLED
        ApplyPostProcessing(color);
    #endif
    
    outFinal = vec4(color, 1.0);
}
