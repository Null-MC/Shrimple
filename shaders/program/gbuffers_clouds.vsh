#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec3 localPos;
    vec3 localNormal;
} vOut;

uniform mat4 gbufferModelViewInverse;

#ifdef TAA_ENABLED
    uniform vec2 taa_offset = vec2(0.0);
#endif


void main() {
    vOut.color = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
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
}
