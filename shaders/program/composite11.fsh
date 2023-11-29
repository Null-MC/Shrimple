#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

#if EFFECT_BLOOM_HAND != 100
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;
#endif

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int isEyeInWater;

#ifdef EFFECT_AUTO_EXPOSE
    uniform ivec2 eyeBrightnessSmooth;
#endif

#include "/lib/sampling/ign.glsl"
#include "/lib/post/bloom.glsl"


/* RENDERTARGETS: 15 */
layout(location = 0) out vec3 outFinal;

void main() {
    const int tile = 0;

    vec2 boundsMin, boundsMax;
    vec2 outerBoundsMin, outerBoundsMax;
    GetBloomTileInnerBounds(tile, boundsMin, boundsMax);
    GetBloomTileOuterBounds(tile, outerBoundsMin, outerBoundsMax);

    // vec2 tex = texcoord - 0.5 * pixelSize;// (gl_FragCoord.xy - 0.5) * pixelSize;
    // tex = clamp(tex, boundsMin, boundsMax);
    // tex = (tex - boundsMin) / (boundsMax - boundsMin);

    //tex -= 0.5 * pixelSize;

    vec3 color = BloomBoxSample(BUFFER_FINAL, texcoord, pixelSize);
    
    #if defined DH_COMPAT_ENABLED && !defined DEFERRED_BUFFER_ENABLED
        color = RGBToLinear(color);
    #endif
    
    #ifdef EFFECT_AUTO_EXPOSE
        vec2 eyeBright = eyeBrightnessSmooth / 240.0;
        float brightF = 1.0 - max(eyeBright.x * 0.5, eyeBright.y);
        color *= mix(1.0, 3.0, pow(brightF, 1.5));
    #endif

    color *= exp2(POST_EXPOSURE);

    float power = EFFECT_BLOOM_POWER;
    if (isEyeInWater == 1) power = 1.0;

    //const float lumMax = luminance(vec3(6.0));
    float brightness = luminance(color);// / lumMax;
    brightness = brightness / (brightness + 1.0);
    //float contribution = max(brightness - threshold, 0.0);
    float contribution = pow(brightness, power);
    //contribution /= max(brightness, EPSILON);
    color *= min(contribution, 1.0);

    #if EFFECT_BLOOM_HAND != 100
        float depth1 = textureLod(depthtex1, texcoord, 0).r;
        float depth2 = textureLod(depthtex2, texcoord, 0).r;

        if (depth1 < depth2) color *= Bloom_HandStrength;
    #endif

    color += (InterleavedGradientNoise(gl_FragCoord.xy) - 0.25) / 32.0e3;

    outFinal = max(color, 0.0);
}
