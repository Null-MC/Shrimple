#ifdef RENDER_COMPOSITE_LPV
	layout(rgba16f) uniform restrict image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict image3D imgSceneLPV_2;
#elif defined RENDER_GEOMETRY || defined RENDER_VERTEX
	layout(rgba16f) uniform restrict writeonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict writeonly image3D imgSceneLPV_2;
#else
	layout(rgba16f) uniform restrict readonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict readonly image3D imgSceneLPV_2;
#endif
