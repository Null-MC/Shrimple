float SampleWaterCaustics(const in vec3 localPos, const in float lightDist, const in float skyLight) {
    float causticTime = 0.25 * GetAnimationFactor();

    vec3 shadowViewPos = localPos + fract(cameraPosition*0.01)*100.0;// + vec3(1.0, 0.0, 3.0) * Water_WaveStrength * causticTime;

    #ifdef RENDER_SHADOWS_ENABLED
        #ifdef IRIS_FEATURE_SSBO
            shadowViewPos = mat3(shadowModelViewEx) * shadowViewPos;
        #else
            shadowViewPos = mat3(shadowModelView) * shadowViewPos;
        #endif
    #else
        shadowViewPos = shadowViewPos.xzy;
    #endif

    vec3 causticCoord = vec3(0.06/Water_WaveStrength * shadowViewPos.xy, causticTime);
    float causticLight = textureLod(texCaustics, causticCoord.xyz, 0).r;
    //causticLight = RGBToLinear(causticLight);

    #ifndef RENDER_SHADOWS_ENABLED
        causticLight *= skyLight;
    #endif

    float causticDepthF = 1.0;//min(lightDist / 8.0, 1.0);
    causticLight = 6.0 * pow(causticLight, 6.0 + 4.0 * Water_WaveStrength) + 0.9;
    return mix(1.0, causticLight, causticDepthF * Water_CausticStrength);
}
