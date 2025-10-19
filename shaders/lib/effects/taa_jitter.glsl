void jitter(inout vec4 ndcPos) {
	ndcPos.xy += 2.0 * taa_offset * ndcPos.w;
}
