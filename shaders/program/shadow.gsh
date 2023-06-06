#define RENDER_SHADOW
#define RENDER_GEOMETRY

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

in vec4 vColor[3];
in vec2 vTexcoord[3];
flat in int vBlockId[3];
flat in vec3 vOriginPos[3];

out vec2 gTexcoord;
out vec4 gColor;
flat out uint gBlockId;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    flat out vec2 gShadowTilePos;
#endif

uniform int renderStage;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float far;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform float near;
    //uniform float far;
#endif

#include "/lib/blocks.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/entities.glsl"
    #include "/lib/items.glsl"
    
    #include "/lib/buffers/lighting.glsl"
    //#include "/lib/lighting/blackbody.glsl"
    //#include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    //#include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    //#include "/lib/lighting/voxel/entities.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
    #endif
#endif


#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    // returns: tile [0-3] or -1 if excluded
    int GetShadowRenderTile(const in vec3 blockPos) {
        //#ifdef SHADOW_CSM_FITRANGE
        //    const int max = 3;
        //#else
            const int max = 4;
        //#endif

        for (int i = 0; i < max; i++) {
            if (CascadeContainsPosition(blockPos, i, 3.0)) return i;
        }

        //#ifdef SHADOW_CSM_FITRANGE
        //    return 3;
        //#else
            return -1;
        //#endif
    }
#endif

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        bool intersectsShadow = true;
        vec3 originPos = (vOriginPos[0] + vOriginPos[1] + vOriginPos[2]) / 3.0;

        #ifdef SHADOW_FRUSTUM_CULL
            if (vBlockId[0] > 0) {
                vec2 lightViewPos = (shadowModelViewEx * vec4(originPos, 1.0)).xy;

                if (clamp(lightViewPos, shadowViewBoundsMin, shadowViewBoundsMax) != lightViewPos) return;
            }
        #endif

        if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES && vBlockId[0] > 0) {
            vec3 cf = fract(cameraPosition);
            vec3 lightGridOrigin = floor(originPos + cf) - cf + 0.5;

            ivec3 gridCell, blockCell;
            vec3 gridPos = GetLightGridPosition(lightGridOrigin);
            if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                uint gridIndex = GetSceneLightGridIndex(gridCell);
                bool intersectsLight = true;

                #ifdef DYN_LIGHT_FRUSTUM_TEST
                    vec3 lightViewPos = (gbufferModelView * vec4(originPos, 1.0)).xyz;

                    const float viewPad = 1.0;
                    if (lightViewPos.z > viewPad) intersectsLight = false;
                    else if (lightViewPos.z < -(far + viewPad)) intersectsLight = false;
                    else {
                        if (dot(sceneViewUp,   lightViewPos) > viewPad) intersectsLight = false;
                        if (dot(sceneViewDown, lightViewPos) > viewPad) intersectsLight = false;
                        if (dot(sceneViewLeft,  lightViewPos) > viewPad) intersectsLight = false;
                        if (dot(sceneViewRight, lightViewPos) > viewPad) intersectsLight = false;
                    }
                #endif

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                    if (intersectsLight && !IsTraceEmptyBlock(vBlockId[0]))
                        SetSceneBlockMask(blockCell, gridIndex, vBlockId[0]);
                #endif
            }
        }
        // else if (renderStage == MC_RENDER_STAGE_ENTITIES) {
        //     if (entityId == ENTITY_LIGHTNING_BOLT) return;

        //     #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        //         if (entityId == ENTITY_PLAYER) {
        //             for (int i = 0; i < 3; i++) {
        //                 if (vVertexId[i] % 600 == 300) {
        //                     HandLightPos1 = (shadowModelViewInverse * gl_in[i].gl_Position).xyz;
        //                 }
        //             }

        //             if (vVertexId[0] == 5) {
        //                 HandLightPos2 = (shadowModelViewInverse * gl_in[0].gl_Position).xyz;
        //             }
        //         }
        //     #endif

        //     // vec4 light = GetSceneEntityLightColor(entityId, vVertexId);
        //     // if (light.a > EPSILON) {
        //     //     AddSceneBlockLight(0, vOriginPos[0], light.rgb, light.a);
        //     // }
        // }

        if (!intersectsShadow) return;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        vec3 originShadowViewPos = (shadowModelViewEx * vec4(vOriginPos[0], 1.0)).xyz;

        // #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        //     if (!all(greaterThan(originShadowViewPos.xy, shadowViewBoundsMin))
        //      || !all(lessThan(originShadowViewPos.xy, shadowViewBoundsMax))) return;
        // #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            int shadowTile = GetShadowRenderTile(originShadowViewPos);
            if (shadowTile < 0) return;

            #ifdef SHADOW_CSM_OVERLAP
                int cascadeMin = max(shadowTile - 1, 0);
                int cascadeMax = min(shadowTile + 1, 3);
            #else
                int cascadeMin = shadowTile;
                int cascadeMax = shadowTile;
            #endif

            for (int c = cascadeMin; c <= cascadeMax; c++) {
                if (c != shadowTile) {
                    #ifdef SHADOW_CSM_OVERLAP
                        // duplicate geometry if intersecting overlapping cascades
                        if (!CascadeContainsPosition(originShadowViewPos, c, 9.0)) continue;
                    #else
                        continue;
                    #endif
                }

                vec2 shadowTilePos = shadowProjectionPos[c];

                for (int v = 0; v < 3; v++) {
                    gShadowTilePos = shadowTilePos;

                    gTexcoord = vTexcoord[v];
                    gColor = vColor[v];
                    gBlockId = vBlockId[v];

                    gl_Position = cascadeProjection[c] * gl_in[v].gl_Position;

                    gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
                    gl_Position.xy = gl_Position.xy * 0.5 + shadowTilePos;
                    gl_Position.xy = gl_Position.xy * 2.0 - 1.0;

                    EmitVertex();
                }

                EndPrimitive();
            }
        #else
            for (int v = 0; v < 3; v++) {
                gTexcoord = vTexcoord[v];
                gColor = vColor[v];
                gBlockId = vBlockId[v];

                #ifdef IRIS_FEATURE_SSBO
                    gl_Position = shadowProjectionEx * gl_in[v].gl_Position;
                #else
                    gl_Position = gl_ProjectionMatrix * gl_in[v].gl_Position;
                #endif

                gl_Position.xyz = distort(gl_Position.xyz);

                EmitVertex();
            }

            EndPrimitive();
        #endif
    #endif
}
