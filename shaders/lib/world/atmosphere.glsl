const float phaseAir = 0.25;

#ifdef WORLD_SKY_ENABLED
	const float AirAmbientF = mix(0.002, 0.008, skyRainStrength);

	float AirScatterF = mix(0.006, 0.016, skyRainStrength);
	float AirExtinctF = mix(0.002, 0.008, skyRainStrength);
#else
	vec3 tint = RGBToLinear(fogColor);// * 0.8 + 0.08;

	const vec3 AirAmbientF = tint;

	float AirScatterF = 0.09;// * tint;
	float AirExtinctF = 0.04;
#endif
