#include "/lib/constants.glsl"
#include "/lib/common.glsl"


#ifndef RENDER_SOLID
    in vec2 texcoord;
//    in int blockId;
#endif


uniform sampler2D gtexture;

uniform float alphaTestRef;

/* RENDERTARGETS: 0 */
//layout(location = 0) out vec4 outColor;


void main() {
    #ifndef RENDER_SOLID
        vec4 color = texture(gtexture, texcoord);
        if (color.a < alphaTestRef) discard;
    #endif
}
