#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;

#include "/lib/sampling/ign.glsl"
#include "/lib/post/bloom.glsl"


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    const int tile = 0;

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 pixelSize = rcp(viewSize);

    vec2 boundsMin, boundsMax;
    vec2 outerBoundsMin, outerBoundsMax;
    GetBloomTileInnerBounds(viewSize, tile, boundsMin, boundsMax);
    GetBloomTileOuterBounds(viewSize, tile, outerBoundsMin, outerBoundsMax);

    vec2 tex = (gl_FragCoord.xy - 0.5) / viewSize;
    tex = clamp(tex, boundsMin, boundsMax);
    tex = (tex - outerBoundsMin) / (boundsMax - boundsMin);

    //tex -= 0.5 * pixelSize;

    vec3 color = BloomBoxSample(BUFFER_FINAL, tex, pixelSize);
    
    #if defined DH_COMPAT_ENABLED && !defined DEFERRED_BUFFER_ENABLED
        color = RGBToLinear(color);
    #endif

    float threshold = PostBloomThresholdF;
    if (isEyeInWater == 1) threshold *= 0.25;

    float brightness = luminance(color);
    float contribution = max(brightness - threshold, 0.0);
    contribution /= max(brightness, EPSILON);
    color *= contribution;

    color += (InterleavedGradientNoise(gl_FragCoord.xy) - 0.25) / 32.0e3;

    outFinal = max(color, 0.0);
}
