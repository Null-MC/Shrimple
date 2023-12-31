#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_FINAL_PREV;
uniform sampler2D BUFFER_DEPTH_PREV;
uniform sampler2D depthtex0;
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


vec2 getReprojectedUV(const in vec2 texcoord, const in float depthNow) {
    vec3 clipPos = vec3(texcoord, depthNow) * 2.0 - 1.0;
    //clipPos.xy -= 0.25*getJitterOffset(frameCounter);

    #ifdef IRIS_FEATURE_SSBO
        vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    #endif

    vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;

    #ifdef IRIS_FEATURE_SSBO
        vec4 clipPosPrev = gbufferPreviousModelViewProjection * vec4(localPosPrev, 1.0);
    #else
        vec4 viewPosPrev = gbufferPreviousModelView * vec4(localPosPrev, 1.0);
        vec4 clipPosPrev = gbufferPreviousProjection * viewPosPrev;
    #endif

    clipPosPrev.xyz /= clipPosPrev.w;
    //clipPosPrev.xy -= 0.25*getJitterOffset(frameCounter-1);

    return clipPosPrev.xy * 0.5 + 0.5;
}

void neighborClampColor(inout vec3 colorPrev, const in vec2 texcoord) {
    vec3 minColor = vec3(+9999.0);
    vec3 maxColor = vec3(-9999.0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = texcoord + vec2(x, y) * pixelSize;
            vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;

            minColor = min(minColor, sampleColor);
            maxColor = max(maxColor, sampleColor);
        }
    }
    
    colorPrev = clamp(colorPrev, minColor, maxColor);
}

float neighborColorTest(const in vec3 colorPrev, const in vec2 texcoord) {
    vec3 minColor = vec3(+9999.0);
    vec3 maxColor = vec3(-9999.0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = texcoord + vec2(x, y) * pixelSize;
            vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;

            minColor = min(minColor, sampleColor);
            maxColor = max(maxColor, sampleColor);
        }
    }
    
    //return all(greaterThanEqual(colorPrev, minColor)) && all(lessThanEqual(colorPrev, maxColor)) ? 1.0 : 0.0;
    vec3 diff = max(minColor - colorPrev, 0.0) + max(colorPrev - maxColor, 0.0);
    return max(1.0 - 2.0*luminance(diff), 0.0);
}

float neighborDepthTest(const in float depthPrevL, const in vec2 texcoord) {
    float minDepth = 1.0;
    float maxDepth = 0.0;

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = texcoord + vec2(x, y) * pixelSize;
            float sampleDepth = textureLod(depthtex0, sampleCoord, 0).r;

            // ivec2 sampleCoord = ivec2(gl_FragCoord.xy) + ivec2(x, y);
            // float sampleDepth = texelFetch(depthtex0, sampleCoord, 0).r;

            minDepth = min(minDepth, sampleDepth);
            maxDepth = max(maxDepth, sampleDepth);
        }
    }

    minDepth = linearizeDepthFast(minDepth, near, far) - 0.1;
    maxDepth = linearizeDepthFast(maxDepth, near, far) + 0.1;
    
    // return step(minDepth, depthPrevL) * step(depthPrevL, maxDepth);
    float dist = max(minDepth - depthPrevL, 0.0) + max(depthPrevL - maxDepth, 0.0);
    return max(1.0 - _pow2(2.0*dist), 0.0);
}

vec4 sampleHistoryCatmullRom(const in vec2 uv) {
    vec2 samplePos = uv * viewSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - texPos1;

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
    vec2 offset12 = w2 / max(w1 + w2, EPSILON);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0 = (texPos1 - 1.0) * pixelSize;
    vec2 texPos3 = (texPos1 + 2.0) * pixelSize;
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

    return result;
}


/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec4 outFinalPrev;
layout(location = 2) out float outDepthPrev;

void main() {
    float TAA_MaxFrameAccum = 30.0;
    TAA_MaxFrameAccum /= 1.0 + 100.0*_lengthSq(cameraPosition - previousCameraPosition);

    vec2 uvNow = texcoord;
    //vec2 offset = getJitterOffset(frameCounter);

    float depthNow = textureLod(depthtex0, uvNow, 0).r;
    float depthNowHand = textureLod(depthtex2, uvNow, 0).r;
    bool isHand = abs(depthNow - depthNowHand) > EPSILON;

    if (isHand) {
        depthNow = depthNow * 2.0 - 1.0;
        depthNow /= MC_HAND_DEPTH;
        depthNow = depthNow * 0.5 + 0.5;

        uvNow += 0.5*getJitterOffset(frameCounter);
    }
    vec3 colorNow = textureLod(BUFFER_FINAL, uvNow, 0).rgb;

    //uvNow += offset*0.5;
    vec2 uvPrev = getReprojectedUV(uvNow, depthNow);
    float depthNowL = linearizeDepthFast(depthNow, near, far);

    //vec4 colorPrev = textureLod(BUFFER_FINAL_PREV, uvPrev, 0);
    vec4 colorPrev = sampleHistoryCatmullRom(uvPrev);
    float counter = clamp(colorPrev.a, 0.0, TAA_MaxFrameAccum);
    if (saturate(uvPrev) != uvPrev) counter = 0.0;

    //neighborClampColor(colorPrev.rgb, uvNow);
    counter *= neighborColorTest(colorPrev.rgb, uvNow);

    // uvPrev += getJitterOffset(frameCounter);
    // uvPrev -= getJitterOffset(frameCounter-1);
    float depthPrevL = textureLod(BUFFER_DEPTH_PREV, uvPrev, 0).r;
    counter *= neighborDepthTest(depthPrevL, uvNow);

    counter = max(counter + 1.0, 1.0);
    float weight = 1.0 - rcp(counter);

    vec3 colorFinal = mix(colorNow, colorPrev.rgb, weight);
    //float depthFinal = mix(depthNowL, depthPrevL, weight);

    outFinal = colorFinal;
    outFinalPrev = vec4(colorFinal, counter);
    outDepthPrev = depthNowL;
}
