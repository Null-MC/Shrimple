#include "/lib/constants.glsl"
#include "/lib/common.glsl"

const ivec2 textureSize = ivec2(WaterNormalResolution);

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 16, 1);

layout(rgba8) uniform writeonly image2D IMG_WATER_NORMAL;

shared float sharedHeight[18*18];


uniform sampler2D texWaterHeight;


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 18 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (18*18)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 18, i_shared / 18);
    sharedHeight[i_shared] = texelFetch(texWaterHeight, clamp(uv, ivec2(0), textureSize-1), 0).r;
//    sharedHeight[i_shared] = texelFetch(texWaterHeight, (uv + textureSize) % textureSize, 0).r;
}

vec3 ComputeNormal() {
    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;

    float x1 = sharedHeight[getSharedIndex(luv - ivec2(1, 0))];
    float x2 = sharedHeight[getSharedIndex(luv + ivec2(1, 0))];
    float y1 = sharedHeight[getSharedIndex(luv - ivec2(0, 1))];
    float y2 = sharedHeight[getSharedIndex(luv + ivec2(0, 1))];

    const float strength = 20.0;
    return normalize(vec3(x1 - x2, 2.0 / strength, y1 - y2));
}


void main() {
    // preload shared memory
    int i_base = int(gl_LocalInvocationIndex) * 2;
    ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 1;

    copyToShared(uv_base, i_base + 0);
    copyToShared(uv_base, i_base + 1);

    memoryBarrierShared();
    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, textureSize))) return;

    vec3 normal = ComputeNormal();

    imageStore(IMG_WATER_NORMAL, uv, vec4(normal.xzy * 0.5 + 0.5, 1.0));
}
