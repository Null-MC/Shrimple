const float WaterAmbientF = 0.2;
float WaterDensityF = waterDensitySmooth * Water_DensityF;
vec3 WaterScatterF = _RGBToLinear(WaterScatterColor);
vec3 WaterAbsorbF = _RGBToLinear(1.0 - WaterAbsorbColor);

const float WaterAmbientDepth = 2.0;


#if WATER_WAVE_SIZE == 3
	const float Water_WaveStrength = 1.00;
	const float Water_CausticStrength = 1.00;
#elif WATER_WAVE_SIZE == 2
	const float Water_WaveStrength = 0.50;
	const float Water_CausticStrength = 0.80;
#elif WATER_WAVE_SIZE == 1
	const float Water_WaveStrength = 0.25;
	const float Water_CausticStrength = 0.50;
#else
	const float Water_WaveStrength = 0.00;
	const float Water_CausticStrength = 0.00;
#endif


// float GetWaterPhase(const in float VoL) {return DHG(VoL, -0.12, 0.68, 0.24);}
