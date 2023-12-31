const vec2 taa_offsets[16] = vec2[](
	vec2(0.500000, 0.333333),
	vec2(0.250000, 0.666667),
	vec2(0.750000, 0.111111),
	vec2(0.125000, 0.444444),
	vec2(0.625000, 0.777778),
	vec2(0.375000, 0.222222),
	vec2(0.875000, 0.555556),
	vec2(0.062500, 0.888889),
	vec2(0.562500, 0.037037),
	vec2(0.312500, 0.370370),
	vec2(0.812500, 0.703704),
	vec2(0.187500, 0.148148),
	vec2(0.687500, 0.481481),
	vec2(0.437500, 0.814815),
	vec2(0.937500, 0.259259),
	vec2(0.031250, 0.592593));


vec2 getJitterOffset(const in int frameOffset) {
	return (taa_offsets[frameOffset % 16] * 2.0 - 1.0) * pixelSize;
}

void jitter(inout vec4 ndcPos) {
	ndcPos.xy += getJitterOffset(frameCounter) * ndcPos.w;
}
