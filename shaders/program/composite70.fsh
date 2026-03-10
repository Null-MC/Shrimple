#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

uniform vec2 viewSize;

#include "/lib/bloom.glsl"


/* RENDERTARGETS: 5 */
layout(location = 0) out vec3 outFinal;

void main() {
    const int tile = 0;

    vec2 pixelSize = 1.0 / viewSize;

    vec2 tex = texcoord - (tilePadding + 0.5) * 2.0*pixelSize;
    tex /= 1.0 - (2.0*tilePadding) * 2.0*pixelSize;
    tex += pixelSize;

    outFinal = BloomBoxSample(BUFFER_FINAL, tex, vec2(0.0), viewSize);
}
