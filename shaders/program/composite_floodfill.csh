#define RENDER_COMPOSITE_LPV
#define RENDER_COMPOSITE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

#if LPV_SIZE == 3
    const ivec3 workGroups = ivec3(32, 32, 32);
#elif LPV_SIZE == 2
    const ivec3 workGroups = ivec3(16, 16, 16);
#else
    const ivec3 workGroups = ivec3(8, 8, 8);
#endif

const vec2 LpvBlockSkyFalloff = vec2(0.04, 0.04);


#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0
    #ifdef LIGHTING_FLICKER
        uniform sampler2D noisetex;
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        uniform sampler2D shadowtex0;
        uniform sampler2D shadowtex1;

        uniform sampler2D shadowcolor0;

        #ifdef SHADOW_CLOUD_ENABLED
            #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                uniform sampler3D TEX_CLOUDS;
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
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
        uniform float skyRainStrength;

        #ifdef RENDER_SHADOWS_ENABLED
            uniform mat4 shadowProjection;
            uniform float far;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                uniform mat4 shadowModelView;
            #endif
        #endif

        #ifdef SHADOW_CLOUD_ENABLED
            uniform vec3 eyePosition;
            uniform float cloudHeight;
            uniform float cloudTime;
        #endif
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

    #include "/lib/utility/hsv.glsl"

    #ifdef LPV_BLEND_ALT
        #include "/lib/utility/jzazbz.glsl"
    #endif

    #include "/lib/lpv/lpv.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"

    #ifdef LIGHTING_FLICKER
        #include "/lib/utility/anim.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
        #include "/lib/lighting/voxel/lights_render.glsl"

    #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED
        #include "/lib/buffers/shadow.glsl"

        #include "/lib/sampling/noise.glsl"
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
            #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                #include "/lib/clouds/cloud_custom.glsl"
                #include "/lib/clouds/cloud_custom_shadow.glsl"
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                #include "/lib/clouds/cloud_vanilla.glsl"
                #include "/lib/clouds/cloud_vanilla_shadow.glsl"
            #endif
        #endif
    #endif
#endif


const vec2 LpvBlockSkyRange = vec2(LPV_BLOCKLIGHT_SCALE, LPV_SKYLIGHT_RANGE);

ivec3 GetLPVVoxelOffset() {
    vec3 voxelCameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    ivec3 voxelOrigin = ivec3(voxelCameraOffset + VoxelBlockCenter + 0.5);

    vec3 viewDir = gbufferModelViewInverse[2].xyz;
    ivec3 lpvOrigin = ivec3(GetLpvCenter(cameraPosition, viewDir) + 0.5);

    return voxelOrigin - lpvOrigin;
}

vec4 GetLpvValue(in ivec3 texCoord) {
    if (clamp(texCoord, ivec3(0), SceneLPVSize - 1) != texCoord) return vec4(0.0);

    vec4 lpvSample = (frameCounter % 2) == 0
        ? imageLoad(imgSceneLPV_2, texCoord)
        : imageLoad(imgSceneLPV_1, texCoord);

    lpvSample.ba = exp2(lpvSample.ba * LpvBlockSkyRange) - 1.0;
    lpvSample.rgb = HsvToRgb(lpvSample.rgb);

    #ifdef LPV_BLEND_ALT
        lpvSample.rgb = RgbToJab(lpvSample.rgb);
    #endif

    return lpvSample;
}

float GetBlockBounceF(const in uint blockId) {
    // TODO: make this better
    return step(blockId + 1, BLOCK_WATER);
}

float GetLpvBounceF(const in ivec3 gridBlockCell, const in ivec3 blockOffset) {
    ivec3 gridCell = ivec3(floor((gridBlockCell + blockOffset) / LIGHT_BIN_SIZE));
    uint gridIndex = GetVoxelGridCellIndex(gridCell);
    ivec3 blockCell = gridBlockCell + blockOffset - gridCell * LIGHT_BIN_SIZE;

    uint blockId = GetVoxelBlockMask(blockCell, gridIndex);
    //float bounceF = max(dot(-normalize(blockOffset), localSkyLightDirection), 0.0);
    return GetBlockBounceF(blockId);// * bounceF * 0.98 + 0.02;
}

