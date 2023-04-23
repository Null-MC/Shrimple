#define RENDER_SHADOW
#define RENDER_GEOMETRY

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

in vec2 vTexcoord[3];
in vec4 vColor[3];

flat in vec3 vOriginPos[3];
flat in int vBlockId[3];
flat in int vVertexId[3];

out vec2 gTexcoord;
out vec4 gColor;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    flat out vec2 gShadowTilePos;
#endif

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_COLOR_MODE == DYN_LIGHT_COLOR_RP
        uniform sampler2D gtexture;
    #endif
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform int renderStage;
uniform vec4 entityColor;
uniform int entityId;
uniform float near;
uniform float far;

// #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
//     uniform mat4 shadowModelViewInverse;
// #endif

#if SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/blocks.glsl"
    #include "/lib/entities.glsl"
    #include "/lib/items.glsl"
    
    #include "/lib/buffers/lighting.glsl"
    //#include "/lib/lighting/blackbody.glsl"
    //#include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_lights.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    //#include "/lib/lighting/dynamic_entities.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
         || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
            vec3 lightOrigin = (vOriginPos[0] + vOriginPos[1] + vOriginPos[2]) / 3.0;

            vec3 cf = fract(cameraPosition);
            vec3 lightGridOrigin = floor(lightOrigin + cf) - cf + 0.5;

            // #if DYN_LIGHT_COLOR_MODE == DYN_LIGHT_COLOR_RP
            //     vec3 lightColor = vec3(0.0);
            //     float lightRange = GetSceneBlockLightLevel(vBlockId[0]);
            //     if (lightRange > EPSILON) lightColor = RGBToLinear(textureLod(gtexture, vTexcoord[0], 3).rgb);
            //     AddSceneBlockLight(vBlockId[0], lightOrigin, lightColor, lightRange);
            // #else
            //     AddSceneBlockLight(vBlockId[0], lightOrigin);
            // #endif

            ivec3 gridCell, blockCell;
            vec3 gridPos = GetLightGridPosition(lightGridOrigin);
            if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                uint gridIndex = GetSceneLightGridIndex(gridCell);

                uint lightType = GetSceneLightType(vBlockId[0]);

                bool intersects = true;
                #ifdef DYN_LIGHT_FRUSTUM_TEST
                    vec3 lightViewPos = (gbufferModelView * vec4(lightOrigin, 1.0)).xyz;
                    //float lightRange = GetSceneLightLevel(lightType);

                    const float lightRange = 16.0 * DynamicLightRangeF + 1.0;//lightRange + 1.0;
                    //float maxRange = lightRange > EPSILON ? lightRange : 16.0;
                    if (lightViewPos.z > lightRange) intersects = false;
                    else if (lightViewPos.z < -(far + lightRange)) intersects = false;
                    else {
                        if (dot(sceneViewUp,   lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewDown, lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewLeft,  lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewRight, lightViewPos) > lightRange) intersects = false;
                    }
                #endif

                if (lightType > 0) {
                    if (!intersects) lightType = LIGHT_IGNORED;

                    if (SetSceneLightMask(blockCell, gridIndex, lightType)) {
                        if (intersects) atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
                        #ifdef DYN_LIGHT_DEBUG_COUNTS
                            else atomicAdd(SceneLightMaxCount, 1u);
                        #endif
                    }
                }

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                    if (intersects && IsDynLightSolidBlock(vBlockId[0])) {
                        uint blockType = GetBlockType(vBlockId[0]);
                        SetSceneBlockMask(blockCell, gridIndex, blockType);
                    }
                #endif
            }
        }
        else if (renderStage == MC_RENDER_STAGE_ENTITIES) {
            if (entityId == ENTITY_LIGHTNING_BOLT) return;

            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                if (entityId == ENTITY_PLAYER) {
                    for (int i = 0; i < 3; i++) {
                        if (vVertexId[i] % 600 == 300) {
                            HandLightPos1 = (shadowModelViewInverse * gl_in[i].gl_Position).xyz;
                        }
                    }

                    if (vVertexId[0] == 5) {
                        HandLightPos2 = (shadowModelViewInverse * gl_in[0].gl_Position).xyz;
                    }
                }
            #endif

            // vec4 light = GetSceneEntityLightColor(entityId, vVertexId);
            // if (light.a > EPSILON) {
            //     AddSceneBlockLight(0, vOriginPos[0], light.rgb, light.a);
            // }
        }
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        vec3 originShadowViewPos = (shadowModelView * vec4(vOriginPos[0], 1.0)).xyz;

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            if (!all(greaterThan(originShadowViewPos.xy, shadowViewBoundsMin))
             || !all(lessThan(originShadowViewPos.xy, shadowViewBoundsMax))) return;
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            int shadowTile = GetShadowTile(cascadeProjection, originShadowViewPos);
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
                        if (!CascadeIntersectsPosition(originShadowViewPos, c)) continue;
                    #else
                        continue;
                    #endif
                }

                vec2 shadowTilePos = shadowProjectionPos[c];

                for (int v = 0; v < 3; v++) {
                    gShadowTilePos = shadowTilePos;

                    gTexcoord = vTexcoord[v];
                    gColor = vColor[v];

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

                gl_Position = gl_ProjectionMatrix * gl_in[v].gl_Position;

                #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
                    gl_Position.xyz = distort(gl_Position.xyz);
                #endif

                EmitVertex();
            }

            EndPrimitive();
        #endif
    #endif
}
