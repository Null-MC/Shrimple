#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define CAS_BETTER_DIAGONALS

#if RENDER_SCALE != 0
    //#define CAS_SCALING_ENABLED
#endif

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(rgba16f) uniform writeonly image2D IMG_FINAL;
layout(rgba16f) uniform writeonly image2D imgTAA_prev;

#if TAA_SHARPNESS != 0
    #ifdef CAS_SCALING_ENABLED
        #define SHARED_RES 19
    #else
        #define SHARED_RES 18
    #endif

    shared vec3 sharedBuffer[SHARED_RES*SHARED_RES];
#endif

uniform sampler2D texTAA;

uniform vec2 viewSize;
uniform vec2 viewSizeScaled;


#if TAA_SHARPNESS != 0
    int getSharedIndex(const in ivec2 uv) {
        return uv.y * SHARED_RES + uv.x;
    }

    void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
        if (i_shared >= (SHARED_RES*SHARED_RES)) return;

        ivec2 uv = uv_base + ivec2(i_shared % SHARED_RES, i_shared / SHARED_RES);
        sharedBuffer[i_shared] = texelFetch(texTAA, uv, 0).rgb;
    }

    // Simplified version of "slow" CAS without upscaling or better diagonals
    // https://github.com/GPUOpen-Effects/FidelityFX-CAS/blob/master/ffx-cas/ffx_cas.h#L423

    #ifdef CAS_BETTER_DIAGONALS
        const float CAS_AMP = 2.0;
    #else
        const float CAS_AMP = 1.0;
    #endif

    #ifdef CAS_SCALING_ENABLED
        void apply_CAS(const in float peak, out vec3 color, out vec3 f) {
            ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;

            vec3 a, b, c, d, e, g, h, i, j, k, l, m, n, o, p;
            a = sharedBuffer[getSharedIndex(luv + ivec2(-1,-1))];
            b = sharedBuffer[getSharedIndex(luv + ivec2( 0,-1))];
            c = sharedBuffer[getSharedIndex(luv + ivec2( 1,-1))];
            d = sharedBuffer[getSharedIndex(luv + ivec2( 2,-1))];

            e = sharedBuffer[getSharedIndex(luv + ivec2(-1, 0))];
            f = sharedBuffer[getSharedIndex(luv)];
            g = sharedBuffer[getSharedIndex(luv + ivec2( 1, 0))];
            h = sharedBuffer[getSharedIndex(luv + ivec2( 2, 0))];

            i = sharedBuffer[getSharedIndex(luv + ivec2(-1, 1))];
            j = sharedBuffer[getSharedIndex(luv + ivec2( 0, 1))];
            k = sharedBuffer[getSharedIndex(luv + ivec2( 1, 1))];
            l = sharedBuffer[getSharedIndex(luv + ivec2( 2, 1))];

            m = sharedBuffer[getSharedIndex(luv + ivec2(-1, 2))];
            n = sharedBuffer[getSharedIndex(luv + ivec2( 0, 2))];
            o = sharedBuffer[getSharedIndex(luv + ivec2( 1, 2))];
            p = sharedBuffer[getSharedIndex(luv + ivec2( 2, 2))];

            vec3 area_min_f = min(min(min(min(b, e), f), g), j);
            vec3 area_max_f = max(max(max(max(b, e), f), g), j);

            #ifdef CAS_BETTER_DIAGONALS
                area_min_f += min(min(min(min(area_min_f, a), c), i), k);
                area_max_f += max(max(max(max(area_max_f, a), c), i), k);
            #endif

            vec3 area_min_g = min(min(min(min(c, f), g), h), k);
            vec3 area_max_g = max(max(max(max(c, f), g), h), k);

            #ifdef CAS_BETTER_DIAGONALS
                area_min_g += min(min(min(min(area_min_g, b), d), j), l);
                area_max_g += max(max(max(max(area_max_g, b), d), j), l);
            #endif

            vec3 area_min_j = min(min(min(min(f, i), j), k), n);
            vec3 area_max_j = max(max(max(max(f, i), j), k), n);

            #ifdef CAS_BETTER_DIAGONALS
                area_min_j += min(min(min(min(area_min_j, e), g), m), o);
                area_max_j += max(max(max(max(area_max_j, e), g), m), o);
            #endif

            vec3 area_min_k = min(min(min(min(g, j), k), l), o);
            vec3 area_max_k = max(max(max(max(g, j), k), l), o);

            #ifdef CAS_BETTER_DIAGONALS
                area_min_k += min(min(min(min(area_min_k, f), h), n), p);
                area_max_k += max(max(max(max(area_max_k, f), h), n), p);
            #endif

            // Smooth minimum distance to signal limit divided by smooth max.
            vec3 amp_f = saturate(min(area_min_f, CAS_AMP - area_max_f) / area_max_f);
            vec3 amp_g = saturate(min(area_min_g, CAS_AMP - area_max_g) / area_max_g);
            vec3 amp_j = saturate(min(area_min_j, CAS_AMP - area_max_j) / area_max_j);
            vec3 amp_k = saturate(min(area_min_k, CAS_AMP - area_max_k) / area_max_k);

            // Shaping amount of sharpening.
            amp_f = sqrt(amp_f);
            amp_g = sqrt(amp_g);
            amp_j = sqrt(amp_j);
            amp_k = sqrt(amp_k);

            // Filter shape.
            vec3 w_f = amp_f * peak;
            vec3 w_g = amp_g * peak;
            vec3 w_j = amp_j * peak;
            vec3 w_k = amp_k * peak;

            // Blend between 4 results.
            vec2 offset = 0.5 * viewSizeScaled / viewSize - 0.5;
            vec2 pp = fract(gl_GlobalInvocationID.xy * RENDER_SCALE_F + offset);
//            vec2 pp = gl_GlobalInvocationID.xy * RENDER_SCALE_F + offset;
//            pp -= floor(pp);

            float s = (1.0 - pp.x) * (1.0 - pp.y);
            float t =        pp.x  * (1.0 - pp.y);
            float u = (1.0 - pp.x) *        pp.y ;
            float v =        pp.x  *        pp.y ;

            // Thin edges to hide bilinear interpolation (helps diagonals).
            float thinB = 1.0/32.0;

            s *= 1.0 / ((area_max_f.g - area_min_f.g) + thinB);
            t *= 1.0 / ((area_max_g.g - area_min_g.g) + thinB);
            u *= 1.0 / ((area_max_j.g - area_min_j.g) + thinB);
            v *= 1.0 / ((area_max_k.g - area_min_k.g) + thinB);

            // Final weighting.
            vec3 qbe = w_f * s;
            vec3 qch = w_g * t;
            vec3 qf = w_g * t + w_j * u + s;
            vec3 qg = w_f * s + w_k * v + t;
            vec3 qj = w_f * s + w_k * v + u;
            vec3 qk = w_g * t + w_j * u + v;
            vec3 qin = w_j * u;
            vec3 qlo = w_k * v;

            // Filter.
            vec3 weight = 2.0 * (qbe + qch + qin + qlo) + qf + qg + qj + qk;

            color = (b * qbe + e * qbe + c * qch + h * qch + i * qin + n * qin + l * qlo + o * qlo + f * qf + g * qg + j * qj + k * qk) / weight;
        }
    #else
        void apply_CAS(const in float peak, out vec3 color, out vec3 e) {
            ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;

            vec3 b, d, f, h;
            b = sharedBuffer[getSharedIndex(luv + ivec2( 0,-1))];
            d = sharedBuffer[getSharedIndex(luv + ivec2(-1, 0))];
            e = sharedBuffer[getSharedIndex(luv)];
            f = sharedBuffer[getSharedIndex(luv + ivec2( 1, 0))];
            h = sharedBuffer[getSharedIndex(luv + ivec2( 0, 1))];

            #ifdef CAS_BETTER_DIAGONALS
                vec3 a, c, g, i;
                a = sharedBuffer[getSharedIndex(luv + ivec2(-1,-1))];
                c = sharedBuffer[getSharedIndex(luv + ivec2( 1,-1))];
                g = sharedBuffer[getSharedIndex(luv + ivec2(-1, 1))];
                i = sharedBuffer[getSharedIndex(luv + ivec2( 1, 1))];
            #endif

            vec3 area_min = min(min(min(min(d, e), f), b), h);
            vec3 area_max = max(max(max(max(d, e), f), b), h);

            #ifdef CAS_BETTER_DIAGONALS
                area_min += min(min(min(min(area_min, a), c), g), i);
                area_max += max(max(max(max(area_max, a), c), g), i);
            #endif

            // Smooth minimum distance to signal limit divided by smooth max.
            vec3 amp = min(area_min, CAS_AMP - area_max) / area_max;

            // Filter shape.
            vec3 weight = sqrt(saturate(amp)) * peak;

            // Filter.
            vec3 weight_inv = 1.0 / (4.0*weight + 1.0);
            color = ((b + d + f + h) * weight + e) * weight_inv;
        }
    #endif
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
        vec3 outFinal, outPrev;
        #if TAA_SHARPNESS != 0
            const float sharpnessF = TAA_SHARPNESS * 0.01;
            const float peak = -1.0 / mix(8.0, 5.0, sharpnessF);

            apply_CAS(peak, outFinal, outPrev);
        #else
            outPrev = outFinal = texelFetch(texTAA, uv, 0).rgb;
        #endif

        outFinal = max(outFinal, vec3(0.0));

        imageStore(IMG_FINAL, uv, vec4(outFinal, 1.0));
        imageStore(imgTAA_prev, uv, vec4(outPrev, 1.0));
    }
}
