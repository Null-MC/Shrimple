float SampleWaterBump(const in vec3 worldPos, const vec3 localNormal) {
	const float AnimSpeed = 2.0;

	float nm = max(abs(localNormal.y), 0.0);

	vec3 texPos = worldPos;
	texPos.y *= 2.0;

	texPos.xz -= AnimSpeed * (localNormal.xz * localNormal.y) * frameTimeCounter;

	texPos.y += AnimSpeed * ((1.0 - _pow2(nm))*0.96 + 0.04) * frameTimeCounter;

	float minF = 0.7*textureLod(texClouds, 0.02*texPos.xzy, 0).r;
	minF += 0.3*textureLod(texClouds, 0.09*texPos.xzy, 0).r;
	minF = smoothstep(0.5, 1.0, minF);
	//sampleF = sqrt(sampleF);

    float strength = 1.0 - max(nm*16.0-15.0, 0.0);
    // float strength = 1.0 - pow(nm, 8.0);
	minF = mix(minF, 1.0, strength);

	// sampleF = smoothstep(0.99 - 0.99*strength, 1.0, sampleF);

	float sampleF = textureLod(texClouds, 0.15*texPos.xzy, 0).r;
	sampleF *= textureLod(texClouds, 0.6*texPos.xzy, 0).r;
	// sampleF = smoothstep(0.8, 0.4, sampleF);
	// sampleF = 1.0 - sampleF;
	// sampleF = _pow2(sampleF);

	return minF * sampleF;
}

float SampleWaterFoam(const in vec3 worldPos, const vec3 localNormal) {
	const float AnimSpeed = 2.0;

	float nm = max(abs(localNormal.y), 0.0);

	vec3 texPos = worldPos;
	texPos.y *= 2.0;

	texPos.xz -= AnimSpeed * (localNormal.xz * localNormal.y) * frameTimeCounter;

	texPos.y += AnimSpeed * ((1.0 - _pow2(nm))*0.96 + 0.04) * frameTimeCounter;

	float minF = 0.7*textureLod(texClouds, 0.02*texPos.xzy, 0).r;
	minF += 0.3*textureLod(texClouds, 0.09*texPos.xzy, 0).r;
	minF = smoothstep(0.5, 1.0, minF);
	//sampleF = sqrt(sampleF);

    float strength = 1.0 - max(nm*8.0-7.0, 0.0);
	minF = mix(minF, 1.0, strength);

	// sampleF = smoothstep(0.99 - 0.99*strength, 1.0, sampleF);

	float sampleF = textureLod(texClouds, 0.15*texPos.xzy, 0).r;
	sampleF *= textureLod(texClouds, 0.6*texPos.xzy, 0).r;
	// sampleF = smoothstep(0.8, 0.4, sampleF);
	sampleF = 1.0 - sampleF;
	sampleF = _pow2(sampleF);

	return minF * sampleF;
}
