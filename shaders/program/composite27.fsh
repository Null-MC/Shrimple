#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_BLOOM_TILES;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/post/bloom.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 pixelSize = rcp(viewSize);

    vec2 srcBoundsMin, srcBoundsMax;
    GetBloomTileInnerBounds(viewSize, 0, srcBoundsMin, srcBoundsMax);

    vec2 srcTex = texcoord * (srcBoundsMax - srcBoundsMin) + srcBoundsMin;

    srcTex -= pixelSize;

    vec3 color1 = textureLod(BUFFER_BLOOM_TILES, srcTex, 0).rgb;
    vec3 color2 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(1,0)).rgb;
    vec3 color3 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(0,1)).rgb;
    vec3 color4 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(1,1)).rgb;

    vec3 color = (color1 + color2 + color3 + color4) * 0.25;

    outFinal = color * PostBloomStrengthF;
}
