const float CloudAmbientF = 0.02;
const float CloudScatterF = mix(2.40, 1.20, rainStrength);
const float CloudAbsorbF  = mix(0.36, 0.96, rainStrength);
const float CloudFar = 800.0;//mix(800.0, far, rainStrength);

#if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
    const float CloudHeight = 128.0;
    const float CloudSize = 16.0;
#else
    const float CloudHeight = 4.0;
    const float CloudSize = 4.0;
#endif
