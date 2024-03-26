#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_FINAL_PREV;
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
// uniform float far;
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
#include "/lib/effects/taa_jitter.glsl"

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

#include "/lib/effects/taa_epic.glsl"


/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec4 outFinalPrev;

void main() {
    vec4 colorFinal = ApplyTAA(texcoord);

    outFinal = colorFinal.rgb;
    outFinalPrev = colorFinal;
}
