#define RENDER_SHADOW
#define RENDER_GEOMETRY

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

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
    #if DYN_LIGHT_COLORS == DYN_LIGHT_COLOR_RP
        uniform sampler2D gtexture;
    #endif

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uniform sampler2D noisetex;
    #endif

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uniform float frameTimeCounter;
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

#if SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

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
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_entities.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
         || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
            #if DYN_LIGHT_COLORS == DYN_LIGHT_COLOR_RP
                vec3 lightColor = vec3(0.0);
                float lightRange = GetSceneBlockLightLevel(vBlockId[0]);
                if (lightRange > EPSILON) lightColor = RGBToLinear(textureLod(gtexture, vTexcoord[0], 3).rgb);
                AddSceneBlockLight(vBlockId[0], vOriginPos[0], lightColor, lightRange);
            #else
                AddSceneBlockLight(vBlockId[0], vOriginPos[0]);
            #endif
        }
        else if (renderStage == MC_RENDER_STAGE_ENTITIES) {
            vec4 light = GetSceneEntityLightColor(entityId, vVertexId);
            if (light.a > EPSILON) AddSceneBlockLight(0, vOriginPos[0], light.rgb, light.a);
        }
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        //if (vEntityId[0] == MATERIAL_LIGHTNING_BOLT) return;

        vec3 originShadowViewPos = (shadowModelView * vec4(vOriginPos[0], 1.0)).xyz;

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            bool intersects = true;
            //vec3 shadowClipPos = (shadowProjection * vec4(originShadowViewPos, 1.0)).xyz;

            // TODO: shadow culling needs different frustum tests

            if (!intersects) return;
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
                        if (!CascadeIntersectsProjection(originShadowViewPos, c)) continue;
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
