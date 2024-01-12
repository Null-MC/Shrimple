#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_FINAL_PREV;
uniform sampler2D BUFFER_DEPTH_PREV;
uniform sampler2D BUFFER_VELOCITY;
// uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int frameCounter;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/effects/taa.glsl"


vec3 getReprojectedClipPos(const in vec2 texcoord, const in float depthNow, const in vec3 velocity) {
    vec3 clipPos = vec3(texcoord, depthNow) * 2.0 - 1.0;

    #ifdef IRIS_FEATURE_SSBO
        vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    #endif

    vec3 localPosPrev = localPos - velocity + cameraPosition - previousCameraPosition;

    #ifdef IRIS_FEATURE_SSBO
        vec3 clipPosPrev = unproject(gbufferPreviousModelViewProjection * vec4(localPosPrev, 1.0));
    #else
        vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
        vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));
    #endif

    return clipPosPrev * 0.5 + 0.5;
}

// void neighborClampColor(inout vec3 colorPrev, const in vec2 texcoord) {
//     vec3 minColor = vec3(+9999.0);
//     vec3 maxColor = vec3(-9999.0);

//     for (int x = -1; x <= 1; ++x) {
//         for (int y = -1; y <= 1; ++y) {
//             vec2 sampleCoord = texcoord + vec2(x, y) * pixelSize;
//             vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;

//             minColor = min(minColor, sampleColor);
//             maxColor = max(maxColor, sampleColor);
//         }
//     }
    
//     colorPrev = clamp(colorPrev, minColor, maxColor);
// }

float neighborColorTest(const in vec3 colorPrev, const in vec2 texcoord) {
    //float deltaMin = 1.0;

    // vec3 colorPrevN = normalize(colorPrev + EPSILON);

    // WARN: using the min-of-samples is bad; promotes flicker
    // instead get min/max and check if range

    float lumMax = 0.0;
    float lumMin = 9999.0;

    vec3 rgbMax = vec3(0.0);
    vec3 rgbMin = vec3(9999.0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = texcoord + vec2(x, y) * pixelSize;
            vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;
            float sampleLum = luminance(sampleColor);

            rgbMin = min(rgbMin, sampleColor);
            rgbMax = max(rgbMax, sampleColor);

            // vec3 sampleColorN = normalize(sampleColor + EPSILON);
            // vec3 deltaRGB = abs(colorPrevN - sampleColorN);
            // float sampleDelta = 2.0 * luminance(deltaRGB);

            lumMin = min(lumMin, sampleLum);
            lumMax = max(lumMax, sampleLum);

            // float deltaLum = abs(luminance(colorPrev) - sampleLum);
            // sampleDelta += 0.5 * deltaLum;

            //deltaMin = min(deltaMin, sampleDelta);
        }
    }

    float delta = 0.0;

    // vec3 colorPrevN = normalize(colorPrev + EPSILON);
    // vec3 rgbMinN = normalize(rgbMin + EPSILON);
    // vec3 rgbMaxN = normalize(rgbMax + EPSILON);
    // vec3 rgbDeltaN = max(rgbMinN - colorPrevN, 0.0) + max(colorPrevN - rgbMaxN, 0.0);
    // delta += max(maxOf(rgbDeltaN) - 0.2, 0.0);

    vec3 rgbDelta = max(rgbMin - colorPrev, 0.0) + max(colorPrev - rgbMax, 0.0);
    delta += 2.0 * max(luminance(rgbDelta) - 0.5, 0.0);

    float lumPrev = luminance(colorPrev);
    float lumDelta = max(lumMin - lumPrev, 0.0) + max(lumPrev - lumMax, 0.0);
    delta += 2.0 * max(lumDelta - 0.4, 0.0);
    
    //return max(1.0 - delta, 0.0);
    return 1.0 - _smoothstep(delta);
}

// TODO: combine neighbor tests

void getNeighborDepthRange(const in vec2 texcoord, out float depthMin, out float depthMax) {
    //vec2 jitter = getJitterOffset(frameCounter);
    vec2 offsetCoord = texcoord;// + 0.5*jitter;// - 0.5*pixelSize;

    depthMin = 1.0;
    depthMax = 0.0;

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = offsetCoord + vec2(x, y) * pixelSize;
            float sampleDepth = textureLod(depthtex1, sampleCoord, 0).r;
            //float sampleDepth = texelFetch(depthtex1, ivec2(sampleCoord * viewSize), 0).r;

            depthMin = min(depthMin, sampleDepth);
            depthMax = max(depthMax, sampleDepth);
        }
    }
}

vec4 sampleHistoryCatmullRom(const in vec2 uv) {
    vec2 samplePos = uv * viewSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    //vec2 f = samplePos - texPos1;
    vec2 f = fract(samplePos - 0.5);

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / max(w12, 0.001);

    w0 = saturate(w0);
    w12 = saturate(w12);
    w3 = saturate(w3);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0  = (texPos1 - 1.0) * pixelSize;
    vec2 texPos3  = (texPos1 + 2.0) * pixelSize;
    vec2 texPos12 = (texPos1 + offset12) * pixelSize;

    vec4 result = vec4(0.0);

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos0.y), 0) * w0.x * w0.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos0.y), 0) * w12.x * w0.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos0.y), 0) * w3.x * w0.y;

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos12.y), 0) * w0.x * w12.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos12.y), 0) * w12.x * w12.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos12.y), 0) * w3.x * w12.y;

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos3.y), 0) * w0.x * w3.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos3.y), 0) * w12.x * w3.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos3.y), 0) * w3.x * w3.y;

    return clamp(result, 0.0, 65000.0);
}

