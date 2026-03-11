#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define BLOOM_TILE 0

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(0.5, 0.5);


layout(rgba16f) uniform writeonly image2D IMG_BLOOM;

shared vec3 sharedCenter[17*17];
shared vec3 sharedNeighbor[18*18];

uniform sampler2D BUFFER_FINAL;

uniform vec2 viewSize;

#include "/lib/bloom.glsl"


int getSharedCenterIndex(const in ivec2 uv) {
    return uv.y * 17 + uv.x;
}

int getSharedNeighborIndex(const in ivec2 uv) {
    return uv.y * 18 + uv.x;
}

void copyToSharedCenter(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (17*17)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 17, i_shared / 17);

    vec2 texcoord = (uv + 0.5) / viewSize;
    sharedCenter[i_shared] = texture(BUFFER_FINAL, texcoord).rgb;
}

void copyToSharedNeighbor(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (18*18)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 18, i_shared / 18);

    vec2 texcoord = (uv + 0.5) / viewSize;
    sharedNeighbor[i_shared] = texture(BUFFER_FINAL, texcoord).rgb;
}

void main() {
    // preload shared memory
    int i_center = int(gl_LocalInvocationIndex) * 2;
    vec2 uv_center = gl_WorkGroupID.xy * 16.0 - 0.5;

    copyToSharedCenter(uv_center, i_center + 0);
    copyToSharedCenter(uv_center, i_center + 1);

    int i_neighbor = int(gl_LocalInvocationIndex) * 2;
    vec2 uv_neighbor = gl_WorkGroupID.xy * 16.0 - 0.5;

    copyToShared(uv_base, i_base + 1);

    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSize))) return;




//    const int tile = 0;

    vec2 pixelSize = 1.0 / viewSize;

    vec2 tex = texcoord - (tilePadding + 0.5) * 2.0*pixelSize;
    tex /= 1.0 - (2.0*tilePadding) * 2.0*pixelSize;
    tex += pixelSize;

    outFinal = BloomBoxSample(BUFFER_FINAL, tex, vec2(0.0), viewSize);
}
