const float AirDensityF = SKY_DENSITY * 0.01;
const float phaseAir = phaseIso;

#ifdef DISTANT_HORIZONS
	float SkyFar = max(2000.0, 0.5 * dhFarPlane);
#else
	const float SkyFar = 2000.0;
#endif

#ifdef WORLD_SKY_ENABLED
	const float AirDensityRainF = AirDensityF; //0.05;
	const vec3 AirScatterColor_rain = _RGBToLinear(vec3(0.565, 0.561, 0.612));
	const vec3 AirExtinctColor_rain = _RGBToLinear(vec3(0.580, 0.553, 0.522));

	const float AirAmbientF = 0.02;//mix(0.02, 0.0, skyRainStrength);
	const vec3 AirScatterColor = _RGBToLinear(vec3(0.647, 0.694, 0.722));
	const vec3 AirExtinctColor = 1.0 - _RGBToLinear(vec3(0.961, 0.953, 0.941));//mix(0.02, 0.006, skyRainStrength);
#else
	vec3 AirAmbientF = RGBToLinear(fogColor);

	const vec3 AirScatterColor = vec3(0.07);
	const vec3 AirExtinctColor = vec3(0.02);
#endif


float GetSkyDensity(const in float worldY) {
    return AirDensityF * (1.0 - smoothstep(62.0, 420.0, worldY));
}
