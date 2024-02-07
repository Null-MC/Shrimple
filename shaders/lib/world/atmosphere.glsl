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
	float AirDensityF = mix(SkyDensityF, max(SkyDensityF, 0.04), skyRainStrength);

	const float AirDensityRainF = 0.04;
	const vec3 AirScatterColor_rain = _RGBToLinear(vec3(0.565, 0.561, 0.612));
	const vec3 AirExtinctColor_rain = _RGBToLinear(vec3(0.580, 0.553, 0.522));

	const float AirAmbientF = 0.02;//mix(0.02, 0.0, skyRainStrength);
	const vec3 AirScatterColor = _RGBToLinear(vec3(0.455, 0.553, 0.612));
	const vec3 AirExtinctColor = _RGBToLinear(1.0 - vec3(0.831, 0.796, 0.745));//mix(0.02, 0.006, skyRainStrength);
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
    return DHG(VoL, -0.22, 0.78, 0.44);
}
