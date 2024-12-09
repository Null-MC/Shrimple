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
const float LpvIndirectFalloff = 0.98;


#ifdef IS_LPV_ENABLED
    #ifdef LIGHTING_FLICKER
        uniform sampler2D noisetex;
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        uniform sampler2D shadowtex0;
        uniform sampler2D shadowtex1;

        uniform sampler2D shadowcolor0;

        #ifdef SHADOW_CLOUD_ENABLED
            // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            //     uniform sampler3D TEX_CLOUDS;
            #ifdef SKY_CLOUD_ENABLED
                uniform sampler2D TEX_CLOUDS_VANILLA;
            #endif
        #endif
    #endif

    uniform float frameTime;
    uniform int frameCounter;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;

    #ifdef WORLD_SKY_ENABLED
        uniform float rainStrength;
        uniform float weatherStrength;

        #ifdef RENDER_SHADOWS_ENABLED
            uniform mat4 shadowProjection;
            uniform float far;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                uniform mat4 shadowModelView;
            #endif
        #endif

        uniform vec3 eyePosition;
        uniform float cloudHeight;
        uniform float cloudTime;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif

    #ifdef WORLD_WATER_ENABLED
        uniform vec3 WaterAbsorbColor;
        uniform vec3 WaterScatterColor;
        uniform float waterDensitySmooth;
    #endif

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

    #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
        #include "/lib/buffers/lpv_indirect.glsl"
    #endif

    #include "/lib/utility/hsv.glsl"

    #ifdef LPV_BLEND_ALT
        #include "/lib/utility/jzazbz.glsl"
    #endif

    #include "/lib/voxel/voxel_common.glsl"

    #include "/lib/voxel/lpv/lpv.glsl"
    #include "/lib/voxel/lights/mask.glsl"
    // #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"

    #include "/lib/sampling/noise.glsl"

    #ifdef LIGHTING_FLICKER
        #include "/lib/utility/anim.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    #include "/lib/lighting/voxel/lights_render.glsl"

    #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED
        #include "/lib/buffers/shadow.glsl"

        #include "/lib/sampling/ign.glsl"

        #include "/lib/world/sky.glsl"
        #include "/lib/clouds/cloud_common.glsl"

        #ifdef WORLD_WATER_ENABLED
            #include "/lib/world/water.glsl"
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded/common.glsl"
        #else
            #include "/lib/shadows/distorted/common.glsl"
        #endif

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            //     #include "/lib/clouds/cloud_custom.glsl"
            //     #include "/lib/clouds/cloud_custom_shadow.glsl"
            #ifdef SKY_CLOUD_ENABLED
                #include "/lib/clouds/cloud_vanilla.glsl"
                #include "/lib/clouds/cloud_vanilla_shadow.glsl"
            #endif
        #endif
    #endif
#endif


// const vec2 LpvBlockSkyRange = vec2(LPV_BLOCKLIGHT_SCALE, LPV_SKYLIGHT_RANGE);

// ivec3 GetLpvVoxelOffset() {
//     vec3 voxelCameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
//     ivec3 voxelOrigin = ivec3(voxelCameraOffset + VoxelLightBlockCenter + 0.5);

//     vec3 viewDir = gbufferModelViewInverse[2].xyz;
//     ivec3 lpvOrigin = ivec3(GetVoxelCenter(cameraPosition, viewDir) + 0.5);

//     return voxelOrigin - lpvOrigin;
// }

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

#if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
    vec3 GetLpvIndirectValue(in ivec3 texCoord) {
        if (!IsInVoxelBounds(texCoord)) return vec3(0.0);

        vec3 lpvSample = (frameCounter % 2) == 0
            ? imageLoad(imgIndirectLpv_2, texCoord).rgb
            : imageLoad(imgIndirectLpv_1, texCoord).rgb;

        // lpvSample = RGBToLinear(lpvSample);

        vec3 hsv = RgbToHsv(lpvSample);
        hsv.z = exp2(hsv.z * LPV_GI_RANGE) - 1.0;
        lpvSample = HsvToRgb(hsv);

        return lpvSample;
    }
#endif

// float GetBlockBounceF(const in uint blockId) {
//     // TODO: make this better
//     return step(blockId + 1, BLOCK_WATER);
// }

// float GetLpvBounceF(const in ivec3 gridBlockCell, const in ivec3 blockOffset) {
//     ivec3 gridCell = ivec3(floor((gridBlockCell + blockOffset) / LIGHT_BIN_SIZE));
//     uint gridIndex = GetVoxelGridCellIndex(gridCell);
//     ivec3 blockCell = gridBlockCell + blockOffset - gridCell * LIGHT_BIN_SIZE;

