#include "/lib/constants.glsl"
#include "/lib/common.glsl"


out VertexData {
    vec2 lmcoord;
    vec3 localPos;
//    flat uint localNormal;
} vOut;


uniform mat4 gbufferModelViewInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/sampling/lightmap.glsl"
//#include "/lib/octohedral.glsl"


void main() {
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

//    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
//    vec3 localNormal = mat3(gbufferModelViewInverse) * viewNormal;
//    vOut.localNormal = packUnorm2x16(OctEncode(localNormal));

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA_ENABLED
        gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
    #endif
}
