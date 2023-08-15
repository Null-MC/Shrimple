//const vec3 WaterAbsorbColor = vec3(0.416, 0.667, 0.712);
//vec3 WaterAbsorbColorInv = 1.0*RGBToLinear(1.0 - WaterAbsorbColor);
vec3 WaterAbsorbColorInv = RGBToLinear(1.0 - WaterAbsorbColor);

//const vec3 WaterScatterColor = vec3(0.453, 0.598, 0.636);
//vec3 vlWaterScatterColorL = 0.18*RGBToLinear(WaterScatterColor);
vec3 vlWaterScatterColorL = RGBToLinear(WaterScatterColor);


#if WORLD_WATER_WAVES == 3
	const float Water_WaveStrength = 1.00;
	const float Water_CausticStrength = 1.00;
#elif WORLD_WATER_WAVES == 2
	const float Water_WaveStrength = 0.50;
	const float Water_CausticStrength = 0.50;
#elif WORLD_WATER_WAVES == 1
	const float Water_WaveStrength = 0.25;
	const float Water_CausticStrength = 0.25;
#else
	const float Water_WaveStrength = 0.00;
	const float Water_CausticStrength = 0.00;
#endif
