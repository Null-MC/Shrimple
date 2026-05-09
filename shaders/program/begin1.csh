#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define WRITE_SCENE

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

uniform vec3 sunLocalDir;
uniform vec3 cameraPosition;
uniform float weatherStrength;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform float frameTime;

#include "/lib/buffers/scene.glsl"
#include "/lib/lighting/blackbody.glsl"


#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef SHADOWS_ENABLED
        const float SkyDayBrightness = 12.0;
    #else
        const float SkyDayBrightness = 8.0;
    #endif

    vec3 GetSkyLightColor(const in float localSunLightDir_y, const in float localSkyLightDir_y) {
        #ifndef WORLD_NETHER
            const float nightBrightF = OVERWORLD_NIGHT_BRIGHTNESS * 0.01;

            float dayF = smoothstep(-0.15, 0.05, localSunLightDir_y);
            float skyLightBrightness = mix(nightBrightF, SkyDayBrightness, dayF);
            skyLightBrightness *= pow(abs(localSkyLightDir_y), 0.25);// abs(localSunLightDir_y);

            //        skyLightBrightness *= mix(1.0, 0.08, smoothstep(0.0, 1.0, weatherStrength));
            skyLightBrightness *= mix(1.0, 0.12, weatherStrength);

            #ifdef WORLD_OVERWORLD
                vec3 sunColor = blackbody(OVERWORLD_SUN_TEMP);
            #else
                const vec3 sunColor = pow(vec3(0.749, 0.918, 0.980), vec3(2.2));
            #endif

            return skyLightBrightness * sunColor;
        #else
            //        const float brightnessF = NETHER_BRIGHTNESS * 0.01;
            //        return vec3(brightnessF);
            return vec3(0.0);
        #endif
    }
#endif


void main() {
    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        scene.skyLightColor = GetSkyLightColor(sunLocalDir.y, localSkyLightDir.y);
    #endif

    #ifdef WIND_ENABLED
        scene.WavingAnimLastF = scene.WavingAnimF;

        float wavingSpeed = mix(1.2, 2.0, weatherStrength) * frameTime;
        scene.WavingAnimF = mod(scene.WavingAnimF + wavingSpeed, PI * 1000.0);
    #endif
}
