const float CloudSpeed = 0.01;
// const float CloudDensityF = 0.6;
// const float CloudAmbientF = 0.1;

const vec3 CloudScatterColor_clear = _RGBToLinear(vec3(0.84));
const vec3 CloudScatterColor_rain  = _RGBToLinear(vec3(0.92));

const vec3 CloudAbsorbColor_clear = _RGBToLinear(1.0 - vec3(0.70));
const vec3 CloudAbsorbColor_rain  = _RGBToLinear(1.0 - vec3(0.54));

float CloudDensityF       = mix(0.4, 0.8, skyRainStrength);
float CloudAmbientF       = mix(0.12, 0.24, skyRainStrength);
vec3 CloudScatterColor    = mix(CloudScatterColor_clear, CloudScatterColor_rain, skyRainStrength);
vec3 CloudAbsorbColor     = mix(CloudAbsorbColor_clear, CloudAbsorbColor_rain, skyRainStrength);
float CloudAbsorbF        = mix(0.4, 0.4, skyRainStrength);


#define CLOUD_STEPS_MIN 12
#define CLOUD_STEPS_MAX 48
#define CLOUD_SHADOW_STEPS 16
#define CLOUD_GROUND_SHADOW_STEPS 6
#define CLOUD_REFLECT_STEPS 12
#define CLOUD_REFLECT_SHADOW_STEPS 4

#if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    // const int CloudMaxOctaves = 5;
    // const int CloudTraceOctaves = 2;
    // const int CloudShadowOctaves = 2;
    const float CloudHeight = 16.0;//SKY_CLOUD_HEIGHT;
    const float CloudSize = 12.0;
// #elif SKY_CLOUD_TYPE == CLOUDS_CUSTOM_CUBE
//     const int CloudMaxOctaves = 5;
//     const int CloudTraceOctaves = 2;
//     const int CloudShadowOctaves = 2;
//     const float CloudHeight = 512.0;
//     const float CloudSize = 64.0;
#else
    const float CloudHeight = 4.0;
    const float CloudSize = 4.0;
#endif

float GetCloudAltitude() {
    #if SKY_CLOUD_ALTITUDE > 0 || !defined IS_IRIS
        return SKY_CLOUD_ALTITUDE;
    #else
        return cloudHeight;
    #endif
}

vec2 GetCloudOffset() {
    vec2 cloudOffset = vec2(-cloudTime/12.0, 0.33);
    cloudOffset = mod(cloudOffset, vec2(256.0));
    cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

    return cloudOffset;
}

vec3 GetCloudCameraOffset() {
    const float irisCamWrap = 1024.0;

    vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
    camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
    return camOffset;
}
