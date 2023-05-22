#ifdef RENDER_SHADOWCOMP_LPV
	layout(rgba16f) uniform restrict image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict image3D imgSceneLPV_2;
#elif defined RENDER_SHADOWCOMP_LIGHT_POPULATE
	layout(rgba16f) uniform restrict writeonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict writeonly image3D imgSceneLPV_2;
#else
	layout(rgba16f) uniform restrict readonly image3D imgSceneLPV_1;
	layout(rgba16f) uniform restrict readonly image3D imgSceneLPV_2;
#endif