//     uint blockId = GetVoxelBlockMask(blockCell, gridIndex);
//     //float bounceF = max(dot(-normalize(blockOffset), localSkyLightDirection), 0.0);
//     return GetBlockBounceF(blockId);// * bounceF * 0.98 + 0.02;
// }

#if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED
    vec4 SampleShadow(const in vec3 blockLocalPos, out float shadowDist) {
        const float giScale = rcp(2.0);

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos = mul3(shadowModelView, blockLocalPos);
            int cascade = GetShadowCascade(shadowPos, -1.5);

            float shadowDistMax = GetShadowRange(cascade);
            // float shadowBias = 1.5 * rcp(shadowDistMax);//GetShadowOffsetBias(cascade);
        #else
            float shadowDistMax = GetShadowRange();
            // float shadowBias = 1.5 * rcp(shadowDistMax);// * GetShadowOffsetBias();
        #endif

        float viewDist = length(blockLocalPos);
        //float viewDistF = 1.0 - min(viewDist / 20.0, 1.0);
        uint maxSamples = uint((1.0 - smoothstep(0.0, 40.0, viewDist)) * LPV_SHADOW_SAMPLES) + 1;
        maxSamples = clamp(maxSamples, 1u, uint(LPV_SHADOW_SAMPLES));

        vec4 shadowF = vec4(0.0);
        shadowDist = 0.0;
        //float shadowWeight = 0.0;
        for (uint i = 0; i < LPV_SHADOW_SAMPLES; i++) {
            if (i >= maxSamples) break;

            vec3 blockLpvPos = blockLocalPos;

            #if LPV_SHADOW_SAMPLES > 1
                //float ign = InterleavedGradientNoise(imgCoord.xz + 3.0*imgCoord.y);
                vec3 shadowOffset = hash44(vec4(cameraPosition + blockLocalPos + 0.5, i)).xyz;
                blockLpvPos += 0.8*(shadowOffset - 0.5) + 0.4;
                //vec3 blockLpvPos = floor(blockLocalPos - fract(cameraPosition)) + 0.5 + 0.8*(shadowOffset - 0.5);
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowPos = mul3(shadowModelViewEx, blockLpvPos);
                shadowPos = mul3(cascadeProjection[cascade], shadowPos);

                shadowPos = shadowPos * 0.5 + 0.5;
                shadowPos.xy = shadowPos.xy * 0.5 + shadowProjectionPos[cascade];
            #else
                vec3 shadowPos = mul3(shadowModelViewProjection, blockLpvPos);

                shadowPos = distort(shadowPos);
                shadowPos = shadowPos * 0.5 + 0.5;
            #endif

            float texDepth = texture(shadowtex1, shadowPos.xy).r;
            float sampleDist = texDepth - shadowPos.z;
            float sampleF = step(0.0, sampleDist);
            //sampleF *= max(1.0 - abs(shadowDist * shadowDistMax) * giScale, 0.0);

            shadowDist += max(sampleDist, 0.0);

            // TODO: temp fix for preventing underwater LPV-GI
            float texDepthTrans = texture(shadowtex0, shadowPos.xy).r;
            //shadowDist = max(shadowPos.z - texDepth, 0.0);
            //sampleColor *= exp(shadowDist * -WaterAbsorbF);
            //sampleColor *= step(shadowDist, EPSILON);// * max(1.0 - (shadowDist * far / 8.0), 0.0);

            vec3 sampleColor = vec3(0.0);
            #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
                sampleColor = textureLod(shadowcolor0, shadowPos.xy, 0).rgb;
                sampleColor = RGBToLinear(sampleColor);
                //sampleColor = 10.0 * _pow3(sampleColor);

                // TODO: fade out color
                float colorF = min(abs(sampleDist * shadowDistMax) * giScale, 1.0);
                // sampleColor = mix(sampleColor, vec3(1.0), colorF);
                sampleColor *= 1.0 - colorF;
                sampleF *= 1.0 - colorF;
            #endif
            
            //sampleF *= step(shadowPos.z - texDepthTrans, -0.003);

            // TODO: needs an actual water mask in shadow pass
            // bool isWater = shadowPos.z < texDepth + EPSILON
            //     && shadowPos.z > texDepthTrans + shadowBias;

            bool isWater = false;//texDepthTrans < texDepth - EPSILON;

            //if (i == 0) waterDepth = max(shadowPos.z - texDepthTrans, 0.0) * shadowDistMax;

            if (isWater) {
                // shadowDist = max(shadowPos.z - texDepthTrans, EPSILON) * shadowDistMax;
                // sampleColor *= exp(shadowDist * -WaterAbsorbF);
                sampleF *= 0.0;//Lighting_AmbientF;// * exp(-shadowDist);
            }
            // else {
            //     sampleColor *= sampleF;
            // }

            shadowF += vec4(sampleColor * sampleF, sampleF);
        }

        shadowF /= maxSamples;
        shadowDist = (shadowDist / maxSamples) * shadowDistMax;
        //shadowF = RGBToLinear(shadowF);

        // #ifdef SHADOW_CLOUD_ENABLED
        //     float cloudF = SampleCloudShadow(localSunDirection, cloudShadowPos);

        //     shadowF *= cloudF;
        // #endif

        return saturate(shadowF);
    }
