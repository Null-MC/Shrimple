const float CloudDensityF = 1.0;
const float CloudAmbientF = 0.02;//mix(0.05, 0.4, skyRainStrength);
float CloudScatterF       = mix(0.30, 0.018, skyRainStrength);
float CloudAbsorbF        = mix(0.06, 0.128, skyRainStrength);
vec3 CloudAbsorbColor = vec3(CloudAbsorbF);// 1.0 - _RGBToLinear(vec3(0.6, 0.2, 0.8));

const float CloudSpeed = 0.01;

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
