#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

#if LIGHTING_VOXEL_SIZE == 256
    const ivec3 workGroups = ivec3(32, 32, 32);
#elif LIGHTING_VOXEL_SIZE == 128
    const ivec3 workGroups = ivec3(16, 16, 16);
#elif LIGHTING_VOXEL_SIZE == 64
    const ivec3 workGroups = ivec3(8, 8, 8);
#endif

const float LpvFalloff = 0.998;
//const float LpvBlockRange = LIGHTING_FLOODFILL_RANGE;


shared uint voxelSharedData[10*10*10];
shared vec4 lpvBuffer[10*10*10];

layout(rgba8) uniform image3D imgFloodFill;

uniform usampler3D texVoxels;
uniform sampler2D texBlockLight;
uniform usampler2D texBlockMask;

uniform int frameCounter;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

//#include "/lib/oklab.glsl"
#include "/lib/voxel.glsl"
#include "/lib/blocks.glsl"
#include "/lib/sampling/block-light.glsl"
#include "/lib/sampling/block-mask.glsl"


bool IsLightBlock(const in uint blockId) {
//    #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
//        return blockId == BLOCK_LAVA
//            || blockId == BLOCK_CAVEVINE_BERRIES;
//    #else
        return blockId > 0u && blockId < 65535u;
//    #endif
}

vec3 toExp2(const in vec3 color) {
    float lum_now = luminance(color);
    if (lum_now < EPSILON) return color;

    float lum_tgt = exp2(lum_now * LIGHTING_FLOODFILL_RANGE) - 1.0;
    return color * (lum_tgt / lum_now);
}

vec3 fromExp2(const in vec3 color) {
    float lum_now = luminance(color);
    if (lum_now < EPSILON) return color;

    float lum_tgt = log2(lum_now + 1.0) / LIGHTING_FLOODFILL_RANGE;
    return color * (lum_tgt / lum_now);
}

vec4 GetLpvValue(in ivec3 texcoord) {
    if (!IsInVoxelBounds(texcoord)) return vec4(0.0);

    if (frameCounter % 2 == 0)
        texcoord.z += LIGHTING_VOXEL_SIZE;

    vec4 color = imageLoad(imgFloodFill, texcoord);
    color.rgb = RGBToLinear(color.rgb);
    return color;
}

const ivec3 lpvFlatten = ivec3(1, 10, 100);

int getSharedCoord(const in ivec3 pos) {
    return sumOf(pos * lpvFlatten);
}

ivec3 GetVoxelFrameOffset() {
    return ivec3(floor(cameraPosition)) - ivec3(floor(previousCameraPosition));
}

vec4 sampleShared(const in ivec3 pos, const in int mask_index, out float weight) {
    int shared_index = getSharedCoord(pos + 1);

    //float mixWeight = 1.0;
    uint mixMask = 0xFFFF;
    uint blockId = voxelSharedData[shared_index];
    weight = 1.0;

//    if (blockId > 0u && blockId < 65000u) {
//        ivec2 blockMaskUV = ivec2(blockId % 256, blockId / 256);
//        uint maskData = texelFetch(texBlockMask, blockMaskUV, 0).r;
//        mixWeight = unpackUnorm4x8(maskData).r;
//        mixMask = bitfieldExtract(maskData, 8, 8);
//    }

    vec4 color = lpvBuffer[shared_index];
    uint wMask = bitfieldExtract(mixMask, mask_index, 1);
    color *= wMask;// * mixWeight;
    return color;
}

