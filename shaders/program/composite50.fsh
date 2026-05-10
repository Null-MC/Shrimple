// based on: https://www.shadertoy.com/view/lstBDl

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE TEX_FINAL
#define TEX_DEPTH depthtex0


in vec2 texcoord;

uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_SOURCE;

uniform float nearPlane;
uniform float farPlane;
uniform vec2 viewSize;
uniform float centerDepthSmooth;
uniform int isEyeInWater;
uniform int frameCounter;

uniform float blindness = 0.0;

#include "/lib/sampling/depth.glsl"
#include "/lib/ign.glsl"


float GetDither() {
    vec2 seed = gl_FragCoord.xy;
    #ifdef TAA_ENABLED
        seed += vec2(71.83, 83.71) * (frameCounter % 16);
    #endif

    return InterleavedGradientNoise(seed);
}

mat2 GetRandomRotation(const in float dither) {
    float angle = fract(dither) * (PI * 2.0);
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

float getBlurSize(float depth, float focusPoint, float focusScale) {
    float coc = 0.0;

    #ifdef EFFECT_BLUR_DOF
        coc = clamp((1.0 / focusPoint - 1.0 / depth) * focusScale, -1.0, 1.0);
    #endif

    #ifdef EFFECT_BLUR_WATER
        if (isEyeInWater == 1) {
            float water_coc = depth * 0.02;
            coc = max(coc, water_coc);
        }
    #endif

    #ifdef EFFECT_BLUR_BLINDNESS
        coc = max(coc, blindness * smoothstep(8.0, 12.0, depth));
    #endif

    coc = abs(coc) * EFFECT_BLUR_RADIUS;

    return coc;
}

vec4 SampleDof(const in ivec2 uv, const in float focusPoint, const in float focusScale) {
    float centerDepth = texelFetch(TEX_DEPTH, uv, 0).r;
    centerDepth = linearizeDepth(centerDepth, nearPlane, farPlane);

    float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
    vec3 color = vec3(0.0);//texelFetch(TEX_SOURCE, uv, 0).rgb;

    vec2 texelSize = 1.0 / viewSize;
    vec2 texcoord = (uv + 0.5) / viewSize;

    float dither = GetDither();
    mat2 rotation = GetRandomRotation(dither);

    float total = 0.0;
    for (int i = 0; i < EFFECT_BLUR_SAMPLES; i++) {
        float radius = sqrt(float(i + dither) / EFFECT_BLUR_SAMPLES) * EFFECT_BLUR_RADIUS;

        float ang = i * GoldenAngle;
        vec2 tc = rotation * vec2(cos(ang), sin(ang)) * texelSize * radius + texcoord;
        vec3 sampleColor = textureLod(TEX_SOURCE, tc, 0).rgb;

        float sampleDepth = texture(TEX_DEPTH, tc).r;
        sampleDepth = linearizeDepth(sampleDepth, nearPlane, farPlane);

        float sampleSize = getBlurSize(sampleDepth, focusPoint, focusScale);

        if (sampleDepth > centerDepth) {
            sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);
        }

        float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
//        color += mix(color/(i+1), sampleColor, m);
        color += m * sampleColor;
        total += m;
    }

    if (total > EPSILON) color /= total;
    else color = texelFetch(TEX_SOURCE, uv, 0).rgb;

    return vec4(color, centerSize);
}


/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 outBlurSize;

void main() {
    float focusPoint = linearizeDepth(centerDepthSmooth, nearPlane, farPlane);
    float focusScale = min(8.0 / focusPoint, focusPoint);

    ivec2 uv = ivec2(gl_FragCoord.xy);
    outBlurSize = SampleDof(uv, focusPoint, focusScale);
}
