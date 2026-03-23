layout(location = 0) out vec4 outFinal;
layout(location = 1) out uint outMeta;

#ifdef RENDER_TRANSLUCENT
    layout(location = 2) out vec4 outTint;

    #ifdef TAA_ENABLED
        layout(location = 3) out vec3 outVelocity;

        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 1,8,2,6,4,3 */
            layout(location = 4) out vec4 outNormal;
            layout(location = 5) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 1,8,2,6 */
        #endif
    #else
        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 1,8,2,4,3 */
            layout(location = 3) out vec4 outNormal;
            layout(location = 4) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 1,8,2 */
        #endif
    #endif
#else
    #ifdef TAA_ENABLED
        layout(location = 2) out vec3 outVelocity;

        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 0,8,6,4,3 */
            layout(location = 3) out vec4 outNormal;
            layout(location = 4) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 0,8,6 */
        #endif
    #else
        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 0,8,4,3 */
            layout(location = 2) out vec4 outNormal;
            layout(location = 3) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 0,8 */
        #endif
    #endif
#endif
