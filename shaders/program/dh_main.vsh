#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"


out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat int materialId;
} vOut;


uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"


void main() {
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vOut.color = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    // TODO: how useful is this snapping?
    vec3 cameraOffset = fract(cameraPosition);
    vec3 modelPos = floor(gl_Vertex.xyz + cameraOffset + 0.5) - cameraOffset;

    #ifdef RENDER_TRANSLUCENT
        if (dhMaterialId == DH_BLOCK_WATER)
            modelPos.y -= (1.8/16.0);
    #endif

    vec3 viewPos = mul3(gl_ModelViewMatrix, modelPos);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA_ENABLED
        gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
    #endif

    #if RENDER_SCALE != 0
        gl_Position.xy /= gl_Position.w;
        gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
        gl_Position.xy *= RENDER_SCALE_F;
        gl_Position.xy = gl_Position.xy * 2.0 - 1.0;
        gl_Position.xy *= gl_Position.w;
    #endif

    vOut.materialId = dhMaterialId;
}
