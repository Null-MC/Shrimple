vec3 GetSkyColor(const in vec3 localSunDir, const in vec3 localViewDir) {
    #ifdef WORLD_SKY_ENABLED
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            vec3 skyColorL = GetCustomSkyColor(localSunDirection, localViewDir);
        #else
            vec3 fogColorL = RGBToLinear(fogColor);
            vec3 skyColorL = GetVanillaFogColor(fogColorL, localViewDir.y);
        #endif

        #if LIGHTING_MODE != LIGHTING_MODE_NONE
            skyColorL *= 0.5;
        #endif

        return skyColorL;
    #else
        return RGBToLinear(fogColor);
    #endif
}
