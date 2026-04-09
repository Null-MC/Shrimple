layout(location = 0) out vec4 outFinal;
//layout(location = 1) out vec4 outTint;
layout(location = 1) out vec4 outAlbedo;

#ifdef DEFERRED_ENABLED
    layout(location = 2) out vec4 outNormals;
    layout(location = 3) out uvec2 outSpecularMeta;

    #ifdef VELOCITY_ENABLED
        layout(location = 4) out vec3 outVelocity;
        /* RENDERTARGETS: 1,4,5,6,3 */
    #else
        /* RENDERTARGETS: 1,4,5,6 */
    #endif
#else
    #ifdef VELOCITY_ENABLED
        layout(location = 2) out vec3 outVelocity;
        /* RENDERTARGETS: 1,2,3 */
    #else
        /* RENDERTARGETS: 1,2 */
    #endif
#endif
