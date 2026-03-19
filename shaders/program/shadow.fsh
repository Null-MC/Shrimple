#include "/lib/constants.glsl"
#include "/lib/common.glsl"


#if defined(SHADOWS_ENABLED) && (!defined(RENDER_SOLID) || defined(SHADOW_COLORED))
    in vec2 texcoord;

    #ifdef SHADOW_COLORED
        in vec4 color;
        flat in int blockId;
    #endif
#endif


uniform sampler2D gtexture;

uniform float alphaTestRef;

#include "/lib/blocks.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(0.0);

    #if defined(SHADOWS_ENABLED) && (!defined(RENDER_SOLID) || defined(SHADOW_COLORED))
        outColor = texture(gtexture, texcoord);

        #ifdef SHADOW_COLORED
            outColor *= color;

            if (blockId == BLOCK_WATER)
                outColor.a = 1.0;
        #endif
    #endif

    #ifndef RENDER_SOLID
        if (outColor.a < alphaTestRef) discard;
    #endif
}
