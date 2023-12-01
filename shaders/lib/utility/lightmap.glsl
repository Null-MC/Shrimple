const float lmCoordMin = (0.5/16.0);


vec2 LightMapNorm(vec2 lightCoord) {
    return (lightCoord - lmCoordMin) / (15.0/16.0);
}

vec2 LightMapTex(vec2 lightNorm) {
    return saturate(lightNorm) * (15.0/16.0) + lmCoordMin;
}
