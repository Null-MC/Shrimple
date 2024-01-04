float CloudAmbientF = mix(4.2, 2.6, skyRainStrength);
float CloudScatterF = mix(3.8, 3.8, skyRainStrength);
float CloudAbsorbF  = mix(0.6, 1.4, skyRainStrength);// * (1.0 - RGBToLinear(vec3(0.606, 0.429, 0.753)));
const float CloudFar = 2000.0;//mix(800.0, far, skyRainStrength);

#if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    const float CloudHeight = 128.0;
    const float CloudSize = 24.0;
#elif SKY_CLOUD_TYPE == CLOUDS_CUSTOM_CUBE
    const float CloudHeight = 128.0;
    const float CloudSize = 24.0;
#else
    const float CloudHeight = 4.0;
    const float CloudSize = 4.0;
#endif
