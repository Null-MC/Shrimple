#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_REFLECT texReflect
#define TEX_DEPTH depthtex0


layout (local_size_x = 16, local_size_y = 16) in;

const vec2 workGroupsRender = vec2(RENDER_SCALE_F, RENDER_SCALE_F);

//#if RENDER_SCALE == 3
//    const vec2 workGroupsRender = vec2(0.25, 0.25);
//#elif RENDER_SCALE == 2
//    const vec2 workGroupsRender = vec2(0.50, 0.50);
//#elif RENDER_SCALE == 1
//    const vec2 workGroupsRender = vec2(0.75, 0.75);
//#else
//    const vec2 workGroupsRender = vec2(1.00, 1.00);
//#endif

const int sharedSize = 22*22;
shared vec4 sharedColorRough[sharedSize];
shared float sharedDepth[sharedSize];

layout(rgba16f) uniform writeonly image2D IMG_FINAL;
layout(rgba16f) uniform writeonly image2D imgReflectHistory;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_REFLECT;
uniform sampler2D TEX_DEPTH;

uniform vec2 viewSizeScaled;

#include "/lib/sampling/gaussian.glsl"


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 22 + uv.x;
}

void copyToShared(in ivec2 uv_base, const in int i_shared) {
    if (i_shared >= sharedSize) return;

    ivec2 uv = uv_base + ivec2(i_shared % 22, i_shared / 22);
    uv = clamp(uv, ivec2(0), ivec2(viewSizeScaled)-1);

    sharedColorRough[i_shared] = texelFetch(TEX_REFLECT, uv, 0);
    sharedDepth[i_shared] = texelFetch(TEX_DEPTH, uv, 0).r;
}

vec3 SampleBlur(const in float roughL) {
    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 3;

    float sigma_xy = mix(1.0, 9.0, roughL);

    vec3 accum = vec3(0.0);
    float total = 0.0;
    for (int iy = -3; iy <= 3; iy++) {
        float wy = gaussian(sigma_xy, iy);

        for (int ix = -3; ix <= 3; ix++) {
            float wx = gaussian(sigma_xy, ix);

            ivec2 sampleOffset = ivec2(ix, iy);

            int shared_i = getSharedIndex(luv + sampleOffset);
            vec4 sampleColorRough = sharedColorRough[shared_i];

            float sample_roughL = _pow2(sampleColorRough.w);
//            float wr = step(roughL, sample_roughL);
            float wr = float(roughL == sample_roughL);

            // TODO
            float weight = wx * wy * wr;

            accum += weight * sampleColorRough.rgb;
            total += weight;
        }
    }

    if (total > EPSILON) accum /= total;

    return accum;
}


void main() {
    int pre_i = int(gl_LocalInvocationIndex) * 2;
    ivec2 pre_uv = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy) - 3;

    copyToShared(pre_uv, pre_i+0);
    copyToShared(pre_uv, pre_i+1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

    vec3 color_src = texelFetch(TEX_FINAL, uv, 0).rgb;

    vec4 centerColorRough = sharedColorRough[getSharedIndex(ivec2(gl_LocalInvocationID.xy) + 3)];
//    imageStore(imgReflectHistory, uv, vec4(centerColorRough.rgb, 1.0));

    float roughL = _pow2(centerColorRough.w);
    vec3 color_reflect = SampleBlur(roughL);

//    color_reflect = mix(centerColorRough.rgb, color_reflect, centerColorRough.w);

    // TODO: FOR TESTING ONLY
//    color_reflect = centerColorRough.rgb;

    #ifdef LIGHTING_REFLECT_ROUGHNESS
        imageStore(imgReflectHistory, uv, vec4(centerColorRough.rgb, 1.0));
    #endif

    float smoothL = 1.0 - roughL;
    color_reflect *= _pow2(smoothL);

    vec3 color_final = color_src + color_reflect;

    imageStore(IMG_FINAL, uv, vec4(color_final, 1.0));
}