vec3 mixNeighboursDirect(const in ivec3 fragCoord, const in uint mask) {
    uvec3 m1 = (uvec3(mask) >> uvec3(0, 2, 4)) & uvec3(1u);
    uvec3 m2 = (uvec3(mask) >> uvec3(1, 3, 5)) & uvec3(1u);

    vec3 w1, w2;
    vec3 nX1 = sampleShared(fragCoord + ivec3(-1,  0,  0), 1, w1.x).rgb * m1.x;
    vec3 nX2 = sampleShared(fragCoord + ivec3( 1,  0,  0), 0, w2.x).rgb * m2.x;
    vec3 nY1 = sampleShared(fragCoord + ivec3( 0, -1,  0), 3, w1.y).rgb * m1.y;
    vec3 nY2 = sampleShared(fragCoord + ivec3( 0,  1,  0), 2, w2.y).rgb * m2.y;
    vec3 nZ1 = sampleShared(fragCoord + ivec3( 0,  0, -1), 5, w1.z).rgb * m1.z;
    vec3 nZ2 = sampleShared(fragCoord + ivec3( 0,  0,  1), 4, w2.z).rgb * m2.z;

    const float wMaxInv = 1.0 / 6.0;//max(sumOf(w1 + w2), 1.0);
    float avgFalloff = wMaxInv * LpvFalloff;
    return (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * avgFalloff;

//    vec3 c1 = LinearToLab(nX1);
//    vec3 c2 = LinearToLab(nX2);
//    vec3 c3 = LinearToLab(nY1);
//    vec3 c4 = LinearToLab(nY2);
//    vec3 c5 = LinearToLab(nZ1);
//    vec3 c6 = LinearToLab(nZ2);
//    vec3 cf = (c1+c2+c3+c4+c5+c6) * avgFalloff;
//    return LabToLinear(cf);
}

void copyToShared(const in ivec3 imgCoordOffset, const in uint i) {
    ivec3 workGroupOffset = ivec3(gl_WorkGroupID * gl_WorkGroupSize) - 1;
    ivec3 pos = workGroupOffset + ivec3(i / lpvFlatten) % 10;

    ivec3 lpvPos = imgCoordOffset + pos;
    vec4 color = GetLpvValue(lpvPos);
    color.rgb = toExp2(color.rgb);
    lpvBuffer[i] = color;

    uint blockId = 0u;
    if (IsInVoxelBounds(pos))
        blockId = texelFetch(texVoxels, pos, 0).r;

    voxelSharedData[i] = blockId;
}

void PopulateShared() {
    uint i1 = uint(gl_LocalInvocationIndex) * 2u;
    if (i1 >= 1000u) return;

    uint i2 = i1 + 1u;
    ivec3 imgCoordOffset = GetVoxelFrameOffset();

    copyToShared(imgCoordOffset, i1);
    copyToShared(imgCoordOffset, i2);
}

void main() {
    uvec3 chunkPos = gl_WorkGroupID * gl_WorkGroupSize;
    if (any(greaterThanEqual(chunkPos, VoxelBufferSize))) return;

    uint i_base = uint(gl_LocalInvocationIndex) * 2u;
    if (i_base < 1000u) {
        ivec3 imgCoordOffset = GetVoxelFrameOffset();

        copyToShared(imgCoordOffset, i_base);
        copyToShared(imgCoordOffset, i_base + 1u);
    }

    memoryBarrierShared();
    barrier();

    ivec3 imgCoord = ivec3(gl_GlobalInvocationID);
    if (any(greaterThanEqual(imgCoord, VoxelBufferSize))) return;

    vec3 viewDir = gbufferModelViewInverse[2].xyz;
    vec3 lpvCenter = GetVoxelCenter(cameraPosition, viewDir);
    vec3 blockLocalPos = imgCoord - lpvCenter + 0.5;

    uint blockId = voxelSharedData[getSharedCoord(ivec3(gl_LocalInvocationID) + 1)];

    vec4 colorFinal = vec4(0.0);

    float mixWeight = 1.0;
    uint mixMask = 0xFFFF;
    vec3 tint = vec3(1.0);

    if (blockId > 0u && blockId < USHORT_MAX) {
        GetBlockMask(blockId, mixWeight, mixMask);
    }

    float _w;
    colorFinal.a = lpvBuffer[getSharedCoord(ivec3(gl_LocalInvocationID) + ivec3(1,2,1))].a;
    colorFinal.a = max(colorFinal.a, 1.0 - mixWeight);
    if (blockId == BLOCK_GLASS) colorFinal.a = 1.0;
    //uint blockId_up = voxelSharedData[getSharedCoord(ivec3(gl_LocalInvocationID) + ivec3(1,2,1))];
//    if (blockId_up != 0u) colorFinal.a = 0.0;

    vec3 lightColor = vec3(0.0);
    float lightRange = 0.0;
    if (IsLightBlock(blockId)) {
        GetBlockColorRange(blockId, lightColor, lightRange);
    }

    if (blockId >= BLOCK_HONEY && blockId <= BLOCK_TINTED_GLASS) {
        tint = lightColor;//GetLightGlassTint(blockId);
//        mixWeight = 1.0;
    }

    if (mixWeight > EPSILON) {
        vec3 lightMixed = mixNeighboursDirect(ivec3(gl_LocalInvocationID), mixMask);
        lightMixed *= mixWeight * tint;
        colorFinal.rgb += lightMixed;
    }

    if (lightRange > 0.0) {
        vec3 newLight = lightColor * (lightRange / 15.0);
        colorFinal.rgb += toExp2(newLight);
    }

    colorFinal.rgb = fromExp2(colorFinal.rgb);
    colorFinal.rgb = LinearToRGB(colorFinal.rgb);
//    colorFinal.a = saturate(colorFinal.a / 15.0);

    if (frameCounter % 2 == 1) imgCoord.z += LIGHTING_VOXEL_SIZE;
    imageStore(imgFloodFill, imgCoord, colorFinal);
}
