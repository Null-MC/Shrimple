vec3 SampleLpvIndirect(const in vec3 lpvPos) {
    vec3 texcoord = lpvPos / SceneLPVSize;

    vec3 lpvSample = (frameCounter % 2) == 0
        ? textureLod(texIndirectLpv_1, texcoord, 0).rgb
        : textureLod(texIndirectLpv_2, texcoord, 0).rgb;

    lpvSample = RGBToLinear(lpvSample);

    vec3 hsv = RgbToHsv(lpvSample);
    hsv.z = saturate(hsv.z);
    hsv.z = _pow2(hsv.z);
    lpvSample = HsvToRgb(hsv);

    return lpvSample;
}
