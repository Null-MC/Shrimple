const float SkyDensityF = SKY_FOG_DENSITY * 0.01;
const float CaveFogDensityF = SKY_CAVE_FOG_DENSITY * 0.01;

#ifdef DISTANT_HORIZONS
    float SkyFar = max(4000.0, dhFarPlane);
#else
    const float SkyFar = 4000.0;
#endif

#ifdef SKY_CAVE_FOG_ENABLED
    float GetCaveFogF() {
        float eyeLightF = eyeBrightnessSmooth.y / 240.0;
        return 1.0 - smoothstep(0.0, 0.1, eyeLightF);
        //densityFinal = mix(densityFinal, CaveFogDensityF, caveF);
    }
#endif
