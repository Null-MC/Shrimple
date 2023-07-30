//const vec3 WaterAbsorbColor = vec3(0.416, 0.667, 0.712);
//vec3 WaterAbsorbColorInv = 1.0*RGBToLinear(1.0 - WaterAbsorbColor);
vec3 WaterAbsorbColorInv = RGBToLinear(1.0 - WaterAbsorbColor);

//const vec3 WaterScatterColor = vec3(0.453, 0.598, 0.636);
//vec3 vlWaterScatterColorL = 0.18*RGBToLinear(WaterScatterColor);
vec3 vlWaterScatterColorL = RGBToLinear(WaterScatterColor);