#endif

const ivec3 lpvFlatten = ivec3(1, 10, 100);

shared uint voxelSharedData[10*10*10];
shared vec4 lpvDirectBuffer[10*10*10];

#if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
    shared vec3 lpvIndirectBuffer[10*10*10];
#endif

int getSharedCoord(ivec3 pos) {
    return sumOf(pos * lpvFlatten);
}

// vec4 sampleShared(ivec3 pos) {
//     return lpvDirectBuffer[getSharedCoord(pos + 1)];
// }

vec4 sampleDirectShared(ivec3 pos, int mask_index, out float weight) {
    int shared_index = getSharedCoord(pos + 1);

    //float mixWeight = 1.0;
    uint mixMask = 0xFFFF;
    uint blockId = voxelSharedData[shared_index];
    weight = blockId == BLOCK_EMPTY ? 1.0 : 0.0;
    
    if (blockId > 0 && blockId != BLOCK_EMPTY)
        ParseBlockLpvData(StaticBlockMap[blockId].lpv_data, mixMask, weight);

    float wMask = (mixMask >> mask_index) & 1u;
    return lpvDirectBuffer[shared_index] * wMask;// * mixWeight;
}

#if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
    vec3 sampleIndirectShared(ivec3 pos, int mask_index, out float weight) {
        int shared_index = getSharedCoord(pos + 1);

        //float mixWeight = 1.0;
        uint mixMask = 0xFFFF;
        uint blockId = voxelSharedData[shared_index];
        weight = blockId == BLOCK_EMPTY ? 1.0 : 0.0;
        
        if (blockId > 0 && blockId != BLOCK_EMPTY)
            ParseBlockLpvData(StaticBlockMap[blockId].lpv_data, mixMask, weight);

        float wMask = (mixMask >> mask_index) & 1u;
        return lpvIndirectBuffer[shared_index] * wMask;// * mixWeight;
    }
#endif

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

    float wMax = 6.0;//max(sumOf(w1 + w2), 1.0);
    float avgFalloff = rcp(wMax) * LpvFalloff;
    return (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * avgFalloff;
}

