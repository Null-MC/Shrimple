#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 v_texcoord;


void main() {
    gl_Position = ftransform();
    v_texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
