const float AirDensityF = SKY_DENSITY * 0.01;
const float phaseAir = phaseIso;

#ifdef DISTANT_HORIZONS
	float SkyFar = max(2000.0, 0.5 * dhFarPlane);
#else
	const float SkyFar = 2000.0;
#endif

#ifdef WORLD_SKY_ENABLED
	const float AirDensityRainF = AirDensityF; //0.05;
	const float AirScatterRainF = 0.48;
	const float AirExtinctRainF = 0.24;

	const float AirAmbientF = 0.02;//mix(0.02, 0.0, skyRainStrength);
	// float AirScatterF = 0.32;//mix(1.00, 0.028, skyRainStrength);
	const vec3 AirScatterColor = _RGBToLinear(vec3(0.596, 0.689, 0.722));
	// float AirExtinctF = 0.06;//mix(0.02, 0.006, skyRainStrength);
	const vec3 AirExtinctColor = 1.0 - _RGBToLinear(vec3(0.955, 0.942, 0.917));//mix(0.02, 0.006, skyRainStrength);
#else
	vec3 AirAmbientF = RGBToLinear(fogColor);

	float AirScatterF = 0.07;
	float AirExtinctF = 0.02;
#endif


float GetSkyDensity(const in float worldY) {
    return AirDensityF * (1.0 - smoothstep(62.0, 420.0, worldY));
}
