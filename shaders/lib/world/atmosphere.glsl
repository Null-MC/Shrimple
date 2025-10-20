const float FogDensity_Day = SKY_FOG_DENSITY * 0.01;
const float FogDensity_Night = SKY_FOG_DENSITY_NIGHT * 0.01;
const float FogDensity_Rain = SKY_FOG_DENSITY_RAIN * 0.01;
const float FogDensity_Cave = SKY_CAVE_FOG_DENSITY * 0.01;

#ifdef DISTANT_HORIZONS
    float SkyFar = max(4000.0, dhFarPlane);
#else
    const float SkyFar = 4000.0;
#endif

#ifdef WORLD_SKY_ENABLED
    const float AirAmbientF = 0.6;//mix(0.02, 0.0, weatherStrength);
    vec3 AirScatterColor = vec3(0.24);//vec3(mix(0.12, 0.09, weatherStrength));
    // const vec3 AirExtinctColor = _RGBToLinear(1.0 - vec3(0.6));//mix(0.02, 0.006, weatherStrength);
    float AirExtinctFactor = 0.12;
    vec3 AirExtinctColor = vec3(AirExtinctFactor);//vec3(mix(0.08, 0.09, weatherStrength));//mix(0.02, 0.006, weatherStrength);
#else
    // const float AirDensityF = FogDensity_Day;
    vec3 AirAmbientF = RGBToLinear(fogColor);

    const vec3 AirScatterColor = vec3(0.07);
    const vec3 AirExtinctColor = vec3(0.02);
#endif

uniform float weatherHumidity;

float GetAirDensity(const in float skyLightF) {
    #ifdef WORLD_SKY_ENABLED
        #if LIGHTING_VOLUMETRIC != VOL_TYPE_NONE
            // base
            float density = FogDensity_Day * weatherHumidity;

            const float SunriseShift = 0.06;

            // night
            float nightF = -sin((sunAngle - SunriseShift) * 2.0*PI);
            // nightF = nightF * max(nightF, 0.0);
            nightF = nightF * 0.5 + 0.5;
            density = mix(density, FogDensity_Night, _pow3(nightF));

            // weather
            float localWeatherStrength = weatherStrength * skyLightF;
            return mix(density, FogDensity_Rain, localWeatherStrength);
        #else
            return 0.0;
        #endif
    #else
        return FogDensity_Day;
    #endif
}

#ifdef SKY_CAVE_FOG_ENABLED
    float GetCaveFogF() {
        float eyeLightF = eyeBrightnessSmooth.y / 240.0;
        return 1.0 - smoothstep(0.0, 0.1, eyeLightF);
        //densityFinal = mix(densityFinal, FogDensity_Cave, caveF);
    }
#endif
