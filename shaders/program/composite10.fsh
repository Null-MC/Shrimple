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

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/depth.glsl"

vec2 getReprojectedUV(const in vec2 texcoord, const in float depthNow) {
    vec3 clipPos = vec3(texcoord, depthNow) * 2.0 - 1.0;

    #ifdef IRIS_FEATURE_SSBO
        vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    #endif

    vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;

    #ifdef IRIS_FEATURE_SSBO
        vec3 clipPosPrev = unproject(gbufferPreviousModelViewProjection * vec4(localPosPrev, 1.0));
    #else
        vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
        vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));
    #endif

    return clipPosPrev.xy * 0.5 + 0.5;
}

void neighboorhoodClampColor(inout vec3 colorPrev, const in vec2 texcoord) {
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

float neighboorhoodDepthTest(const in float depthPrevL, const in vec2 texcoord) {
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

    minDepth = linearizeDepthFast(minDepth, near, far) - 0.02;
    maxDepth = linearizeDepthFast(maxDepth, near, far) + 0.02;
    
    // return step(minDepth, depthPrevL) * step(depthPrevL, maxDepth);
    float dist = max(minDepth - depthPrevL, 0.0) + max(depthPrevL - maxDepth, 0.0);
    return max(1.0 - 2.0*dist, 0.0);
}


/* RENDERTARGETS: 0,5,6 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec4 outFinalPrev;
layout(location = 2) out float outDepthPrev;

void main() {
    vec3 colorNow = textureLod(BUFFER_FINAL, texcoord, 0).rgb;
    float depthNow = textureLod(depthtex0, texcoord, 0).r;

    vec2 uvPrev = getReprojectedUV(texcoord, depthNow);
    float depthNowL = linearizeDepthFast(depthNow, near, far);

    vec4 colorPrev = textureLod(BUFFER_FINAL_PREV, uvPrev, 0);
    float depthPrevL = textureLod(BUFFER_DEPTH_PREV, uvPrev, 0).r;
    float counter = clamp(colorPrev.a, 0.0, 60.0);

    // neighboorhoodClampColor(colorPrev.rgb, texcoord);

    counter *= neighboorhoodDepthTest(depthPrevL, texcoord);

    if (saturate(uvPrev) != uvPrev) counter = 0.0;

    float weight = 1.0 - rcp(1.0 + counter);

    vec3 colorFinal = mix(colorNow, colorPrev.rgb, weight);
    float depthFinal = mix(depthNowL, depthPrevL, weight);
    counter += 1.0;

    outFinal = colorFinal;
    outFinalPrev = vec4(colorFinal, counter);
    outDepthPrev = depthFinal;
}
