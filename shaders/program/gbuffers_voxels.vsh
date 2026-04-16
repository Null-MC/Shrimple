#include "/lib/constants.glsl"
#include "/lib/common.glsl"

//in vec4 mc_Entity;
in vec4 at_midBlock;

out VertexData {
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;
} vOut;


uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/blocks.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/photonics/photonics.glsl"


void main() {
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    vOut.localNormal = gl_Normal;

//    #ifdef WIND_ENABLED
////        int blockId = int(mc_Entity.x + EPSILON);
//        int blockId = BLOCK_GRASS_SHORT;//get_block_id(vOut.localPos + rt_camera_position + at_midBlock.xyz/64.0);
//
//        if (blockId == BLOCK_GRASS_SHORT) {
//            vec3 localPos = vOut.localPos;
//            localPos.y += 0.5;
//
//            viewPos = mul3(gbufferModelView, localPos);
//        }
//    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA_ENABLED
        gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
    #endif
}
