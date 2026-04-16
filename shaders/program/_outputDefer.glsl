layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outNormals;
layout(location = 2) out uvec2 outSpecularMeta;

#ifdef VELOCITY_ENABLED
    /* RENDERTARGETS: 4,5,6,3 */
    layout(location = 3) out vec3 outVelocity;
#else
    /* RENDERTARGETS: 4,5,6 */
#endif
