#define RENDER_SHADOW
#define RENDER_GEOMETRY

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

in vec4 vColor[3];
in vec2 vTexcoord[3];
flat in vec3 vOriginPos[3];

out vec2 gTexcoord;
out vec4 gColor;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    flat out vec2 gShadowTilePos;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform float near;
    uniform float far;

    #include "/lib/blocks.glsl"

    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
    #endif
#endif


void main() {
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
