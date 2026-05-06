#ifdef WRITE_SCENE
    #define SCENE_ATTR writeonly
#else
    #define SCENE_ATTR readonly
#endif

layout(std430, binding = 0) SCENE_ATTR buffer sceneData {
    vec3 skyLightColor;
} scene;