#if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
    vec3 mixNeighboursIndirect(const in ivec3 fragCoord, const in uint mask) {
        uvec3 m1 = (uvec3(mask) >> uvec3(0, 2, 4)) & uvec3(1u);
        uvec3 m2 = (uvec3(mask) >> uvec3(1, 3, 5)) & uvec3(1u);

        vec3 w1, w2;
        vec3 nX1 = sampleIndirectShared(fragCoord + ivec3(-1,  0,  0), 1, w1.x) * m1.x;
        vec3 nX2 = sampleIndirectShared(fragCoord + ivec3( 1,  0,  0), 0, w2.x) * m2.x;
        vec3 nY1 = sampleIndirectShared(fragCoord + ivec3( 0, -1,  0), 3, w1.y) * m1.y;
        vec3 nY2 = sampleIndirectShared(fragCoord + ivec3( 0,  1,  0), 2, w2.y) * m2.y;
        vec3 nZ1 = sampleIndirectShared(fragCoord + ivec3( 0,  0, -1), 5, w1.z) * m1.z;
        vec3 nZ2 = sampleIndirectShared(fragCoord + ivec3( 0,  0,  1), 4, w2.z) * m2.z;

        float wMax = 6.0;//max(sumOf(w1 + w2), 1.0);
        // float avgFalloff = (1.0/6.0) * (1.0 - LpvIndirectFalloff);
        float avgFalloff = rcp(wMax) * LpvIndirectFalloff;
        return (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * avgFalloff;
    }
#endif

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

    #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
        lpvIndirectBuffer[i1] = GetLpvIndirectValue(lpvPos1);
        lpvIndirectBuffer[i2] = GetLpvIndirectValue(lpvPos2);
    #endif


    uint blockId1 = BLOCK_EMPTY;
    uint blockId2 = BLOCK_EMPTY;

    // ivec3 voxelPos1 = voxelOffset + pos1;
    // ivec3 voxelPos2 = voxelOffset + pos2;

    if (IsInVoxelBounds(pos1)) {
        // ivec3 gridCell = ivec3(floor(voxelPos1 / LIGHT_BIN_SIZE));
        // uint gridIndex = GetVoxelGridCellIndex(gridCell);
        // ivec3 blockCell = voxelPos1 - gridCell * LIGHT_BIN_SIZE;

        // blockId1 = GetVoxelBlockMask(blockCell, gridIndex);
        blockId1 = imageLoad(imgVoxels, pos1).r;
    }

    if (IsInVoxelBounds(pos2)) {
        // ivec3 gridCell = ivec3(floor(voxelPos2 / LIGHT_BIN_SIZE));
        // uint gridIndex = GetVoxelGridCellIndex(gridCell);
        // ivec3 blockCell = voxelPos2 - gridCell * LIGHT_BIN_SIZE;

        // blockId2 = GetVoxelBlockMask(blockCell, gridIndex);
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
        #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
            vec3 indirectLightValue = vec3(0.0);
        #endif

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

            #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED && defined IS_LPV_SKYLIGHT_ENABLED
                #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
                    lightMixed.rgb = mixNeighboursIndirect(ivec3(gl_LocalInvocationID), mixMask);
                    lightMixed.rgb *= mixWeight * tint;
                    indirectLightValue += lightMixed.rgb;
                #endif

                float shadowDist;
                vec4 shadowColorF = SampleShadow(blockLocalPos, shadowDist);

                // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
                //     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                //         vec3 worldPos = cameraPosition + blockLocalPos;
                //         float cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                //     #else
                //         vec2 cloudOffset = GetCloudOffset();
                //         vec3 camOffset = GetCloudCameraOffset();
                //         float cloudShadow = SampleCloudShadow(blockLocalPos, localSkyLightDirection, cloudOffset, camOffset, 0.5);
                //     #endif

                //     shadowColorF.a *= cloudShadow;
                // #endif

                float sunUpF = smoothstep(-0.2, 0.1, localSunDirection.y);

                #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
                    if (blockId != BLOCK_WATER) {
                        // ivec3 bounceOffset = ivec3(sign(-localSunDirection));

                        // // make sure diagonals dont exist
                        // int bounceYF = int(step(0.5, abs(localSunDirection.y)) + 0.5);
                        // bounceOffset.xz *= 1 - bounceYF;
                        // bounceOffset.y *= bounceYF;

                        // float sunUpF = smoothstep(-0.1, 0.3, localSunDirection.y);
                        //float skyLightBrightF = mix(Sky_MoonBrightnessF, Sky_SunBrightnessF, sunUpF);
                        //skyLightBrightF *= 1.0 - 0.8 * weatherStrength;
                        // TODO: make darker at night

                        // #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                        //     float skyLightRange = 6.0 * sunUpF * Lighting_AmbientF;
                        // #else
                        //     float skyLightRange = 10.0 * sunUpF;
                        // #endif

                        // skyLightRange *= 1.0 - 0.8 * weatherStrength;

                        vec3 skyLight = shadowColorF.rgb;// * WorldSkyLightColor;

                        vec3 hsv = RgbToHsv(skyLight);
                        // hsv.y *= 0.65;
                        hsv.z = exp2(LPV_GI_RANGE * shadowColorF.a) - 1.0;
                        skyLight = HsvToRgb(hsv);

                        indirectLightValue += skyLight;// / max(shadowDist, 1.0);
                    }
                #endif

                float skyLightDistF = 1.0;//sunUpF * 0.8 + 0.2;
                float skyLightFinal = exp2(LpvBlockSkyRange.y * skyLightDistF * shadowColorF.a) - 1.0;
                directLightValue.a = max(directLightValue.a, skyLightFinal);
            #endif
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

        #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
            // indirectLightValue = vec3(0.0, 100.0, 0.0);

            vec3 hsv = RgbToHsv(indirectLightValue);
            hsv.z = log2(hsv.z + 1.0) / LPV_GI_RANGE;
            indirectLightValue = HsvToRgb(hsv);

            // indirectLightValue = LinearToRGB(indirectLightValue);
        #endif

        // if (worldTimeCurrent - worldTimePrevious > 1000 || (worldTimeCurrent + 12000 < worldTimePrevious && worldTimeCurrent + 24000 - worldTimePrevious > 1000)) {
        //     directLightValue = vec4(0.0);
        //     indirectLightValue = vec3(0.0);
        // }

        if (frameCounter % 2 == 0)
            imageStore(imgSceneLPV_1, imgCoord, directLightValue);
        else
            imageStore(imgSceneLPV_2, imgCoord, directLightValue);

        #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
            if (frameCounter % 2 == 0)
                imageStore(imgIndirectLpv_1, imgCoord, vec4(indirectLightValue, 1.0));
            else
                imageStore(imgIndirectLpv_2, imgCoord, vec4(indirectLightValue, 1.0));
        #endif
    #endif
}
