const float Water_FlowSpeedF = WATER_FLOW_SPEED * 0.01;
const vec2 Water_AnimSpeed = vec2(3.0, 5.0) * Water_FlowSpeedF;


vec3 GetWaterBumpTexcoord(in vec3 texPos, const vec3 localNormal, const in float animOffset) {
	float nm = max(abs(localNormal.y), 0.0);

	texPos.xz -= animOffset * (localNormal.xz * localNormal.y);

	texPos.y += animOffset * ((1.0 - _pow2(nm))*0.96 + 0.04);

	return texPos;
}

float SampleWaterBump(const in vec3 worldPos, const vec3 localNormal) {
	vec2 animOffset = Water_AnimSpeed * frameTimeCounter;

	vec3 texPos0 = worldPos;
	texPos0.y *= 3.0;

	vec3 texPos1 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.x);
	vec3 texPos2 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.y);

	float minF = 0.7*textureLod(texClouds, 0.02*texPos0.xzy, 0).r;
	minF += 0.3*textureLod(texClouds, 0.09*texPos0.xzy, 0).r;
	minF = smoothstep(0.5, 1.0, minF);
	//sampleF = sqrt(sampleF);

	float nm = max(abs(localNormal.y), 0.0);
    float strength = 1.0 - max(nm*16.0-15.0, 0.0);
    // float strength = 1.0 - pow(nm, 8.0);
	// minF = mix(minF, 1.0, strength);
	minF = strength;

	// sampleF = smoothstep(0.99 - 0.99*strength, 1.0, sampleF);

	float sampleF = textureLod(texClouds, 0.1*texPos1.xzy, 0).r;
	sampleF *= textureLod(texClouds, 0.3*texPos2.xzy, 0).r;
	// sampleF = smoothstep(0.8, 0.4, sampleF);
	// sampleF = 1.0 - sampleF;
	// sampleF = _pow2(sampleF);

	return minF * sampleF;
}

float SampleWaterFoam(const in vec3 worldPos, const vec3 localNormal) {
	vec2 animOffset = Water_AnimSpeed * frameTimeCounter;

	vec3 texPos0 = worldPos;
	// texPos0.y *= 3.0;

	vec3 texPos1 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.x);
	vec3 texPos2 = GetWaterBumpTexcoord(texPos0, localNormal, animOffset.y);

	texPos1.y *= 0.2;
	texPos2.y *= 0.2;

	// texPos.xz -= Water_AnimSpeed * (localNormal.xz * localNormal.y) * frameTimeCounter;


	// texPos.y += Water_AnimSpeed * ((1.0 - _pow2(nm))*0.96 + 0.04) * frameTimeCounter;

	float minF = textureLod(texClouds, 0.02*texPos1.xzy, 0).r;
	minF *= textureLod(texClouds, 0.09*texPos2.xzy, 0).r;
	// minF = smoothstep(0.5, 1.0, minF);
	minF = sqrt(minF);

	float nm = max(abs(localNormal.y), 0.0);
    float strength = 1.0 - max(nm*8.0-7.0, 0.0);
	minF = mix(minF, 1.0, strength);

	// sampleF = smoothstep(0.99 - 0.99*strength, 1.0, sampleF);

	float sampleF = textureLod(texClouds, 0.2*texPos1.xzy, 0).r;
	sampleF *= 1.0 - textureLod(texClouds, 0.5*texPos2.xzy, 0).r;
	// sampleF = smoothstep(0.8, 0.4, sampleF);
	// sampleF = _pow2(sampleF);

	return minF * sampleF;
}
