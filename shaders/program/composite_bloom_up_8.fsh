#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_BLOOM_TILES;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;

#include "/lib/sampling/ign.glsl"
#include "/lib/effects/bloom.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec2 srcBoundsMin, srcBoundsMax;
    GetBloomTileInnerBounds(0, srcBoundsMin, srcBoundsMax);

    vec2 srcTex = texcoord * (srcBoundsMax - srcBoundsMin) + srcBoundsMin;

    #ifdef EFFECT_BLOOM_SMOOTH
        srcTex -= pixelSize;

        vec3 color1 = textureLod(BUFFER_BLOOM_TILES, srcTex, 0).rgb;
        vec3 color2 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(1,0)).rgb;
        vec3 color3 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(0,1)).rgb;
        vec3 color4 = textureLodOffset(BUFFER_BLOOM_TILES, srcTex, 0, ivec2(1,1)).rgb;

        vec3 color = (color1 + color2 + color3 + color4) * 0.25;
    #else
        vec3 color = textureLod(BUFFER_BLOOM_TILES, srcTex, 0).rgb;
    #endif

    color *= EffectBloomStrengthF;

    #if POST_TONEMAP == 0
        // apply a reinhard like curve to prevent blowout when tonemap is disabled
        color = color / (color + 1.0);
    #endif
    
    DitherBloom(color);

    outFinal = color;
}
