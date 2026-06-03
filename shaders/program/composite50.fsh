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
uniform int frameCounter;
uniform int isEyeInWater = 0;
uniform float blindness = 0.0;
uniform vec2 taa_offset = vec2(0.0);

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

float getBlurCoc(float depth, float focusPoint, float focusScale) {
    return clamp((1.0 / focusPoint - 1.0 / depth) * focusScale, -1.0, 1.0);
}

float getBlurFar(float depth, float focusPoint, float focusScale) {
    float coc = 0.0;

    #ifdef EFFECT_BLUR_WATER
        if (isEyeInWater == 1) {
            float water_coc = depth * 0.02;
            coc = max(coc, water_coc);
        }
    #endif

    #ifdef EFFECT_BLUR_BLINDNESS
        coc = max(coc, blindness * smoothstep(8.0, 12.0, depth));
    #endif

    return coc;
}

//float getBlurSize(float depth, float focusPoint, float focusScale) {
//    float coc_near = 0.0;
//    float coc_far = getBlurFar();
//
//    #ifdef EFFECT_BLUR_DOF
//        float coc = getBlurCoc(depth, focusPoint, focusScale);
////        coc = abs(coc);
//
//        coc_near = min(coc_near, coc);
//        coc_far = max(coc_far, coc);
//    #endif
//
//    coc *= EFFECT_BLUR_RADIUS;
//
//    return coc;
//}

struct BlurData {
    vec3 near;
    float coc;
    vec3 far;
    float distF;
};

BlurData SampleDof(const in ivec2 uv, const in float focusPoint, const in float focusScale) {
    float centerDepth = texelFetch(TEX_DEPTH, uv, 0).r;
    centerDepth = linearizeDepth(centerDepth, nearPlane, farPlane);

    BlurData result;
    result.coc = 0.0;

//    float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
    #ifdef EFFECT_BLUR_DOF
        result.coc = getBlurCoc(centerDepth, focusPoint, focusScale);
    #endif

    float centerSize = max(abs(result.coc), result.distF) * EFFECT_BLUR_RADIUS;

//    vec3 color = vec3(0.0);//texelFetch(TEX_SOURCE, uv, 0).rgb;
    result.near = vec3(0.0);
    result.far = vec3(0.0);

    vec2 texelSize = 1.0 / viewSize;
    vec2 texcoord = (uv + 0.5) / viewSize;

    #ifdef TAA_ENABLED
        texcoord += taa_offset;
    #endif

    float dither = GetDither();
    mat2 rotation = GetRandomRotation(dither);

    float total = 0.0;
//    float total_near = 0.0;
//    float total_far = 0.0;

    for (int i = 0; i < EFFECT_BLUR_SAMPLES; i++) {
        float radius = sqrt(float(i + dither) / EFFECT_BLUR_SAMPLES) * EFFECT_BLUR_RADIUS;

        float ang = i * GoldenAngle;
        vec2 tc = rotation * vec2(cos(ang), sin(ang)) * texelSize * radius + texcoord;

        ivec2 uv = ivec2(tc * viewSize);
        uv = clamp(uv, ivec2(0), ivec2(viewSize)-1);

        vec3 sampleColor = textureLod(TEX_SOURCE, tc, 0).rgb;
//        vec3 sampleColor = texelFetch(TEX_SOURCE, uv, 0).rgb;

        float sampleDepth = texture(TEX_DEPTH, tc).r;
//        float sampleDepth = texelFetch(TEX_DEPTH, uv, 0).r;
        sampleDepth = linearizeDepth(sampleDepth, nearPlane, farPlane);

        float sampleCoc = getBlurCoc(sampleDepth, focusPoint, focusScale);
        float sampleSize = abs(sampleCoc) * EFFECT_BLUR_RADIUS;

        if (sampleDepth > centerDepth) {
            sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);
        }

        float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
//        color += mix(color/(i+1), sampleColor, m);

//        if (result.coc < 0.0) m *= sampleCoc + 1.0;
//        if (sampleCoc < 0.0) m *= sampleCoc + 1.0;

//        if (result.coc > 0.0) m *= 1.0 - sampleCoc;
//        if (sampleCoc > 0.0) m *= 1.0 - sampleCoc;

        result.near += m * sampleColor;
        total += m;
    }

    if (total > EPSILON) result.near /= total;
    else result.near = texelFetch(TEX_SOURCE, uv, 0).rgb;

    return result;
}


/* RENDERTARGETS: 9,10 */
layout(location = 0) out vec4 outBlurNear;
layout(location = 1) out vec4 outBlurFar;

void main() {
    #ifndef EFFECT_BLUR_DOF
        bool skip = true;
        if (isEyeInWater == 1) skip = false;
        if (blindness > 0.0) skip = false;
        if (skip) return;
    #endif

    float focusPoint = linearizeDepth(centerDepthSmooth, nearPlane, farPlane);
    float focusScale = min(float(EFFECT_DOF_STRENGTH) / focusPoint, focusPoint);

    ivec2 uv = ivec2(gl_FragCoord.xy);
    BlurData result = SampleDof(uv, focusPoint, focusScale);

    outBlurNear = vec4(result.near, result.coc);
    outBlurFar = vec4(result.far, result.distF);
}
