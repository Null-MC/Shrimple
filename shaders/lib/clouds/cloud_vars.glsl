const float CloudSpeed = 0.01;
const float CloudDensityF = 1.0;
const float CloudAmbientF = 0.02;

const vec3 CloudScatterColor_clear = _RGBToLinear(vec3(0.50));
const vec3 CloudScatterColor_rain  = _RGBToLinear(vec3(0.16));

const vec3 CloudAbsorbColor_clear = 1.0 - _RGBToLinear(vec3(0.946, 0.961, 0.965));
const vec3 CloudAbsorbColor_rain  = 1.0 - _RGBToLinear(vec3(0.615, 0.595, 0.652));

vec3 CloudScatterColor    = mix(CloudScatterColor_clear, CloudScatterColor_rain, skyRainStrength);
vec3 CloudAbsorbColor     = mix(CloudAbsorbColor_clear, CloudAbsorbColor_rain, skyRainStrength);
float CloudAbsorbF        = mix(0.02, 0.128, skyRainStrength);


#define CLOUD_STEPS 24
#define CLOUD_SHADOW_STEPS 8
#define CLOUD_GROUND_SHADOW_STEPS 4
#define CLOUD_REFLECT_STEPS 12
#define CLOUD_REFLECT_SHADOW_STEPS 4

#if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    const int CloudMaxOctaves = 6;
    const int CloudTraceOctaves = 3;
    const int CloudShadowOctaves = 2;
    const float CloudHeight = 256.0;
    const float CloudSize = 24.0;
#elif SKY_CLOUD_TYPE == CLOUDS_CUSTOM_CUBE
    const int CloudMaxOctaves = 5;
    const int CloudTraceOctaves = 2;
    const int CloudShadowOctaves = 2;
    const float CloudHeight = 256.0;
    const float CloudSize = 20.0;
#else
    const float CloudHeight = 4.0;
    const float CloudSize = 4.0;
#endif