// void getHistoryCoordNearest(inout vec2 fragCoord, const in float depthNowL, out float depthPrevL, out float depthDiff) {
//     //return fragCoord;
//     // TODO: find neighbor with best depth-match

//     //vec2 jitter = 0.5*getJitterOffset(frameCounter);

//     vec2 _center = (fragCoord) * viewSize;
//     ivec2 center = ivec2(_center);
//     vec2 offset = vec2(0.0);
//     //depthPrevL = far;
//     //depthDiff = far;

//     depthPrevL = textureLod(BUFFER_DEPTH_PREV, fragCoord, 0).r;
//     depthDiff = abs(depthPrevL - depthNowL);

//     for (int iy = 0; iy < 2; iy++) {
//         for (int ix = 0; ix < 2; ix++) {
//             ivec2 sampleOffset = ivec2(ix, iy);
//             float sampleDepthL = texelFetch(BUFFER_DEPTH_PREV, center + sampleOffset, 0).r;
//             float sampleDiff = abs(sampleDepthL - depthNowL);

//             if (sampleDiff < depthDiff && sampleDiff > 0.8) {
//                 depthPrevL = sampleDepthL;
//                 depthDiff = sampleDiff;

//                 offset = sampleOffset - fract(_center);

//                 //fragCoord = (center + 0.5*sampleOffset + 0.5) * pixelSize;
//             }
//         }
//     }

//     //fragCoord += offset * pixelSize;
// }


/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec4 outFinalPrev;
layout(location = 2) out float outDepthPrev;

void main() {
    vec2 uvNow = texcoord;

    vec2 jitter = getJitterOffset(frameCounter);
    vec2 uvNowJitter = uvNow - 0.5*jitter;
    //uvNow -= 0.5*jitter;

    // float depthNow = textureLod(depthtex0, uvNow, 0).r;

    float depthNow = textureLod(depthtex1, uvNowJitter, 0).r;
    float depthNowHand = textureLod(depthtex2, uvNowJitter, 0).r;
    bool isHand = abs(depthNow - depthNowHand) > EPSILON;

    if (isHand) {
        depthNow = depthNow * 2.0 - 1.0;
        depthNow /= MC_HAND_DEPTH;
        depthNow = depthNow * 0.5 + 0.5;

        // uvNow += 0.5*getJitterOffset(frameCounter);
    }

    vec3 colorNow = textureLod(BUFFER_FINAL, uvNow, 0).rgb;
    vec4 velocity = textureLod(BUFFER_VELOCITY, uvNow, 0);

    float depthMin, depthMax;
    getNeighborDepthRange(uvNowJitter, depthMin, depthMax);
    float depthMinL = linearizeDepthFast(depthMin, near, far);
    float depthMaxL = linearizeDepthFast(depthMax, near, far);

    vec3 clipPosRepro = getReprojectedClipPos(uvNow, depthNow, velocity.xyz);
    float reproDepthL = linearizeDepthFast(clipPosRepro.z, near, far);

    vec2 uvPrev = clipPosRepro.xy;
    //float depthPrevL, depthDiff;
    //getHistoryCoordNearest(uvPrev, reproDepthL, depthPrevL, depthDiff);
    float depthPrevL = textureLod(BUFFER_DEPTH_PREV, uvPrev, 0).r;
    //depthDiff = abs(depthPrevL - depthNowL);

    float depthNowL = linearizeDepthFast(depthNow, near, far);
    depthNowL = clamp(depthNowL, near, far);

    float reproDepthMin = reproDepthL + (depthMinL - depthNowL);
    float reproDepthMax = reproDepthL + (depthMaxL - depthNowL);
    reproDepthMin = clamp(reproDepthMin, near, far);
    reproDepthMax = clamp(reproDepthMax, near, far);

    #ifdef EFFECT_TAA_SHARPEN
        vec4 colorPrev = sampleHistoryCatmullRom(uvPrev);
    #else
        vec4 colorPrev = textureLod(BUFFER_FINAL_PREV, uvPrev, 0);
    #endif

    float counter = clamp(colorPrev.a, 0.0, EFFECT_TAA_MAX_ACCUM);
    if (saturate(uvPrev) != uvPrev) counter = 0.0;

    if (velocity.w > 0.5) counter = min(counter, 2);

    //neighborClampColor(colorPrev.rgb, uvNow);
    counter *= neighborColorTest(colorPrev.rgb, uvNow);

    //const float depthBias = 0.2;
    //float depthTest = step(reproDepthMin - depthBias, depthPrevL) * step(depthPrevL, reproDepthMax + depthBias);
    float depthTest = max((reproDepthMin - 0.02) - depthPrevL, 0.0);
    depthTest += max(depthPrevL - (reproDepthMax + 0.02), 0.0);
    //if ((depthNow >= 1.0 && depthPrevL >= far * 0.99) || isHand) depthTest = 0.0;

    depthTest = saturate(1.0 - depthTest);
    counter *= depthTest;

    counter = max(counter + 1.0, 1.0);
    float weight = 1.0 - rcp(counter);

    vec3 colorFinal = mix(colorNow, colorPrev.rgb, weight);
    float depthFinal = mix(depthNowL, depthPrevL, weight);

    colorFinal = clamp(colorFinal, 0.0, 65000.0);

    outFinal = colorFinal;
    //outFinal = vec3(1.0 - depthTest);
    //outFinal = vec3(depthPrevL / far);
    //outFinal = vec3(1.0 - weight);
    outFinalPrev = vec4(colorFinal, counter);
    outDepthPrev = depthFinal;
}
