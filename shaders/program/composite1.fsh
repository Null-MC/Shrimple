#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

uniform float viewWidth;
uniform float viewHeight;

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

    vec3 color = vec3(0.0);
    float totalWeight = 0.0;

    for (int iy = -5; iy < 5; iy++) {
        for (int ix = -5; ix < 5; ix++) {
            vec2 sampleOffset = vec2(ix, iy);
            float sampleWeight = pow(1.0 - length(sampleOffset) * 0.125, 6.0);

            vec3 sampleColor = textureLod(BUFFER_FINAL, tex + sampleOffset * pixelSize, 0).rgb;
            color += sampleWeight * sampleColor;
            totalWeight += sampleWeight;
        }
    }

    color /= totalWeight;

    const float _Threshold = 1.0;

    float brightness = maxOf(color);
    float contribution = max(brightness - _Threshold, 0.0);
    contribution /= max(brightness, EPSILON);
    color *= contribution;

    outFinal = max(color, 0.0);
}
