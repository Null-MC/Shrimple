#define RENDER_SHADOW_DH
#define RENDER_GEOMETRY

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    float cameraViewDist;

    flat uint materialId;
} vIn[];

out VertexData {
    vec4 color;
    float cameraViewDist;

    flat uint materialId;

    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vOut;

#if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 shadowModelView;
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform vec3 cameraPosition;
    uniform float dhFarPlane;
    uniform float near;
    uniform float far;

    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"
        #include "/lib/buffers/shadow.glsl"
    #endif

    #include "/lib/utility/matrix.glsl"
    #include "/lib/shadows/common.glsl"
    #include "/lib/shadows/cascaded/common.glsl"


    // returns: tile [0-3] or -1 if excluded
    int GetShadowRenderTile(const in vec3 blockPos) {
        const int max = 4;

        for (int i = 0; i < max; i++) {
            if (CascadeContainsPosition(blockPos, i, 3.0)) return i;
        }

        return -1;
    }
#endif

void main() {
    #ifdef RENDER_SHADOWS_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 originShadowViewPos = (gl_in[0].gl_Position.xyz + gl_in[1].gl_Position.xyz + gl_in[2].gl_Position.xyz) * rcp(3.0);

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
                    vOut.shadowTilePos = shadowTilePos;

                    vOut.color = vIn[v].color;
                    vOut.materialId = vIn[v].materialId;
                    vOut.cameraViewDist = vIn[v].cameraViewDist;

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
                gl_Position = gl_in[v].gl_Position;

                vOut.color = vIn[v].color;
                vOut.materialId = vIn[v].materialId;
                vOut.cameraViewDist = vIn[v].cameraViewDist;

                EmitVertex();
            }

            EndPrimitive();
        #endif
    #endif
}
