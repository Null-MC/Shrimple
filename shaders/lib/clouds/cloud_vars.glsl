const float CloudFar = 2000.0;//mix(800.0, far, skyRainStrength);

float CloudDensityF = 10.0;//mix(10.0, 20.0, skyRainStrength);
float CloudAmbientF = 0.3;//mix(0.040, 0.020, skyRainStrength);
float CloudScatterF = mix(0.018, 0.018, skyRainStrength);
float CloudAbsorbF  = mix(0.003, 0.020, skyRainStrength);// * (1.0 - RGBToLinear(vec3(0.606, 0.429, 0.753)));

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
