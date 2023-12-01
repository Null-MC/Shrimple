#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_BLOOM_TILES;

uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/sampling/ign.glsl"
#include "/lib/post/bloom.glsl"


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec3 color = BloomTileDownsample(BUFFER_BLOOM_TILES, 2);

    DitherBloom(color);

    outFinal = color;
}
