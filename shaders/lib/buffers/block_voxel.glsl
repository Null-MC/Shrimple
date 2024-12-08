#if defined RENDER_SHADOWCOMP || defined RENDER_GBUFFER
    // layout(r16ui) uniform uimage2D imgLocalBlockMask;
    layout(r16ui) uniform uimage3D imgVoxels;
#elif defined RENDER_BEGIN || defined RENDER_GEOMETRY || defined RENDER_VERTEX
    // layout(r16ui) uniform writeonly uimage2D imgLocalBlockMask;
    layout(r16ui) uniform writeonly uimage3D imgVoxels;
#else
    // layout(r16ui) uniform readonly uimage2D imgLocalBlockMask;
    layout(r16ui) uniform readonly uimage3D imgVoxels;
#endif
