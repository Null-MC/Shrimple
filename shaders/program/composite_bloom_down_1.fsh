#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

#if EFFECT_BLOOM_HAND_STRENGTH != 100
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;
#endif

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int isEyeInWater;
uniform int frameCounter;
uniform float nightVision;

#if MC_VERSION >= 11900
    uniform float darknessFactor;
    uniform float darknessLightFactor;
#endif

#ifdef EFFECT_AUTO_EXPOSE
    uniform ivec2 eyeBrightnessSmooth;
#endif

#include "/lib/sampling/ign.glsl"
#include "/lib/effects/bloom.glsl"
#include "/lib/post/exposure.glsl"


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    const int tile = 0;

    vec2 tex = texcoord - (tilePadding + 0.5) * 2.0*pixelSize;
    tex /= 1.0 - (2.0*tilePadding) * 2.0*pixelSize;
    tex += pixelSize;

    vec3 color = BloomBoxSample(BUFFER_FINAL, tex, pixelSize);
        
    ApplyPostExposure(color);

    float brightness = luminance(color);
    float brightness_new = pow(brightness * EffectBloomBrightnessF, EFFECT_BLOOM_POWER);
    color *= min(brightness_new / brightness, 1.0);

    #if EFFECT_BLOOM_HAND_STRENGTH != 100
        float depth1 = textureLod(depthtex1, tex, 0).r;
        float depth2 = textureLod(depthtex2, tex, 0).r;

        if (depth1 < depth2) color *= Bloom_HandStrength;
    #endif

    color = max(color, 0.0);

    DitherBloom(color);

    #ifdef DEBUG_BLOOM_TILES
        color = vec3(0.0, 1.0, 0.0);
        if (clamp(tex, 0.0, 1.0) != tex) color = vec3(1.0, 0.0, 0.0);
    #endif

    outFinal = color;
}
