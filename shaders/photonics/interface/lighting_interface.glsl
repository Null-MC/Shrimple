#define NO_SHADOW_MAPPING

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#else
    uniform sampler2D texLightmap;
#endif

//uniform float far;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float skyDayF;
uniform vec3 skyColor;
uniform vec3 sunLocalDir;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform float weatherStrength;
uniform float weatherDensity;
uniform int isEyeInWater;
uniform int vxRenderDistance;
uniform vec3 shadowLightPosition;

#include "/lib/buffers/scene.glsl"

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #include "/lib/sky-transmit.glsl"
    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/sampling/lightmap.glsl"
#endif

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


vec3 get_sun_direction() {
    return sunLocalDir;
}

vec3 get_sun_color(vec3 playerPos, vec3 direction) {
    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        return GetSkyLightColor(playerPos, abs(sunLocalDir.y));
    #else
        vec3 skyLightColor = texture(texLightmap, LightMapTex(vec2(0.0, 1.0))).rgb;
        return RGBToLinear(skyLightColor);
    #endif
}

vec3 get_sky_color(vec3 playerPos, vec3 direction) {
    #ifdef END
        const vec3 EndSkyLightColor = pow(vec3(0.769, 0.569, 0.812), vec3(2.2));
        return EndSkyLightColor;
    #elif defined(NETHER)
        return vec3(0.0);
    #else
        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        return GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, direction, weatherStrength, skyDayF);
    #endif
}

// bool is_in_shadow_at(vec3 scene_pos, vec3 geo_normal) {
//     //
// }
