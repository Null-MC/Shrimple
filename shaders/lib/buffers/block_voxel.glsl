#if defined RENDER_SHADOWCOMP || defined RENDER_GBUFFER
    layout(r16ui) uniform uimage2D imgLocalBlockMask;
#elif defined RENDER_BEGIN || defined RENDER_GEOMETRY || defined RENDER_VERTEX
    layout(r16ui) uniform writeonly uimage2D imgLocalBlockMask;
#else
    layout(r16ui) uniform readonly uimage2D imgLocalBlockMask;
#endif
