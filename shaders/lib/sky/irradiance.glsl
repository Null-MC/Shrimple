vec3 SampleSkyIrradiance(const in vec3 localDir) {
    vec2 uv = DirectionToUV(localDir);
    return textureLod(texSkyIrradiance, uv, 0).rgb;
}
