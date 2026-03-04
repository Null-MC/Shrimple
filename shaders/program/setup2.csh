#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 16, 1);


//const ivec2 cloudSize = ivec2(256);
const ivec2 shadowSize = ivec2(256);

layout(r16f) uniform writeonly image2D imgCloudShadow;

shared float sharedBuffer[20*20];

uniform sampler2D texClouds;


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 20 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (20*20)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 20, i_shared / 20);
    uv = (uv + shadowSize) % shadowSize;
//    sharedBuffer[i_shared] = 1.0 - texelFetch(texClouds, uv, 0).r;
    vec2 texcoord = (uv + 0.5) / shadowSize;
//    vec2 texcoord = vec2(uv) / shadowSize;
    sharedBuffer[i_shared] = 1.0 - texture(texClouds, texcoord).r;
}

float Gaussian(const in float sigma, const in float x) {
    return exp(_pow2(x) / (-2.0 * _pow2(sigma)));
}

float GaussianBlur() {
    const float g_sigma = 1.6;

    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 2;

    float accum = 0.0;
    float total = 0.0;
    for (int iy = -2; iy <= 2; iy++) {
        float fy = Gaussian(g_sigma, iy);

        for (int ix = -2; ix <= 2; ix++) {
            float fx = Gaussian(g_sigma, ix);

            int shared_i = getSharedIndex(luv + ivec2(ix, iy));
            float sampleColor = sharedBuffer[shared_i];

            float weight = fx*fy;
            accum += weight * sampleColor;
            total += weight;
        }
    }

    if (total <= EPSILON) return 1.0;
    return accum / total;
}


void main() {
    // preload shared memory
    int i_base = int(gl_LocalInvocationIndex) * 2;
    ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 2;

    copyToShared(uv_base, i_base + 0);
    copyToShared(uv_base, i_base + 1);

    memoryBarrierShared();
    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, shadowSize))) return;

    float color = GaussianBlur();

    imageStore(imgCloudShadow, uv, vec4(color));
}
