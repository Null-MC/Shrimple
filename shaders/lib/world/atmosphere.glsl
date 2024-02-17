const float WorldAtmosphereMin =  62.0;
const float WorldAtmosphereMax = 800.0;

const float SkyDensityF = SKY_DENSITY * 0.01;
const float phaseAir = phaseIso;

#ifdef DISTANT_HORIZONS
	float SkyFar = max(2000.0, 2.0*dhFarPlane);
#else
	const float SkyFar = 2000.0;
#endif

#ifdef WORLD_SKY_ENABLED
	#if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
		float AirDensityF = mix(SkyDensityF, max(SkyDensityF, 0.04), skyRainStrength);
	#else
		const float AirDensityF = 0.0;
	#endif

	const float AirDensityRainF = 0.04;
	const vec3 AirScatterColor_rain = _RGBToLinear(vec3(0.800, 0.800, 0.820));
	const vec3 AirExtinctColor_rain = _RGBToLinear(vec3(0.569, 0.580, 0.612));

	const float AirAmbientF = 0.02;//mix(0.02, 0.0, skyRainStrength);
	const vec3 AirScatterColor = _RGBToLinear(vec3(0.392, 0.439, 0.471));
	const vec3 AirExtinctColor = _RGBToLinear(1.0 - vec3(0.871, 0.851, 0.831));//mix(0.02, 0.006, skyRainStrength);
#else
	const float AirDensityF = SkyDensityF;
	vec3 AirAmbientF = RGBToLinear(fogColor);

	const vec3 AirScatterColor = vec3(0.07);
	const vec3 AirExtinctColor = vec3(0.02);
#endif


float GetSkyDensity(const in float worldY) {
    return AirDensityF * (1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY));
}

float GetSkyPhase(const in float VoL) {
    return saturate(DHG(VoL, -0.06, 0.94, 0.44));
}
