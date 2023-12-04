const float phaseAir = phaseIso;

#ifdef WORLD_SKY_ENABLED
	const float AirAmbientF = 0.0;//mix(0.08, 0.02, skyRainStrength);

	float AirScatterF = mix(0.008, 0.028, skyRainStrength);
	float AirExtinctF = mix(0.003, 0.008, skyRainStrength);
#else
	vec3 tint = RGBToLinear(fogColor);// * 0.8 + 0.08;

	const vec3 AirAmbientF = tint;

	float AirScatterF = 0.09;// * tint;
	float AirExtinctF = 0.04;
#endif
