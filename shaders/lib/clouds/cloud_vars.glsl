const float CloudAmbientF = mix(0.09, 0.09, skyRainStrength);
const float CloudScatterF = mix(1.12, 3.40, skyRainStrength);
const float CloudAbsorbF  = mix(0.18, 0.44, skyRainStrength);// * (1.0 - RGBToLinear(vec3(0.606, 0.429, 0.753)));
const float CloudFar = 800.0;//mix(800.0, far, skyRainStrength);

#if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    const float CloudHeight = 128.0;
    const float CloudSize = 16.0;
#else
    const float CloudHeight = 4.0;
    const float CloudSize = 4.0;
#endif
