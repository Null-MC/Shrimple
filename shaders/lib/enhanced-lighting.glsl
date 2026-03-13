const float MinAmbientF = LIGHTING_MIN * 0.01;


vec3 GetSkyLightColor(const in vec3 localPos, const in float localSunLightDir_y, const in float localSkyLightDir_y) {
    #ifdef WORLD_NETHER
        const float brightnessF = NETHER_BRIGHTNESS * 0.01;
        return vec3(brightnessF);
    #else
        const float nightBrightF = OVERWORLD_NIGHT_BRIGHTNESS * 0.01;

        float dayF = smoothstep(-0.15, 0.05, localSunLightDir_y);
        float skyLightBrightness = mix(nightBrightF, 6.00, dayF);
        skyLightBrightness *= abs(localSkyLightDir_y);// abs(localSunLightDir_y);

//        skyLightBrightness *= mix(1.0, 0.08, smoothstep(0.0, 1.0, weatherStrength));
        skyLightBrightness *= mix(1.0, 0.04, weatherStrength);

        #ifdef WORLD_OVERWORLD
            float world_y = localPos.y + cameraPosition.y;
            vec3 transmit = sampleSkyTransmit(world_y, localSkyLightDir_y);
        #else
            const vec3 transmit = pow(vec3(0.961, 0.925, 0.843), vec3(2.2));
        #endif

        return transmit * skyLightBrightness;
    #endif
}
