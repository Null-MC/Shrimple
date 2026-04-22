#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
} vOut;


uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#ifdef TAA_ENABLED
    uniform vec2 taa_offset = vec2(0.0);
#endif


void main() {
    gl_Position = ftransform();

    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.color = gl_Color;

    vec3 viewPos = (gbufferProjectionInverse * gl_Position).xyz;
    vOut.localPos = mat3(gbufferModelViewInverse) * viewPos;

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