#if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED
    vec4 SampleShadow(const in vec3 blockLocalPos, out float shadowDist) {
        const float giScale = 0.24;

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos = mul3(shadowModelView, blockLocalPos);
            int cascade = GetShadowCascade(shadowPos, -1.5);

            float shadowDistMax = GetShadowRange(cascade);
            float shadowBias = 1.5 * rcp(shadowDistMax);//GetShadowOffsetBias(cascade);
        #else
            float shadowDistMax = GetShadowRange();
            float shadowBias = 1.5 * rcp(shadowDistMax);// * GetShadowOffsetBias();
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
            float sampleF = step(shadowBias, sampleDist);
            //sampleF *= max(1.0 - abs(shadowDist * shadowDistMax) * giScale, 0.0);

            shadowDist += max(sampleDist, 0);

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
                sampleF *= 0.0;//DynamicLightAmbientF;// * exp(-shadowDist);
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

shared vec4 lpvSharedData[10*10*10];
shared uint voxelSharedData[10*10*10];

int getSharedCoord(ivec3 pos) {
    return sumOf(pos * lpvFlatten);
}

vec4 sampleShared(ivec3 pos) {
    return lpvSharedData[getSharedCoord(pos + 1)];
}

vec4 sampleShared(ivec3 pos, int mask_index) {
    int shared_index = getSharedCoord(pos + 1);

    float mixWeight = 1.0;
    uint mixMask = 0xFFFF;
    uint blockId = voxelSharedData[shared_index];
    
    if (blockId > 0 && blockId != BLOCK_EMPTY)
        ParseBlockLpvData(StaticBlockMap[blockId].lpv_data, mixMask, mixWeight);

    return lpvSharedData[shared_index] * ((mixMask >> mask_index) & 1u);// * mixWeight;
}

vec4 mixNeighbours(const in ivec3 fragCoord, const in uint mask) {
    uvec3 m1 = (uvec3(mask) >> uvec3(0, 2, 4)) & uvec3(1u);
    uvec3 m2 = (uvec3(mask) >> uvec3(1, 3, 5)) & uvec3(1u);

    vec4 nX1 = sampleShared(fragCoord + ivec3(-1,  0,  0), 1) * m1.x;
    vec4 nX2 = sampleShared(fragCoord + ivec3( 1,  0,  0), 0) * m2.x;
    vec4 nY1 = sampleShared(fragCoord + ivec3( 0, -1,  0), 3) * m1.y;
    vec4 nY2 = sampleShared(fragCoord + ivec3( 0,  1,  0), 2) * m2.y;
    vec4 nZ1 = sampleShared(fragCoord + ivec3( 0,  0, -1), 5) * m1.z;
    vec4 nZ2 = sampleShared(fragCoord + ivec3( 0,  0,  1), 4) * m2.z;

    const vec4 avgFalloff = (1.0/6.0) * (1.0 - LpvBlockSkyFalloff.xxxy);
    return (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * avgFalloff;
}

void PopulateShared() {
    uint i1 = uint(gl_LocalInvocationIndex) * 2u;
    if (i1 >= 1000u) return;

    uint i2 = i1 + 1u;
    ivec3 voxelOffset = GetLPVVoxelOffset();
    ivec3 imgCoordOffset = GetLPVFrameOffset();
    ivec3 workGroupOffset = ivec3(gl_WorkGroupID * gl_WorkGroupSize) - 1;

    ivec3 pos1 = workGroupOffset + ivec3(i1 / lpvFlatten) % 10;
    ivec3 pos2 = workGroupOffset + ivec3(i2 / lpvFlatten) % 10;

    ivec3 lpvPos1 = imgCoordOffset + pos1;
    ivec3 lpvPos2 = imgCoordOffset + pos2;

    lpvSharedData[i1] = GetLpvValue(lpvPos1);
    lpvSharedData[i2] = GetLpvValue(lpvPos2);


    uint blockId1 = BLOCK_EMPTY;
    uint blockId2 = BLOCK_EMPTY;

    ivec3 voxelPos1 = voxelOffset + pos1;
    ivec3 voxelPos2 = voxelOffset + pos2;

    if (clamp(voxelPos1, ivec3(0), VoxelBlockSize - 1) == voxelPos1) {
        ivec3 gridCell = ivec3(floor(voxelPos1 / LIGHT_BIN_SIZE));
        uint gridIndex = GetVoxelGridCellIndex(gridCell);
        ivec3 blockCell = voxelPos1 - gridCell * LIGHT_BIN_SIZE;

        blockId1 = GetVoxelBlockMask(blockCell, gridIndex);
    }

    if (clamp(voxelPos2, ivec3(0), VoxelBlockSize - 1) == voxelPos2) {
        ivec3 gridCell = ivec3(floor(voxelPos2 / LIGHT_BIN_SIZE));
        uint gridIndex = GetVoxelGridCellIndex(gridCell);
        ivec3 blockCell = voxelPos2 - gridCell * LIGHT_BIN_SIZE;

        blockId2 = GetVoxelBlockMask(blockCell, gridIndex);
    }

    voxelSharedData[i1] = blockId1;
    voxelSharedData[i2] = blockId2;
}

void main() {
    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
        uvec3 chunkPos = gl_WorkGroupID * gl_WorkGroupSize;
        if (any(greaterThanEqual(chunkPos, SceneLPVSize))) return;

        PopulateShared();

        barrier();

        ivec3 imgCoord = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(imgCoord, SceneLPVSize))) return;

        // vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell - VoxelBlockCenter + cameraOffset + 0.5;

        vec3 viewDir = gbufferModelViewInverse[2].xyz;
        vec3 lpvCenter = GetLpvCenter(cameraPosition, viewDir);
        vec3 blockLocalPos = imgCoord - lpvCenter + 0.5;

        uint blockId = voxelSharedData[getSharedCoord(ivec3(gl_LocalInvocationID) + 1)];

        vec4 lightValue = vec4(0.0);
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
            vec4 lightMixed = mixNeighbours(ivec3(gl_LocalInvocationID), mixMask);
            lightMixed.rgb *= mixWeight * tint;
            lightValue += lightMixed;

            #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED && defined IS_LPV_SKYLIGHT_ENABLED
                float shadowDist;
                vec4 shadowColorF = SampleShadow(blockLocalPos, shadowDist);

                #ifdef RENDER_CLOUD_SHADOWS_ENABLED
                    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                        vec3 worldPos = cameraPosition + blockLocalPos;
                        float cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                    #else
                        vec2 cloudOffset = GetCloudOffset();
                        vec3 camOffset = GetCloudCameraOffset();
                        float cloudShadow = SampleCloudShadow(blockLocalPos, localSkyLightDirection, cloudOffset, camOffset, 0.5);
                    #endif
                    shadowColorF.a *= cloudShadow;
                #endif

                float sunUpF = smoothstep(-0.1, 0.3, localSunDirection.y);

                #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
                    if (blockId != BLOCK_WATER) {
                        // ivec3 bounceOffset = ivec3(sign(-localSunDirection));

                        // // make sure diagonals dont exist
                        // int bounceYF = int(step(0.5, abs(localSunDirection.y)) + 0.5);
                        // bounceOffset.xz *= 1 - bounceYF;
                        // bounceOffset.y *= bounceYF;

                        // float sunUpF = smoothstep(-0.1, 0.3, localSunDirection.y);
                        //float skyLightBrightF = mix(WorldMoonBrightnessF, WorldSunBrightnessF, sunUpF);
                        //skyLightBrightF *= 1.0 - 0.8 * skyRainStrength;
                        // TODO: make darker at night

                        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                            float skyLightRange = 6.0 * sunUpF * DynamicLightAmbientF;
                        //     // float skyLightRange = mix(1.0, 6.0, sunUpF);
                        //     float skyLightRange = mix(2.0, 4.0, sunUpF);
                        #else
                            float skyLightRange = 8.0 * sunUpF;
                        //    // float skyLightRange = mix(1.0, 16.0, sunUpF);
                        //     float skyLightRange = mix(1.0, 6.0, sunUpF);
                        #endif

                        skyLightRange *= 1.0 - 0.8 * skyRainStrength;

                        //float bounceF = GetLpvBounceF(voxelPos, bounceOffset);

                        //#if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                        //    skyLightBrightF *= DynamicLightAmbientF;
                        //#endif



                        vec3 skyLight = RgbToHsv(shadowColorF.rgb * WorldSkyLightColor);
                        skyLight.b = exp2(skyLightRange * shadowColorF.a) - 1.0;
                        skyLight = HsvToRgb(skyLight);



                        // lightValue.rgb += 3.0 * (shadowColorF.rgb * skyLightBrightF) * (exp2(skyLightRange * bounceF * DynamicLightRangeF) - 1.0);
                        lightValue.rgb += skyLight / max(shadowDist, 1.0);
                    }
                #endif

                float skyLightDistF = sunUpF * 0.8 + 0.2;
                float skyLightFinal = exp2(LPV_SKYLIGHT_RANGE * skyLightDistF * shadowColorF.a) - 1.0;
                lightValue.a = max(lightValue.a, skyLightFinal);
            #endif
        }

        #ifdef LPV_BLEND_ALT
            lightValue.rgb = JabToRgb(lightValue.rgb);
        #endif

        lightValue.rgb = RgbToHsv(lightValue.rgb);
        lightValue.ba = log2(lightValue.ba + 1.0) / LpvBlockSkyRange;

        #if LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
            if (blockId > 0 && blockId != BLOCK_EMPTY) {
                uint lightType = StaticBlockMap[blockId].lightType;

                if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                    StaticLightData lightInfo = StaticLightMap[lightType];
                    vec3 lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                    vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                    float lightRange = lightRangeSize.x * 255.0;

                    lightColor = RGBToLinear(lightColor);

                    #ifdef LIGHTING_FLICKER
                       vec2 lightNoise = GetDynLightNoise(cameraPosition + blockLocalPos);
                       ApplyLightFlicker(lightColor, lightType, lightNoise);
                    #endif

                    lightValue.rgb = Lpv_RgbToHsv(lightColor, lightRange);
                }
            }
        #endif

        if (worldTimeCurrent - worldTimePrevious > 1000 || (worldTimeCurrent + 12000 < worldTimePrevious && worldTimeCurrent + 24000 - worldTimePrevious > 1000))
            lightValue = vec4(0.0);

        if (frameCounter % 2 == 0)
            imageStore(imgSceneLPV_1, imgCoord, lightValue);
        else
            imageStore(imgSceneLPV_2, imgCoord, lightValue);
    #endif
}
