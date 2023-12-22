#define RENDER_TERRAIN
#define RENDER_GBUFFER
#define RENDER_GEOMETRY

layout (triangles) in;

#ifdef WIREFRAME_DEBUG
    layout (line_strip, max_vertices=3) out;
#else
    layout (triangle_strip, max_vertices=3) out;
#endif

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat int blockId;
    flat mat2 atlasBounds;

    #if DISPLACE_MODE == DISPLACE_TESSELATION
        vec3 surfacePos;
    #endif

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

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
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat int blockId;
    flat mat2 atlasBounds;

    #if DISPLACE_MODE == DISPLACE_TESSELATION
        vec3 surfacePos;
    #endif

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

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

uniform mat4 gbufferModelView;

#include "/lib/blocks.glsl"


void main() {
    #if DISPLACE_MODE == DISPLACE_TESSELATION
        #ifdef WIREFRAME_DEBUG
            const bool backfaceCull = true;
        #else
            bool backfaceCull = vIn[0].blockId == BLOCK_POWDER_SNOW;
        #endif

        vec3 viewDir = normalize(vIn[0].localPos);
        if (backfaceCull && dot(vIn[0].localNormal, -viewDir) <= 0.0) return;
    #endif

    for(int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;

        vOut.color = vIn[i].color;
        vOut.lmcoord = vIn[i].lmcoord;
        vOut.texcoord = vIn[i].texcoord;
        vOut.localPos = vIn[i].localPos;
        vOut.localCoord = vIn[i].localCoord;
        vOut.localNormal = vIn[i].localNormal;
        vOut.localTangent = vIn[i].localTangent;
        vOut.blockId = vIn[i].blockId;
        vOut.atlasBounds = vIn[i].atlasBounds;

        #if DISPLACE_MODE == DISPLACE_TESSELATION
            vOut.surfacePos = vIn[i].surfacePos;
        #endif

        #ifdef PARALLAX_ENABLED
            vOut.viewPos_T = vIn[i].viewPos_T;

            #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
                vOut.lightPos_T = vIn[i].lightPos_T;
            #endif
        #endif

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            vOut.cloudPos = vIn[i].cloudPos;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vOut.shadowPos[0] = vIn[i].shadowPos[0];
                vOut.shadowPos[1] = vIn[i].shadowPos[1];
                vOut.shadowPos[2] = vIn[i].shadowPos[2];
                vOut.shadowPos[3] = vIn[i].shadowPos[3];

                vOut.shadowTile = vIn[i].shadowTile;
            #else
                vOut.shadowPos = vIn[i].shadowPos;
            #endif
        #endif

        EmitVertex();
    }

    EndPrimitive();
}
