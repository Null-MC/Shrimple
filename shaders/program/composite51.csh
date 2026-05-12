#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE colortex9


layout (local_size_x = 16, local_size_y = 16) in;

#if RENDER_SCALE == 3
    const vec2 workGroupsRender = vec2(0.25, 0.25);
#elif RENDER_SCALE == 2
    const vec2 workGroupsRender = vec2(0.50, 0.50);
#elif RENDER_SCALE == 1
    const vec2 workGroupsRender = vec2(0.75, 0.75);
#else
    const vec2 workGroupsRender = vec2(1.00, 1.00);
#endif

const int sharedSize = 22*22;
shared vec4 sharedColorSize[sharedSize];

layout(rgba16f) uniform writeonly image2D IMG_FINAL;

uniform sampler2D TEX_SOURCE;

uniform vec2 viewSizeScaled;
uniform int isEyeInWater = 0;
uniform float blindness = 0.0;


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 22 + uv.x;
}

void copyToShared(in ivec2 uv_base, const in int i_shared) {
    if (i_shared >= sharedSize) return;

    ivec2 uv = uv_base + ivec2(i_shared % 22, i_shared / 22);
    uv = clamp(uv, ivec2(0), ivec2(viewSizeScaled)-1);

    sharedColorSize[i_shared] = texelFetch(TEX_SOURCE, uv, 0);
}

vec3 SampleBlur() {
    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 3;
//    float size = sharedColorSize[getSharedIndex(luv)].w;

    vec3 accum = vec3(0.0);
    float total = 0.0;
    for (int iy = -3; iy <= 3; iy++) {
        for (int ix = -3; ix <= 3; ix++) {
            ivec2 sampleOffset = ivec2(ix, iy);
            int shared_i = getSharedIndex(luv + sampleOffset);
            vec4 sampleColorSize = sharedColorSize[shared_i];

            float radius = length(sampleOffset);
            float weight = smoothstep(radius-0.5, radius+0.5, sampleColorSize.w);

            accum += weight * sampleColorSize.rgb;
            total += weight;
        }
    }

    if (total > EPSILON) accum /= total;

    return accum;
}


void main() {
    #ifndef EFFECT_BLUR_DOF
        bool skip = true;
        if (isEyeInWater == 1) skip = false;
        if (blindness > 0.0) skip = false;
        if (skip) return;
    #endif

    int pre_i = int(gl_LocalInvocationIndex) * 2;
    ivec2 pre_uv = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy) - 3;

    copyToShared(pre_uv, pre_i+0);
    copyToShared(pre_uv, pre_i+1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

    vec3 color = SampleBlur();

    imageStore(IMG_FINAL, uv, vec4(color, 1.0));
}
