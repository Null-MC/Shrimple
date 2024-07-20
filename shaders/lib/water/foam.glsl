const float Water_FlowSpeedF = WATER_FLOW_SPEED * 0.01;
const vec2 Water_AnimSpeed = vec2(3.0, 5.0) * Water_FlowSpeedF;


vec3 GetWaterBumpTexcoord(in vec3 texPos, const vec3 localNormal, const in float animOffset) {
	// float nm = max(abs(localNormal.y), 0.0);
	float nm = abs(localNormal.y);

	texPos.xz -= animOffset * (localNormal.xz * nm);

	texPos.y += animOffset * ((1.0 - _pow2(nm))*0.96 + 0.04);

	return texPos;
}

float SampleWaterBump(const in vec3 worldPos, const vec3 localNormal) {
	vec2 animOffset = Water_AnimSpeed * frameTimeCounter;

	vec3 texPos0 = worldPos;
	// texPos0.y *= 3.0;

	vec3 texPos1 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.x);
	vec3 texPos2 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.y);

	texPos1.y *= 0.4;
	texPos2.y *= 0.4;

	float minF = 0.7*textureLod(texClouds, 0.02*texPos0.xzy, 0).r;
	minF += 0.3*textureLod(texClouds, 0.09*texPos0.xzy, 0).r;
	minF = smoothstep(0.5, 1.0, minF);

	float nm = abs(localNormal.y);
    float strength = 1.0 - max(nm*16.0-15.0, 0.0);
	minF = strength;

	float sampleF = textureLod(texClouds, 0.1*texPos1.xzy, 0).r;
	sampleF *= textureLod(texClouds, 0.3*texPos2.xzy, 0).r;

	return minF * sampleF;
}

float SampleWaterFoam(const in vec3 worldPos, const vec3 localNormal) {
	vec2 animOffset = Water_AnimSpeed * frameTimeCounter;

	vec3 texPos1 = GetWaterBumpTexcoord(worldPos, localNormal, animOffset.x);
	vec3 texPos2 = GetWaterBumpTexcoord(worldPos, localNormal, animOffset.y);

	texPos1.y *= 0.4;
	texPos2.y *= 0.4;

	float minF = textureLod(texClouds, 0.02*texPos1.xzy, 0).r;
	minF *= textureLod(texClouds, 0.09*texPos2.xzy, 0).r;
	// minF = sqrt(minF);

	float nm = max(abs(localNormal.y), 0.0);
    float strength = 1.0 - max(nm*8.0-7.0, 0.0);
	minF = mix(minF, 1.0, strength);

	float sampleF = textureLod(texClouds, 0.2*texPos1.xzy, 0).r;
	sampleF *= 1.0 - textureLod(texClouds, 0.5*texPos2.xzy, 0).r;

	return minF * sampleF;
}
