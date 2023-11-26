uint GetSceneItemLightType(const in int itemId) {
    #if !(defined RENDER_HAND && defined IS_IRIS)
        // int blockId = GetItemBlockId(itemId);
        // if (blockId != BLOCK_EMPTY)
        //     return GetSceneLightType(blockId);

        uint lightId = GetItemLightId(itemId);
        if (lightId != LIGHT_NONE) return lightId;
    #endif

    //return GetSceneLightType(itemId);
    return CollissionMaps[itemId].LightId;
}

#if !defined RENDER_BEGIN
    vec3 GetSceneItemLightColor(const in int itemId, const in vec2 noiseSample) {
        vec3 lightColor = vec3(0.0);

        #ifdef IRIS_FEATURE_SSBO
            uint lightType = GetSceneItemLightType(itemId);

            if (lightType != LIGHT_EMPTY) {
                StaticLightData lightInfo = StaticLightMap[lightType];
                lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                lightColor = RGBToLinear(lightColor);

                #ifdef DYN_LIGHT_FLICKER
                    ApplyLightFlicker(lightColor, lightType, noiseSample);
                #endif
            }
        #endif

        return lightColor;
    }
#endif

float GetSceneItemLightRange(const in int itemId, const in float defaultValue) {
    float lightRange = defaultValue;

    #ifdef IRIS_FEATURE_SSBO
        uint lightType = GetSceneItemLightType(itemId);

        if (lightType != LIGHT_EMPTY) {
            StaticLightData lightInfo = StaticLightMap[lightType];
            lightRange = unpackUnorm4x8(lightInfo.RangeSize).x * 255.0;
        }
    #endif

    return lightRange;
}

float GetSceneItemLightSize(const in int itemId) {
    float lightSize = 0.1;

    #ifdef IRIS_FEATURE_SSBO
        uint lightType = GetSceneItemLightType(itemId);

        if (lightType != LIGHT_EMPTY) {
            StaticLightData lightInfo = StaticLightMap[lightType];
            lightSize = unpackUnorm4x8(lightInfo.RangeSize).y;
        }
    #endif

    return lightSize;
}
