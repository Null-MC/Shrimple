//#define RENDER_TRANSLUCENT_POST_BLUR
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D BUFFER_FINAL;

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
uniform float near;
uniform float far;

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/post/depth_blur.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float depth = textureLod(depthtex0, texcoord, 0).r;
    float depthL = linearizeDepthFast(depth, near, far);

    vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
    float viewDist = length(viewPos);

    float distScale = isEyeInWater == 1
        ? DIST_BLUR_SCALE_WATER : DIST_BLUR_SCALE_AIR;

    vec3 color = GetBlur(texcoord, depthL, viewDist, distScale);

    outFinal = vec4(color, 1.0);
}
