#ifdef RENDER_TRANSLUCENT
    layout(location = 0) out vec4 outFinal;
    layout(location = 1) out vec3 outTint;

    #ifdef DEFERRED_NORMAL_ENABLED // defined(LIGHTING_REFLECT_ENABLED) || defined(PHOTONICS_LIGHT_ENABLED)
        layout(location = 2) out uvec2 outNormal;

        #ifdef DEFERRED_SPECULAR_ENABLED
            /* RENDERTARGETS: 1,2,4,3 */
            layout(location = 3) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 1,2,4 */
        #endif
    #else
        /* RENDERTARGETS: 1,2 */
    #endif
#else
    layout(location = 0) out vec4 outFinal;

    #ifdef DEFERRED_NORMAL_ENABLED // defined(LIGHTING_REFLECT_ENABLED) || defined(PHOTONICS_LIGHT_ENABLED)
        layout(location = 1) out uvec2 outNormal;

        #ifdef DEFERRED_SPECULAR_ENABLED
            /* RENDERTARGETS: 0,4,3 */
            layout(location = 2) out uvec2 outAlbedoSpecular;
        #else
            /* RENDERTARGETS: 0,4 */
        #endif
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif
