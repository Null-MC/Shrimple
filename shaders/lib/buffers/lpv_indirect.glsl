#ifdef RENDER_COMPOSITE_LPV
	layout(rgba8) uniform image3D imgIndirectLpv_1;
	layout(rgba8) uniform image3D imgIndirectLpv_2;
#else
	layout(rgba8) uniform readonly image3D imgIndirectLpv_1;
	layout(rgba8) uniform readonly image3D imgIndirectLpv_2;
#endif
