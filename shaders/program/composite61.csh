#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(rgba16f) uniform writeonly image2D IMG_FINAL;
layout(rgba16f) uniform writeonly image2D imgTAA_prev;

#if TAA_SHARPNESS != 0
    shared vec3 sharedBuffer[18*18];
#endif

uniform sampler2D texTAA;

uniform vec2 viewSize;


#if TAA_SHARPNESS != 0
    int getSharedIndex(const in ivec2 uv) {
        return uv.y * 18 + uv.x;
    }

    void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
        if (i_shared >= (18*18)) return;

        ivec2 uv = uv_base + ivec2(i_shared % 18, i_shared / 18);
        sharedBuffer[i_shared] = texelFetch(texTAA, uv, 0).rgb;
    }
#endif


void main() {
    #if TAA_SHARPNESS != 0
        // preload shared memory
        uint i_base = gl_LocalInvocationIndex * 2u;
        ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 1;

        copyToShared(uv_base, i_base + 0);
        copyToShared(uv_base, i_base + 1);

        memoryBarrierShared();
        barrier();
    #endif

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (all(lessThan(uv, viewSize))) {
        #if TAA_SHARPNESS != 0
            // Simplified version of "slow" CAS without upscaling or better diagonals
            // https://github.com/GPUOpen-Effects/FidelityFX-CAS/blob/master/ffx-cas/ffx_cas.h#L423

            const float peak = -1.0 / mix(8.0, 5.0, TAA_SHARPNESS * 0.01);

            ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;
            vec3 b = sharedBuffer[getSharedIndex(luv + ivec2( 0,-1))];
            vec3 d = sharedBuffer[getSharedIndex(luv + ivec2(-1, 0))];
            vec3 e = sharedBuffer[getSharedIndex(luv)];
            vec3 f = sharedBuffer[getSharedIndex(luv + ivec2( 1, 0))];
            vec3 h = sharedBuffer[getSharedIndex(luv + ivec2( 0, 1))];

            vec3 area_min = min(min(min(min(d, e), f), b), h);
            vec3 area_max = max(max(max(max(d, e), f), b), h);

            vec3 amp = min(area_min, 1.0 - area_max) / area_max;
            vec3 weight = sqrt(saturate(amp)) * peak;

            vec3 weight_inv = 1.0 / (4.0*weight + 1.0);
            vec3 color = ((b + d + f + h) * weight + e) * weight_inv;
            color = max(color, vec3(0.0));
        #else
            vec3 color = texelFetch(texTAA, uv, 0).rgb;
            vec3 e = color;
        #endif

        imageStore(IMG_FINAL, uv, vec4(color, 1.0));
        imageStore(imgTAA_prev, uv, vec4(e, 1.0));
    }
}
