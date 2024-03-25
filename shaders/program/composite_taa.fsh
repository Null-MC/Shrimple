#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_FINAL_PREV;
// uniform sampler2D BUFFER_DEPTH_PREV;
uniform sampler2D BUFFER_VELOCITY;
// uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex1;
#endif

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform int frameCounter;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;
uniform float farPlane;

#ifdef DISTANT_HORIZONS
    uniform mat4 dhModelViewInverse;
    uniform mat4 dhProjectionInverse;
    uniform mat4 dhPreviousModelView;
    uniform mat4 dhPreviousProjection;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/effects/taa.glsl"


#ifdef DISTANT_HORIZONS
vec3 getReprojectedClipPos(const in vec2 texcoord, const in float depthNow, const in vec3 velocity, const in bool isDepthDh)
#else
vec3 getReprojectedClipPos(const in vec2 texcoord, const in float depthNow, const in vec3 velocity, const in bool isDepthDh)
#endif
{
    vec3 clipPos = vec3(texcoord, depthNow) * 2.0 - 1.0;

    #ifdef DISTANT_HORIZONS
        vec3 localPos;
        if (isDepthDh) {
            vec3 viewPos = unproject(dhProjectionInverse, clipPos);
            localPos = mul3(gbufferModelViewInverse, viewPos);
        }
        else {
            #ifdef IRIS_FEATURE_SSBO
                localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
            #else
                vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
                localPos = mul3(gbufferModelViewInverse, viewPos);
            #endif
        }
    #else
        #ifdef IRIS_FEATURE_SSBO
            vec3 localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
        #else
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
        #endif
    #endif

    vec3 localPosPrev = localPos - velocity + cameraPosition - previousCameraPosition;

    #ifdef DISTANT_HORIZONS
        vec3 clipPosPrev;
        if (isDepthDh) {
            vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);
            clipPosPrev = unproject(dhPreviousProjection, viewPosPrev);
        }
        else {
            #ifdef IRIS_FEATURE_SSBO
                clipPosPrev = unproject(gbufferPreviousModelViewProjection, localPosPrev);
            #else
                vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);
                clipPosPrev = unproject(gbufferPreviousProjection, viewPosPrev);
            #endif
        }
    #else
        #ifdef IRIS_FEATURE_SSBO
            vec3 clipPosPrev = unproject(gbufferPreviousModelViewProjection, localPosPrev);
        #else
            vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);
            vec3 clipPosPrev = unproject(gbufferPreviousProjection, viewPosPrev);
        #endif
    #endif

    return clipPosPrev * 0.5 + 0.5;
}

void neighborClampColor(inout vec3 colorPrev, const in vec2 texcoord) {
    vec3 minColor = vec3(999.0);
    vec3 maxColor = vec3(0.0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = vec2(x, y) * pixelSize + texcoord;
            // vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;
            vec3 sampleColor = texelFetch(BUFFER_FINAL, ivec2(sampleCoord * viewSize), 0).rgb;

            minColor = min(minColor, sampleColor);
            maxColor = max(maxColor, sampleColor);
        }
    }
    
    colorPrev = clamp(colorPrev, minColor, maxColor);
}

vec3 sampleHistoryCatmullRom(const in vec2 uv) {
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

    vec3 result = vec3(0.0);

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos0.y), 0).rgb * w0.x * w0.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos0.y), 0).rgb * w12.x * w0.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos0.y), 0).rgb * w3.x * w0.y;

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos12.y), 0).rgb * w0.x * w12.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos12.y), 0).rgb * w12.x * w12.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos12.y), 0).rgb * w3.x * w12.y;

    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos0.x,  texPos3.y), 0).rgb * w0.x * w3.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos12.x, texPos3.y), 0).rgb * w12.x * w3.y;
    result += textureLod(BUFFER_FINAL_PREV, vec2(texPos3.x,  texPos3.y), 0).rgb * w3.x * w3.y;

    return clamp(result, 0.0, 65000.0);
}


/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec3 outFinalPrev;
// layout(location = 2) out float outDepthPrev;

void main() {
    vec2 uvNow = texcoord;

    //vec2 jitter = getJitterOffset(frameCounter);
    vec2 uvNowJitter = uvNow;// - 0.5*jitter;
    //uvNow -= 0.5*jitter;

    float depthNow = textureLod(depthtex1, uvNowJitter, 0).r;
    float depthNowHand = textureLod(depthtex2, uvNowJitter, 0).r;
    bool isHand = abs(depthNow - depthNowHand) > EPSILON;

    if (isHand) {
        depthNow = depthNow * 2.0 - 1.0;
        depthNow /= MC_HAND_DEPTH;
        depthNow = depthNow * 0.5 + 0.5;
    }

    float depthNowL = linearizeDepthFast(depthNow, near, farPlane);
    bool isDepthDh = false;

    #ifdef DISTANT_HORIZONS
        float dhDepth = textureLod(dhDepthTex1, uvNowJitter, 0).r;
        float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

        if (depthNow >= 1.0 || (dhDepthL < depthNowL && dhDepth > 0.0)) {
            depthNow = dhDepth;
            depthNowL = dhDepthL;
            isDepthDh = true;
        }
    #endif

    vec3 colorNow = textureLod(BUFFER_FINAL, uvNow, 0).rgb;
    vec4 velocity = textureLod(BUFFER_VELOCITY, uvNow, 0);

    vec3 clipPosRepro = getReprojectedClipPos(uvNow, depthNow, velocity.xyz, isDepthDh);

    vec2 uvPrev = clipPosRepro.xy;

    #ifdef EFFECT_TAA_SHARPEN
        vec3 colorPrev = sampleHistoryCatmullRom(uvPrev);
    #else
        vec3 colorPrev = textureLod(BUFFER_FINAL_PREV, uvPrev, 0).rgb;
    #endif

    neighborClampColor(colorPrev, uvNow);

    const float weightMax = rcp(EFFECT_TAA_MAX_ACCUM);

    float weight = weightMax;
    if (saturate(uvPrev) != uvPrev) weight = 1.0;
    vec3 colorFinal = mix(colorPrev, colorNow, weight);

    colorFinal = clamp(colorFinal, 0.0, 65000.0);

    outFinal = colorFinal;
    outFinalPrev = colorFinal;
}
