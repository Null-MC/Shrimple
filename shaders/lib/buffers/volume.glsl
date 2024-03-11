#ifdef RENDER_COMPOSITE_LPV
	layout(rgba8) uniform image3D imgSceneLPV_1;
	layout(rgba8) uniform image3D imgSceneLPV_2;
#elif defined RENDER_GEOMETRY || defined RENDER_VERTEX
	layout(rgba8) uniform writeonly image3D imgSceneLPV_1;
	layout(rgba8) uniform writeonly image3D imgSceneLPV_2;
#else
	layout(rgba8) uniform readonly image3D imgSceneLPV_1;
	layout(rgba8) uniform readonly image3D imgSceneLPV_2;
#endif
