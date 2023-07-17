#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_BLOOM_TILES;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/sampling/ign.glsl"
#include "/lib/post/bloom.glsl"


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec3 color = BloomTileUpsample(BUFFER_BLOOM_TILES, EFFECT_BLOOM_TILE_MAX-4);
    
    color += (InterleavedGradientNoise(gl_FragCoord.xy) - 0.25) / 32.0e3;

    outFinal = color;
}
