const float SkyFar = 2000.0;
const float AirDensityF = SKY_DENSITY * 0.01;
const float phaseAir = phaseIso;

#ifdef WORLD_SKY_ENABLED
	const float AirDensityRainF = AirDensityF; //0.05;
	const float AirScatterRainF = 0.48;
	const float AirExtinctRainF = 0.48;

	float AirAmbientF = 0.02;//mix(0.02, 0.0, skyRainStrength);
	float AirScatterF = 0.32;//mix(1.00, 0.028, skyRainStrength);
	float AirExtinctF = 0.06;//mix(0.02, 0.006, skyRainStrength);
#else
	vec3 tint = RGBToLinear(fogColor);// * 0.8 + 0.08;

	const vec3 AirAmbientF = tint;

	float AirScatterF = 0.07;// * tint;
	float AirExtinctF = 0.02;
#endif


float GetSkyDensity(const in float worldY) {
    return AirDensityF * (1.0 - smoothstep(62.0, 420.0, worldY));
}
