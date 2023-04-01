float GetWorldBrightnessF() {
    #ifdef WORLD_SKY_ENABLED
        vec3 sunDir = normalize(sunPosition);
        vec3 upDir = normalize(upPosition);
        float nightDayF = dot(sunDir, upDir) * 0.5 + 0.5;
        return mix(WorldBrightnessNightF, WorldBrightnessDayF, nightDayF);
    #else
        return WorldBrightnessNightF;
    #endif
}
