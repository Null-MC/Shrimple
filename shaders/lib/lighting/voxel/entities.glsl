// #ifdef RENDER_VERTEX
//     int GetWrappedVertexID(const in int entityId) {
//         int vertexId = -1;

//         switch (entityId) {
//             case ENTITY_BLAZE:
//                 const int BlazeVertexCount = 312;
//                 vertexId = int(mod(gl_VertexID, BlazeVertexCount));
//                 break;
//             case ENTITY_MAGMA_CUBE:
//                 const int MagmaCubeVertexCount = 216;
//                 vertexId = int(mod(gl_VertexID, MagmaCubeVertexCount));
//                 break;
//             case ENTITY_END_CRYSTAL:
//                 const int EndCrystalVertexCount = 72;
//                 vertexId = int(mod(gl_VertexID, EndCrystalVertexCount));
//                 break;
//             case ENTITY_TNT:
//                 const int TNTVertexCount = 24;
//                 vertexId = int(mod(gl_VertexID, TNTVertexCount));
//                 break;
//         }

//         return vertexId;
//     }
// #endif

vec4 GetSceneEntityLightColor(const in int entityId) {
    vec4 colorRange = vec4(0.0);
    
    switch (entityId) {
        case ENTITY_ALLAY:
            colorRange.rgb = RGBToLinear(vec3(0.169, 0.792, 0.871));
            colorRange.a = 4.0;
            break;
        case ENTITY_BLAZE:
            colorRange.rgb = RGBToLinear(vec3(0.813, 0.583, 0.180));
            colorRange.a = 8.0;
            break;
        case ENTITY_END_CRYSTAL:
            colorRange.rgb = RGBToLinear(vec3(0.848, 0.165, 0.724));
            colorRange.a = 15.0;
            break;
        case ENTITY_FLAMES:
            colorRange.rgb = RGBToLinear(vec3(0.851, 0.518, 0.239));
            colorRange.a = 15.0;
            break;
        case ENTITY_GLOW_SQUID:
            colorRange.rgb = RGBToLinear(vec3(0.333, 0.851, 0.839));
            colorRange.a = 6.0;
            break;
        case ENTITY_MAGMA_CUBE:
            colorRange.rgb = RGBToLinear(vec3(0.707, 0.373, 0.157));
            colorRange.a = 12.0;
            break;
        case ENTITY_TNT:
            colorRange.rgb = RGBToLinear(vec3(1.0));
            colorRange.a = 5.0 * entityColor.a + 2.0;
            break;
    }

    return colorRange;
}

// vec4 GetSceneEntityLightColor(const in int entityId, const in int vertexId[3]) {
//     bool match = false;

//     switch (entityId) {
//         case ENTITY_BLAZE:
//             const int BlazeVertexId = 300;
//             match = vertexId[0] == BlazeVertexId || vertexId[1] == BlazeVertexId || vertexId[2] == BlazeVertexId;
//             break;
//         case ENTITY_MAGMA_CUBE:
//             const int MagmaCubeVertexId = 20;
//             match = vertexId[0] == MagmaCubeVertexId || vertexId[1] == MagmaCubeVertexId || vertexId[2] == MagmaCubeVertexId;
//             break;
//         case ENTITY_END_CRYSTAL:
//             const int EndCrystalVertexId = 0;
//             match = vertexId[0] == EndCrystalVertexId || vertexId[1] == EndCrystalVertexId || vertexId[2] == EndCrystalVertexId;
//             break;
//         case ENTITY_TNT:
//             const int TNTVertexId = 16;
//             match = vertexId[0] == TNTVertexId || vertexId[1] == TNTVertexId || vertexId[2] == TNTVertexId;
//             break;
//     }

//     if (!match) return vec4(0.0);
//     return GetSceneEntityLightColor(entityId);
// }
