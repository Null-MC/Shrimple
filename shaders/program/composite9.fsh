#define RENDER_TRANSLUCENT_POST_BLUR
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

const bool colortex0MipmapEnabled = true;

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D BUFFER_FINAL;
//uniform sampler2D BUFFER_OVERLAY_DEPTH;

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float skyRainStrength;

// #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
//     uniform float centerDepthSmooth;
// #endif

#ifdef WORLD_WATER_ENABLED
    uniform float waterDensitySmooth;
#endif

#if EFFECT_BLUR_RADIUS_BLIND > 0
    uniform float blindnessSmooth;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/effects/blur.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, uv, 0).r;
    //float depth = textureLod(depthtex0, texcoord, 0.0).r;

    // float weatherDepth = texelFetch(BUFFER_OVERLAY_DEPTH, uv, 0).r;
    // depth = min(depth, weatherDepth);

    float depthL = linearizeDepthFast(depth, near, far);

    vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
    float viewDist = length(viewPos);

    vec3 color = GetBlur(depthtex0, texcoord, depthL, 0.0, viewDist, isEyeInWater == 1);

    outFinal = vec4(color, 1.0);
}
