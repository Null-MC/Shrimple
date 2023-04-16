#if defined RENDER_SETUP || defined RENDER_BEGIN || defined RENDER_SHADOW
    layout(std430, binding = 0) buffer sceneData
#else
    layout(std430, binding = 0) readonly buffer sceneData
#endif
{
    mat3 matColorPost;      // 36
};
