#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;
in vec3 localPos;


#ifdef SKY_STARS_FANCY
    uniform sampler2D noisetex;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
#endif

uniform float far;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float skyDayF;
uniform float sunAngle;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform int renderStage;
uniform int isEyeInWater;
uniform vec3 sunLocalDir;
uniform vec3 cameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform vec2 viewSizeScaled;

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"

#ifdef SKY_STARS_FANCY
    #include "/lib/matrix.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/sky/stars.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    #include "/lib/sky-transmit.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    #if RENDER_SCALE != 0
        ivec2 uv = ivec2(gl_FragCoord.xy);
        if (any(greaterThan(uv, viewSizeScaled))) return;
    #endif

    vec4 color = vec4(0.0);
    vec3 localViewDir = normalize(localPos);

    #ifdef SKY_STARS_FANCY
        vec3 starLight = GetStarLight(localViewDir);

        starLight *= 1.0 - 0.8 * weatherStrength;

        float moonUpF = smoothstep(-0.1, 0.2, -sunLocalDir.y);
        color.rgb += starLight * moonUpF;
    #else
        if (renderStage == MC_RENDER_STAGE_STARS) {
            color = starData;
            color.rgb = RGBToLinear(color.rgb);
        }
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
        color.rgb *= sampleSkyTransmit(cameraPosition.y, localViewDir.y);
    #endif

    if (renderStage != MC_RENDER_STAGE_STARS) {
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 fogColorL = RGBToLinear(fogColor);
//        color.rgb = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);
        color.rgb += GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, localViewDir, weatherStrength, skyDayF);
        color.a = 1.0;
    }

    outFinal = color;
}
