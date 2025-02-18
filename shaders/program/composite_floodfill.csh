#define RENDER_COMPOSITE_LPV
#define RENDER_COMPOSITE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

#if VOXEL_SIZE == 256
    const ivec3 workGroups = ivec3(32, 32, 32);
#elif VOXEL_SIZE == 128
    const ivec3 workGroups = ivec3(16, 16, 16);
#elif VOXEL_SIZE == 64
    const ivec3 workGroups = ivec3(8, 8, 8);
#endif

const float LpvFalloff = 0.998;


#ifdef IS_LPV_ENABLED
    #ifdef LIGHTING_FLICKER
        uniform sampler2D noisetex;
    #endif

    uniform float frameTime;
    uniform int frameCounter;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;

    #ifdef ANIM_WORLD_TIME
        uniform int worldTime;
    #else
        uniform float frameTimeCounter;
    #endif

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/block_voxel.glsl"
    #include "/lib/buffers/light_static.glsl"
    #include "/lib/buffers/volume.glsl"

    #include "/lib/utility/hsv.glsl"

    #include "/lib/voxel/voxel_common.glsl"

    #include "/lib/voxel/lpv/lpv.glsl"
    #include "/lib/voxel/lights/mask.glsl"
    #include "/lib/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"

    #include "/lib/sampling/noise.glsl"

    #ifdef LIGHTING_FLICKER
        #include "/lib/utility/anim.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    #include "/lib/lighting/voxel/lights_render.glsl"
#endif

vec4 GetLpvDirectValue(in ivec3 texCoord) {
    if (!IsInVoxelBounds(texCoord)) return vec4(0.0);

    vec4 lpvSample = (frameCounter % 2) == 0
        ? imageLoad(imgSceneLPV_2, texCoord)
        : imageLoad(imgSceneLPV_1, texCoord);

    lpvSample.rgb = RGBToLinear(lpvSample.rgb);

    vec4 hsv_sky = vec4(RgbToHsv(lpvSample.rgb), lpvSample.a);
    hsv_sky.zw = exp2(hsv_sky.zw * LpvBlockSkyRange) - 1.0;
    lpvSample = vec4(HsvToRgb(hsv_sky.xyz), hsv_sky.w);

    return lpvSample;
}

const ivec3 lpvFlatten = ivec3(1, 10, 100);

shared uint voxelSharedData[10*10*10];
shared vec4 lpvDirectBuffer[10*10*10];

int getSharedCoord(ivec3 pos) {
    return sumOf(pos * lpvFlatten);
}

vec4 sampleDirectShared(ivec3 pos, int mask_index, out float weight) {
    int shared_index = getSharedCoord(pos + 1);

    //float mixWeight = 1.0;
    uint mixMask = 0xFFFF;
    uint blockId = voxelSharedData[shared_index];
    weight = blockId == BLOCK_EMPTY ? 1.0 : 0.0;
    
    if (blockId > 0 && blockId != BLOCK_EMPTY)
        ParseBlockLpvData(StaticBlockMap[blockId].lpv_data, mixMask, weight);

    uint wMask = bitfieldExtract(mixMask, mask_index, 1);
    return lpvDirectBuffer[shared_index] * wMask;// * mixWeight;
}

