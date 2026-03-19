layout(location = 0) out vec4 outFinal;

#ifdef RENDER_TRANSLUCENT
    layout(location = 1) out vec3 outTint;

    #ifdef TAA_ENABLED
        layout(location = 2) out vec3 outVelocity;

        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 1,2,6,4,3 */
            layout(location = 3) out vec4 outNormal;
            layout(location = 4) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 1,2,6 */
        #endif
    #else
        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 1,2,4,3 */
            layout(location = 2) out vec4 outNormal;
            layout(location = 3) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 1,2 */
        #endif
    #endif
#else
    #ifdef TAA_ENABLED
        layout(location = 1) out vec3 outVelocity;

        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 0,6,4,3 */
            layout(location = 2) out vec4 outNormal;
            layout(location = 3) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 0,6 */
        #endif
    #else
        #ifdef DEFERRED_ENABLED
            /* RENDERTARGETS: 0,4,3 */
            layout(location = 1) out vec4 outNormal;
            layout(location = 2) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 0 */
        #endif
    #endif
#endif
