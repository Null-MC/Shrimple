#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 v_texcoord;


void main() {
    gl_Position = ftransform();
    v_texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    #if RENDER_SCALE != 0
        gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
        gl_Position.xy *= RENDER_SCALE_F;
        gl_Position.xy = gl_Position.xy * 2.0 - 1.0;
    #endif
}