vec4 mixNeighboursDirect(const in ivec3 fragCoord, const in uint mask) {
    uvec3 m1 = (uvec3(mask) >> uvec3(0, 2, 4)) & uvec3(1u);
    uvec3 m2 = (uvec3(mask) >> uvec3(1, 3, 5)) & uvec3(1u);

    vec3 w1, w2;
    vec4 nX1 = sampleDirectShared(fragCoord + ivec3(-1,  0,  0), 1, w1.x) * m1.x;
    vec4 nX2 = sampleDirectShared(fragCoord + ivec3( 1,  0,  0), 0, w2.x) * m2.x;
    vec4 nY1 = sampleDirectShared(fragCoord + ivec3( 0, -1,  0), 3, w1.y) * m1.y;
    vec4 nY2 = sampleDirectShared(fragCoord + ivec3( 0,  1,  0), 2, w2.y) * m2.y;
    vec4 nZ1 = sampleDirectShared(fragCoord + ivec3( 0,  0, -1), 5, w1.z) * m1.z;
    vec4 nZ2 = sampleDirectShared(fragCoord + ivec3( 0,  0,  1), 4, w2.z) * m2.z;

    const float wMaxInv = rcp(6.0);//max(sumOf(w1 + w2), 1.0);
    float avgFalloff = wMaxInv * LpvFalloff;
    return (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * avgFalloff;
}

void PopulateShared() {
    uint i1 = uint(gl_LocalInvocationIndex) * 2u;
    if (i1 >= 1000u) return;

    uint i2 = i1 + 1u;
    // ivec3 voxelOffset = GetLpvVoxelOffset();
    ivec3 imgCoordOffset = GetVoxelFrameOffset();
    ivec3 workGroupOffset = ivec3(gl_WorkGroupID * gl_WorkGroupSize) - 1;

    ivec3 pos1 = workGroupOffset + ivec3(i1 / lpvFlatten) % 10;
    ivec3 pos2 = workGroupOffset + ivec3(i2 / lpvFlatten) % 10;

    ivec3 lpvPos1 = imgCoordOffset + pos1;
    ivec3 lpvPos2 = imgCoordOffset + pos2;

    lpvDirectBuffer[i1] = GetLpvDirectValue(lpvPos1);
    lpvDirectBuffer[i2] = GetLpvDirectValue(lpvPos2);

    uint blockId1 = BLOCK_EMPTY;
    uint blockId2 = BLOCK_EMPTY;

    if (IsInVoxelBounds(pos1)) {
        blockId1 = imageLoad(imgVoxels, pos1).r;
    }

    if (IsInVoxelBounds(pos2)) {
        blockId2 = imageLoad(imgVoxels, pos2).r;
    }

    voxelSharedData[i1] = blockId1;
    voxelSharedData[i2] = blockId2;
}

void main() {
    #ifdef IS_LPV_ENABLED
        uvec3 chunkPos = gl_WorkGroupID * gl_WorkGroupSize;
        if (any(greaterThanEqual(chunkPos, VoxelBufferSize))) return;

        PopulateShared();

        barrier();

        ivec3 imgCoord = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(imgCoord, VoxelBufferSize))) return;

        vec3 viewDir = gbufferModelViewInverse[2].xyz;
        vec3 lpvCenter = GetVoxelCenter(cameraPosition, viewDir);
        vec3 blockLocalPos = imgCoord - lpvCenter + 0.5;

        uint blockId = voxelSharedData[getSharedCoord(ivec3(gl_LocalInvocationID) + 1)];

        vec4 directLightValue = vec4(0.0);

        float mixWeight = blockId == BLOCK_EMPTY ? 1.0 : 0.0;
        uint mixMask = 0xFFFF;
        vec3 tint = vec3(1.0);

        if (blockId > 0 && blockId != BLOCK_EMPTY)
            ParseBlockLpvData(StaticBlockMap[blockId].lpv_data, mixMask, mixWeight);

        #ifdef LPV_GLASS_TINT
            if (blockId >= BLOCK_HONEY && blockId <= BLOCK_TINTED_GLASS) {
                tint = GetLightGlassTint(blockId);
                mixWeight = 1.0;
            }
        #endif
        
        if (mixWeight > EPSILON) {
            vec4 lightMixed = mixNeighboursDirect(ivec3(gl_LocalInvocationID), mixMask);
            lightMixed.rgb *= mixWeight * tint;
            directLightValue += lightMixed;
        }

        #if LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
            if (blockId > 0 && blockId != BLOCK_EMPTY) {
                uint lightType = StaticBlockMap[blockId].lightType;

                if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                    StaticLightData lightInfo = StaticLightMap[lightType];
                    vec3 lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                    vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                    float lightRange = lightRangeSize.x * 255.0;

                    lightColor = RGBToLinear(lightColor);

                    vec3 worldPos = cameraPosition + blockLocalPos;
                    ApplyLightAnimation(lightColor, lightRange, lightType, worldPos);

                    #ifdef LIGHTING_FLICKER
                       vec2 lightNoise = GetDynLightNoise(worldPos);
                       ApplyLightFlicker(lightColor, lightType, lightNoise);
                    #endif

                    vec3 hsv = RgbToHsv(lightColor);
                    hsv.z = exp2(lightRange) - 1.0;
                    // hsv.z = lightRange / 15.0;
                    directLightValue.rgb += HsvToRgb(hsv);
                }
            }
        #endif

        vec4 hsv_sky = vec4(RgbToHsv(directLightValue.rgb), directLightValue.a);
        hsv_sky.zw = log2(hsv_sky.zw + 1.0) / LpvBlockSkyRange;
        directLightValue = vec4(HsvToRgb(hsv_sky.xyz), hsv_sky.w);

        directLightValue.rgb = LinearToRGB(directLightValue.rgb);

        if (frameCounter % 2 == 0)
            imageStore(imgSceneLPV_1, imgCoord, directLightValue);
        else
            imageStore(imgSceneLPV_2, imgCoord, directLightValue);
    #endif
}
