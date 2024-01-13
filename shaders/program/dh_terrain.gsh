#define RENDER_TERRAIN_DH
#define RENDER_GBUFFER
#define RENDER_GEOMETRY

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn[];

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;


void main() {
    for (int v = 0; v < 3; v++) {
        gl_Position = gl_in[v].gl_Position;

        vOut.color = vIn[v].color;
        vOut.lmcoord = vIn[v].lmcoord;
        vOut.localPos = vIn[v].localPos;

        // TODO
        vOut.localNormal = vec3(0.0, 1.0, 0.0);

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            vOut.cloudPos = vIn[v].cloudPos;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vOut.shadowPos[0] = vIn[v].shadowPos[0];
                vOut.shadowPos[1] = vIn[v].shadowPos[1];
                vOut.shadowPos[2] = vIn[v].shadowPos[2];
                vOut.shadowPos[3] = vIn[v].shadowPos[3];
                vOut.shadowTile = vIn[v].shadowTile;
            #else
                vOut.shadowPos = vIn[v].shadowPos;
            #endif
        #endif

        EmitVertex();
    }

    EndPrimitive();
}
