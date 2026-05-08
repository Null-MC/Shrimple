#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE TEX_FINAL

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_trans
    #define MAT_PROJ_INV matProjInv
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_INV gbufferProjectionInverse
#endif


layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

layout(rgba16f) uniform writeonly image2D IMG_FINAL;

uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_SOURCE;
uniform sampler2D texBlurred;

uniform float near;
uniform float farPlane;
uniform float nearPlane;
uniform int isEyeInWater;
uniform float blindness;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec2 viewSizeScaled;

#ifndef LOD_ENABLED
    #include "/lib/sampling/depth.glsl"
#endif


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    vec3 src = texelFetch(TEX_SOURCE, uv, 0).rgb;

    ivec2 uv_blur = uv / 2;
    uv_blur.y += int(viewSizeScaled.y)/2;
    vec3 blurred = texelFetch(texBlurred, uv_blur, 0).rgb;

    #ifdef LOD_ENABLED
        depth = near / depth;
    #else
        depth = linearizeDepth(fma(depth, 2.0, -1.0), nearPlane, farPlane);
    #endif

    const float waterBlurRate = 0.080;
    const float airBlurRate = 0.0;// 0.002;
    float rate = isEyeInWater == 1 ? waterBlurRate : airBlurRate;
    float blurF = saturate(depth * rate);

    blurF = max(blurF, blindness);

    vec3 color = mix(src, blurred, blurF);

    imageStore(IMG_FINAL, uv, vec4(color, 1.0));
}
