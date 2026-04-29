#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

#if   BLOOM_TILE == 0
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#elif BLOOM_TILE == 1
    const vec2 workGroupsRender = vec2(0.25, 0.25);
#elif BLOOM_TILE == 2
    const vec2 workGroupsRender = vec2(0.125, 0.125);
#elif BLOOM_TILE == 3
    const vec2 workGroupsRender = vec2(0.0625, 0.0625);
#elif BLOOM_TILE == 4
    const vec2 workGroupsRender = vec2(0.03125, 0.03125);
#elif BLOOM_TILE == 5
    const vec2 workGroupsRender = vec2(0.015625, 0.015625);
#elif BLOOM_TILE == 6
    const vec2 workGroupsRender = vec2(0.0078125, 0.0078125);
#elif BLOOM_TILE == 7
    const vec2 workGroupsRender = vec2(0.00390625, 0.00390625);
#endif

layout(rgba16f) uniform writeonly image2D IMG_BLOOM_TILES;
//layout(rgba16f) uniform writeonly image2D imgBlurTiles;

shared vec3 sharedCenter[17*17];
shared vec3 sharedNeighbor[18*18];

uniform sampler2D TEX_SOURCE;

uniform vec2 viewSize;

#include "/lib/bloom.glsl"


int getSharedCenterIndex(const in ivec2 uv) {
    return uv.y * 17 + uv.x;
}

int getSharedNeighborIndex(const in ivec2 uv) {
    return uv.y * 18 + uv.x;
}

void copyToSharedCenter(const in vec2 uv_base, const in uint i_shared) {
    if (i_shared >= (17*17)) return;

    vec2 uv = uv_base + 2*ivec2(i_shared % 17, i_shared / 17);

    vec2 texcoord = uv / viewSize;
    // TODO: apply clamping!
    sharedCenter[i_shared] = texture(TEX_SOURCE, texcoord).rgb;
}

void copyToSharedNeighbor(const in vec2 uv_base, const in uint i_shared) {
    if (i_shared >= (18*18)) return;

    vec2 uv = uv_base + 2*ivec2(i_shared % 18, i_shared / 18) + 1;

    vec2 texcoord = uv / viewSize;
    // TODO: apply clamping!
    sharedNeighbor[i_shared] = texture(TEX_SOURCE, texcoord).rgb;
}

void main() {
    // preload shared memory
    vec2 src_pos = vec2(0.0);
    #if BLOOM_TILE > 0
        src_pos = GetBloomTileInnerPosition(BLOOM_TILE-1) * viewSize;
    #endif

    int i_center = int(gl_LocalInvocationIndex) * 2;
    vec2 uv_center = src_pos + gl_WorkGroupID.xy * 32.0 - 0.5;

    copyToSharedCenter(uv_center, i_center + 0);
    copyToSharedCenter(uv_center, i_center + 1);

    int i_neighbor = int(gl_LocalInvocationIndex) * 2;
    vec2 uv_neighbor = src_pos + gl_WorkGroupID.xy * 32.0 - 1.5;

    copyToSharedNeighbor(uv_neighbor, i_neighbor + 0);
    copyToSharedNeighbor(uv_neighbor, i_neighbor + 1);

    barrier();

    // exit early if OOB
    ivec2 local_uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 outputSize = ivec2(ceil(viewSize / exp2(BLOOM_TILE+1)));
    if (any(greaterThanEqual(local_uv, outputSize))) return;

    ivec2 neightbor_local_uv = ivec2(gl_LocalInvocationID.xy) + 1;

    vec3 a = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(-1, +1))];
    vec3 b = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2( 0, +1))];
    vec3 c = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(+1, +1))];

    vec3 d = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(-1,  0))];
    vec3 e = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2( 0,  0))];
    vec3 f = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(+1,  0))];

    vec3 g = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(-1, -1))];
    vec3 h = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2( 0, -1))];
    vec3 i = sharedNeighbor[getSharedNeighborIndex(neightbor_local_uv + ivec2(+1, -1))];

    ivec2 center_local_uv = ivec2(gl_LocalInvocationID.xy);

    vec3 j = sharedCenter[getSharedCenterIndex(center_local_uv + ivec2(0, 1))];
    vec3 k = sharedCenter[getSharedCenterIndex(center_local_uv + ivec2(1, 1))];
    vec3 l = sharedCenter[getSharedCenterIndex(center_local_uv + ivec2(0, 0))];
    vec3 m = sharedCenter[getSharedCenterIndex(center_local_uv + ivec2(1, 0))];

    vec3 color;
    color = e*0.125;
    color += (a+c+g+i)*0.03125;
    color += (b+d+f+h)*0.0625;
    color += (j+k+l+m)*0.125;


    vec2 outputPos = GetBloomTileInnerPosition(BLOOM_TILE);
    ivec2 output_uv = local_uv + ivec2(outputPos * viewSize + EPSILON);
    imageStore(IMG_BLOOM_TILES, output_uv, vec4(color, 1.0));
//    imageStore(imgBlurTiles, output_uv, vec4(color, 1.0));
}
