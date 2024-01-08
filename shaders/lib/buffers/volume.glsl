#ifdef RENDER_COMPOSITE_LPV
	layout(rgba16f) uniform image3D imgSceneLPV_1;
	layout(rgba16f) uniform image3D imgSceneLPV_2;
#elif defined RENDER_GEOMETRY || defined RENDER_VERTEX
	layout(rgba16f) uniform writeonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform writeonly image3D imgSceneLPV_2;
#else
	layout(rgba16f) uniform readonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform readonly image3D imgSceneLPV_2;
#endif
