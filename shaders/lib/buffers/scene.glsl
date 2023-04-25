#if defined RENDER_SETUP || defined RENDER_BEGIN
    layout(std430, binding = 0) buffer sceneData
#else
    layout(std430, binding = 0) readonly buffer sceneData
#endif
{
    vec3 localSunDirection; // 12
    mat4 gbufferModelViewProjectionInverse; // 64
    mat3 matColorPost;      // 36
};
