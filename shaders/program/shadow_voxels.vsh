#include "/lib/constants.glsl"
#include "/lib/common.glsl"


out VertexData {
    vec3 localPos;
    vec3 localNormal;
} vOut;


uniform mat4 shadowModelViewInverse;

#include "/lib/shadows.glsl"


void main() {
    #ifdef PHOTONICS_SHADOW_ENABLED
        gl_Position = vec4(-10.0);
        return;
    #endif

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(shadowModelViewInverse) * viewNormal;

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(shadowModelViewInverse, viewPos);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    distort(gl_Position.xy);
}
