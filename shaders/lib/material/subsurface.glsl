#ifdef RENDER_ENTITIES
    float GetEntitySSS(const in int entityId) {
        float sss = 0.0;

        switch (entityId) {
            case ENTITY_SLIME:
                sss = 0.9;
                break;
        }

        return sss;
    }
#endif

#ifdef RENDER_FRAG
    float GetMaterialSSS(const in int id, const in vec2 texcoord, const in float mip) {
        float sss = 0.0;

        #ifdef RENDER_ENTITIES
            if (entityId == ENTITY_PHYSICSMOD_SNOW) return 0.8;
        #endif

        #if MATERIAL_SSS == SSS_LABPBR
            sss = textureLod(specular, texcoord, mip).b;
            sss = max(sss - 0.25, 0.0) / 0.75;
        #elif MATERIAL_SSS == SSS_DEFAULT
            int materialId = id;
            #if (defined RENDER_HAND || defined RENDER_ENTITIES) && defined IS_IRIS
                if (currentRenderedItemId > 0)
                    materialId = currentRenderedItemId;
            #endif

            #ifdef RENDER_HAND
                sss = StaticBlockMap[materialId].materialSSS;
            #elif defined RENDER_TERRAIN || defined RENDER_WATER
                sss = StaticBlockMap[materialId].materialSSS;
            #elif defined RENDER_ENTITIES
                sss = GetEntitySSS(materialId);
            #endif
        #endif

        return sss;
    }
#endif
