#define RENDER_COMPOSITE_POST
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform sampler2D BUFFER_BLOOM_TILES;


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec3 color = texelFetch(BUFFER_BLOOM_TILES, ivec2(gl_FragCoord.xy), 0).rgb;

    outFinal = color;
}
