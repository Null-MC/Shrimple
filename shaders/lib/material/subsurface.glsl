float GetMaterialSSS(const in int blockId, const in vec2 texcoord) {
    float sss = 0.0;

    #if MATERIAL_SSS == SSS_LABPBR
        sss = texture(specular, texcoord).b;
        sss = max(sss - 0.25, 0.0) / 0.75;
    #elif MATERIAL_SSS == SSS_DEFAULT
        #if defined RENDER_TERRAIN || defined RENDER_WATER
            sss = GetBlockSSS(blockId);
        #elif defined RENDER_ENTITIES
            sss = GetEntitySSS(entityId);
        #endif
    #endif

    return sss;
}
