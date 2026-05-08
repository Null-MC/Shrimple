#ifdef WRITE_SCENE
    #define SCENE_ATTR
#else
    #define SCENE_ATTR readonly
#endif

layout(std430, binding = 0) SCENE_ATTR buffer sceneData {
    vec3 skyLightColor;
    float WavingAnimF;
    float WavingAnimLastF;
} scene;
