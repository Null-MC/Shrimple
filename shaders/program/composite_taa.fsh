#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_FINAL_PREV;
uniform sampler2D BUFFER_VELOCITY;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex1;
#endif

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float farPlane;
uniform int frameCounter;
uniform float frameTime;

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
#include "/lib/sampling/catmull-rom.glsl"
#include "/lib/effects/taa_jitter.glsl"

vec3 getReprojectedClipPos(const in vec2 texcoord, const in float depthNow, const in vec3 velocity, const in bool isDepthDh) {
    vec3 clipPos = vec3(texcoord, depthNow) * 2.0 - 1.0;

    #ifdef DISTANT_HORIZONS
        // vec3 viewPos = unproject(dhProjectionFullInv, clipPos);

        vec3 viewPos = unproject(isDepthDh ? dhProjectionInverse : gbufferProjectionInverse, clipPos);
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
    #endif

    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 localPosPrev = localPos - velocity + (cameraPosition - previousCameraPosition);

    vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);

    #ifdef DISTANT_HORIZONS
        // vec3 clipPosPrev = unproject(dhProjectionFullPrev, viewPosPrev);

        vec3 clipPosPrev = unproject(isDepthDh ? dhPreviousProjection : gbufferPreviousProjection, viewPosPrev);
    #else
        vec3 clipPosPrev = unproject(gbufferPreviousProjection, viewPosPrev);
    #endif

    return clipPosPrev * 0.5 + 0.5;
}

#include "/lib/effects/taa.glsl"


/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec3 outFinal;
layout(location = 1) out vec4 outFinalPrev;

void main() {
    vec4 colorFinal = ApplyTAA(texcoord);

    outFinal = colorFinal.rgb;

    outFinalPrev = colorFinal;
}
