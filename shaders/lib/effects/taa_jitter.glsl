#if EFFECT_TAA_MAX_ACCUM <= 4
	#define EFFECT_TAA_MAX_FRAMES 4

	const vec2 taa_offsets[4] = vec2[](
		vec2(0.375, 0.125),
		vec2(0.875, 0.375),
		vec2(0.125, 0.625),
		vec2(0.625, 0.875));
#elif EFFECT_TAA_MAX_ACCUM <= 8
	#define EFFECT_TAA_MAX_FRAMES 8

	const vec2 taa_offsets[8] = vec2[](
		vec2(0.5625, 0.3125),
		vec2(0.4375, 0.6875),
		vec2(0.8125, 0.5625),
		vec2(0.3125, 0.1875),
		vec2(0.1875, 0.8125),
		vec2(0.0625, 0.4375),
		vec2(0.6875, 0.9375),
		vec2(0.9375, 0.0625));
#else
	#define EFFECT_TAA_MAX_FRAMES 16

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
#endif


vec2 getJitterOffset(const in int frameOffset) {
	return (taa_offsets[frameOffset % EFFECT_TAA_MAX_FRAMES] - 0.5) * pixelSize;
}

void jitter(inout vec4 ndcPos) {
	vec2 offset = getJitterOffset(frameCounter);
	ndcPos.xy += 2.0 * offset * ndcPos.w;
}
