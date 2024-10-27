#ifdef RENDER_COMPOSITE_LPV
	layout(rgba16f) uniform image3D imgIndirectLpv_1;
	layout(rgba16f) uniform image3D imgIndirectLpv_2;
#else
	layout(rgba16f) uniform readonly image3D imgIndirectLpv_1;
	layout(rgba16f) uniform readonly image3D imgIndirectLpv_2;
#endif
