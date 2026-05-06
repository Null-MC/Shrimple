#ifdef WORLD_NETHER
    const float MinAmbientF = NETHER_BRIGHTNESS * 0.01;
#else
    const float MinAmbientF = LIGHTING_MIN * 0.01;
#endif


vec3 GetSkyLightColor(const in vec3 localPos, const in float localSkyLightDir_y) {
    #ifndef WORLD_NETHER
        #ifdef WORLD_OVERWORLD
            float world_y = localPos.y + cameraPosition.y;
            vec3 transmit = sampleSkyTransmit(world_y, localSkyLightDir_y);
        #else
            const vec3 transmit = pow(vec3(0.961, 0.925, 0.843), vec3(2.2));
        #endif

        return scene.skyLightColor * transmit;
    #else
//        const float brightnessF = NETHER_BRIGHTNESS * 0.01;
//        return vec3(brightnessF);
        return vec3(0.0);
    #endif
}
