#define RENDER_SHADOWCOMP_LPV
#define RENDER_SHADOWCOMP
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


#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #ifdef DYN_LIGHT_FLICKER
        uniform sampler2D noisetex;
    #endif

    #ifdef WORLD_WATER_ENABLED
        uniform vec3 WaterAbsorbColor;
        uniform vec3 WaterScatterColor;
        //uniform float waterDensitySmooth;
    #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform sampler2D shadowtex0;
        uniform sampler2D shadowtex1;

        uniform sampler2D shadowcolor0;

        #ifdef SHADOW_CLOUD_ENABLED
            uniform sampler2D TEX_CLOUDS;
        #endif

        // #ifdef SHADOW_ENABLE_HWCOMP
        //     #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        //         uniform sampler2DShadow shadowtex0HW;
        //         uniform sampler2DShadow shadowtex1HW;
        //     #else
        //         uniform sampler2DShadow shadow;
        //     #endif
        // #endif


        uniform float rainStrength;
        uniform float far;

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            uniform mat4 shadowModelView;
        #endif
    #endif

    uniform float frameTime;
    uniform int frameCounter;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    uniform vec4 lightningBoltPosition = vec4(0.0);

    //#ifdef DYN_LIGHT_FLICKER
        //uniform float frameTimeCounter;

        #ifdef ANIM_WORLD_TIME
            uniform int worldTime;
        #else
            uniform float frameTimeCounter;
        #endif
    //#endif

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"
    #include "/lib/anim.glsl"

    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"

    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        //#include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/block_light_map.glsl"
        #include "/lib/lighting/voxel/lights.glsl"
        #include "/lib/lighting/voxel/lights_render.glsl"
    #endif

    #include "/lib/lighting/voxel/tinting.glsl"

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/buffers/shadow.glsl"

        #include "/lib/sampling/noise.glsl"
        #include "/lib/sampling/ign.glsl"

        #include "/lib/world/sky.glsl"

        #ifdef WORLD_WATER_ENABLED
            #include "/lib/world/water.glsl"
        #endif

        #ifdef SHADOW_CLOUD_ENABLED
            #include "/lib/shadows/render.glsl"
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded/common.glsl"
            //#include "/lib/shadows/cascaded/render.glsl"
        #else
            #include "/lib/shadows/distorted/common.glsl"
            //#include "/lib/shadows/distorted/render.glsl"
        #endif
    #endif
#endif


// ivec3 GetLPVFrameOffset() {
//     vec3 posNow = GetLPVPosition(vec3(0.0));
//     vec3 posLast = GetLPVPosition(previousCameraPosition - cameraPosition);
//     return GetLPVImgCoord(posNow) - GetLPVImgCoord(posLast);
// }

ivec3 GetLPVVoxelOffset() {
    vec3 voxelCameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    ivec3 voxelOrigin = ivec3(voxelCameraOffset + VoxelBlockCenter + 0.5);

    vec3 lpvCameraOffset = fract(cameraPosition);
    ivec3 lpvOrigin = ivec3(lpvCameraOffset + SceneLPVCenter + 0.5);

    return voxelOrigin - lpvOrigin;
}

vec4 GetLpvValue(in ivec3 texCoord) {
    if (clamp(texCoord, ivec3(0), SceneLPVSize - 1) != texCoord) return vec4(0.0);

    return (frameCounter % 2) == 0
        ? imageLoad(imgSceneLPV_2, texCoord)
        : imageLoad(imgSceneLPV_1, texCoord);
}

float GetBlockBounceF(const in uint blockId) {
    //float result = 1.0;

    //if (blockId <= 0) result = 0.0;

    //return result;

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

#if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    vec4 SampleShadow(const in vec3 blockLocalPos) {
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos = (shadowModelView * vec4(blockLocalPos, 1.0)).xyz;
            int cascade = GetShadowCascade(shadowPos, -1.5);

            float shadowBias = (1.0/256.0);//GetShadowOffsetBias(cascade);
            const float shadowDistMax = 3.0 * far;
            float shadowDistScale = 64.0; //3.0 * far;
        #else
            float shadowBias = (1.0/256.0);// * GetShadowOffsetBias();
            const float shadowDistMax = 256.0;
            const float shadowDistScale = 128.0;
        #endif

        float viewDistF = 1.0 - min(length(blockLocalPos) / 20.0, 1.0);
        uint maxSamples = LPV_SUN_SAMPLES;//uint(viewDistF * LPV_SUN_SAMPLES) + 1;
        maxSamples = max(min(maxSamples, LPV_SUN_SAMPLES), 1);

        vec4 shadowF = vec4(0.0);
        //float shadowWeight = 0.0;
        for (uint i = 0; i < maxSamples; i++) {
            vec3 blockLpvPos = blockLocalPos;

            #if LPV_SUN_SAMPLES > 1
                //float ign = InterleavedGradientNoise(imgCoord.xz + 3.0*imgCoord.y);
                vec3 shadowOffset = hash44(vec4(cameraPosition + blockLocalPos + 0.5, i)).xyz;
                blockLpvPos += 0.8*(shadowOffset - 0.5) + 0.4;
                //vec3 blockLpvPos = floor(blockLocalPos - fract(cameraPosition)) + 0.5 + 0.8*(shadowOffset - 0.5);
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowPos = (shadowModelView * vec4(blockLpvPos, 1.0)).xyz;
                //int cascade = GetShadowCascade(shadowPos, 0.0);
                shadowPos = (cascadeProjection[cascade] * vec4(shadowPos, 1.0)).xyz;

                shadowPos = shadowPos * 0.5 + 0.5;
                shadowPos.xy = shadowPos.xy * 0.5 + shadowProjectionPos[cascade];
                //shadowPos.xy = shadowPos.xy * 2.0 - 1.0;
            #else
                vec3 shadowPos = (shadowModelViewProjection * vec4(blockLpvPos, 1.0)).xyz;

                shadowPos = distort(shadowPos);
                shadowPos = shadowPos * 0.5 + 0.5;
            #endif

            vec3 sampleColor = textureLod(shadowcolor0, shadowPos.xy, 0).rgb;
            sampleColor = RGBToLinear(sampleColor);
            //sampleColor = 10.0 * _pow3(sampleColor);

            float texDepth = texture(shadowtex1, shadowPos.xy).r;
            float shadowDist = texDepth - shadowPos.z;
            float sampleF = step(shadowBias, shadowDist);
            sampleF *= max(1.0 - abs(shadowDist) * shadowDistScale, 0.0);

            // TODO: temp fix for preventing underwater LPV-GI
            float texDepthTrans = texture(shadowtex0, shadowPos.xy).r;
            //shadowDist = max(shadowPos.z - texDepth, 0.0);
            //sampleColor *= exp(shadowDist * -WaterAbsorbColorInv);
            //sampleColor *= step(shadowDist, EPSILON);// * max(1.0 - (shadowDist * far / 8.0), 0.0);
            
            //sampleF *= step(shadowPos.z - texDepthTrans, -0.003);

            // TODO: needs an actual water mask in shadow pass
            // bool isWater = shadowPos.z < texDepth + EPSILON
            //     && shadowPos.z > texDepthTrans + shadowBias;

            bool isWater = texDepthTrans < texDepth - EPSILON;

            //if (i == 0) waterDepth = max(shadowPos.z - texDepthTrans, 0.0) * shadowDistMax;

            if (isWater) {
                shadowDist = max(shadowPos.z - texDepthTrans, EPSILON) * shadowDistMax;
                sampleColor *= exp(shadowDist * -WaterAbsorbColorInv);
                sampleF *= 0.0;//DynamicLightAmbientF;// * exp(-shadowDist);
                //sampleF = 0.0;
            }
            // else {
            //     sampleColor *= sampleF;
            // }

            shadowF += vec4(sampleColor * sampleF, sampleF);
        }

        shadowF *= rcp(maxSamples);
        //shadowF = RGBToLinear(shadowF);

        // #ifdef SHADOW_CLOUD_ENABLED
        //     float cloudF = SampleCloudShadow(localSunDirection, cloudShadowPos);

        //     shadowF *= cloudF;
        // #endif

        // WARN: this is just a test! make skylight GI more dark and saturated
        //shadowF.rgb = _pow2(shadowF.rgb);

        return saturate(shadowF);
    }
#endif

shared vec4 lpvSharedData[10*10*10];
//shared uint voxelBlockShared[6*6*6];

int sumOf(ivec3 vec) {
    return vec.x + vec.y + vec.z;
}

int getSharedCoord(ivec3 pos) {
    const ivec3 flatten = ivec3(1, 10, 100);
    return sumOf(pos * flatten);
}

vec4 sampleShared(ivec3 pos) {
    return lpvSharedData[getSharedCoord(pos + 1)];
}

vec4 mixNeighbours(const in ivec3 fragCoord, const in uint mask) {
    vec4 nX1 = sampleShared(fragCoord + ivec3(-1,  0,  0)) * ((mask     ) & 1);
    vec4 nX2 = sampleShared(fragCoord + ivec3( 1,  0,  0)) * ((mask >> 1) & 1);
    vec4 nY1 = sampleShared(fragCoord + ivec3( 0, -1,  0)) * ((mask >> 2) & 1);
    vec4 nY2 = sampleShared(fragCoord + ivec3( 0,  1,  0)) * ((mask >> 3) & 1);
    vec4 nZ1 = sampleShared(fragCoord + ivec3( 0,  0, -1)) * ((mask >> 4) & 1);
    vec4 nZ2 = sampleShared(fragCoord + ivec3( 0,  0,  1)) * ((mask >> 5) & 1);

    vec4 avgColor = nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2;
    return avgColor * (1.0/6.0) * (1.0 - LPV_FALLOFF * frameTime);
}

void main() {
    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uvec3 chunkPos = gl_WorkGroupID * gl_WorkGroupSize;
        if (any(greaterThanEqual(chunkPos, SceneLPVSize))) return;

        int frameIndex = frameCounter % 2;
        ivec3 imgCoordOffset = GetLPVFrameOffset();
        ivec3 voxelOffset = GetLPVVoxelOffset();

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;

        ivec3 kernelPos = ivec3(gl_LocalInvocationID + 1u);
        ivec3 kernelEdgeDir = ivec3(step(ivec3(1), gl_LocalInvocationID)) * 2 - 1;
        
        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE //&& DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.96*rainStrength);
            skyLightColor *= smoothstep(0.0, 0.1, abs(localSunDirection.y));

            float sunUpF = smoothstep(-0.2, 0.2, localSunDirection.y);
            skyLightColor *= LpvBlockLightF * mix(WorldMoonBrightnessF, WorldSunBrightnessF, sunUpF);

            skyLightColor *= mix(1.0, 0.1, rainStrength);
        #endif

        ivec3 imgCoord = ivec3(gl_WorkGroupID * gl_WorkGroupSize + gl_LocalInvocationID);

        //barrier();
        //memoryBarrierShared();

        ivec3 o;
        ivec3 imgCoordPrev = imgCoord + imgCoordOffset;
        int k = getSharedCoord(kernelPos);

        ivec3 voxelPos = voxelOffset + imgCoord;
        ivec3 gridCell = ivec3(floor(voxelPos / LIGHT_BIN_SIZE));
        uint gridIndex = GetVoxelGridCellIndex(gridCell);
        ivec3 blockCell = voxelPos - gridCell * LIGHT_BIN_SIZE;
        uint blockId = BLOCK_EMPTY;

        //if (all(greaterThanEqual(blockCell, ivec3(0))) && all(lessThan(blockCell, VoxelBlockSize)))
        if (clamp(voxelPos, ivec3(0), VoxelBlockSize - 1) == voxelPos)
            blockId = GetVoxelBlockMask(blockCell, gridIndex);

        lpvSharedData[k] = GetLpvValue(imgCoordPrev);
        //voxelBlockShared[k] = blockId;

        if (gl_LocalInvocationID.x == 0u || gl_LocalInvocationID.x == 7u) {
            o = ivec3(kernelEdgeDir.x, 0, 0);
            lpvSharedData[getSharedCoord(kernelPos + o)] = GetLpvValue(imgCoordPrev + o);
        }

        if (gl_LocalInvocationID.y == 0u || gl_LocalInvocationID.y == 7u) {
            o = ivec3(0, kernelEdgeDir.y, 0);
            lpvSharedData[getSharedCoord(kernelPos + o)] = GetLpvValue(imgCoordPrev + o);
        }

        if (gl_LocalInvocationID.z == 0u || gl_LocalInvocationID.z == 7u) {
            o = ivec3(0, 0, kernelEdgeDir.z);
            lpvSharedData[getSharedCoord(kernelPos + o)] = GetLpvValue(imgCoordPrev + o);
        }

        barrier();

        if (any(greaterThanEqual(imgCoord, SceneLPVSize))) return;

        vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell + 0.5 - VoxelBlockCenter - cameraOffset;

        vec4 lightValue = vec4(0.0);

        #if DYN_LIGHT_MODE == DYN_LIGHT_LPV
            uint lightType = GetSceneLightType(int(blockId));
            if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                StaticLightData lightInfo = StaticLightMap[lightType];
                vec3 lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                float lightRange = lightRangeSize.x * 255.0;

                lightColor = RGBToLinear(lightColor);

                vec2 lightNoise = vec2(0.0);
                #ifdef DYN_LIGHT_FLICKER
                    lightNoise = GetDynLightNoise(cameraPosition + blockLocalPos);
                    ApplyLightFlicker(lightColor, lightType, lightNoise);
                #endif

                lightValue.rgb = lightColor * (exp2(lightRange * DynamicLightRangeF * 0.5) - 1.0);// * LpvBlockLightF;
            }
            else {
        #endif
            bool allowLight = false;
            vec3 tint = vec3(1.0);

            #ifdef LPV_GLASS_TINT
                if (blockId >= BLOCK_HONEY && blockId <= BLOCK_TINTED_GLASS) {
                    tint = GetLightGlassTint(blockId);
                    allowLight = true;
                }
                else {
            #endif
                allowLight = IsTraceOpenBlock(blockId);
            #ifdef LPV_GLASS_TINT
                }
            #endif

            float mixWeight = 1.0;
            uint mixMask = 0xFFFF;
            if (blockId == BLOCK_SLAB_TOP || blockId == BLOCK_SLAB_BOTTOM) {
                mixMask = mixMask & ~(1 << 2) & ~(1 << 3);
                mixWeight = 0.5;
                allowLight = true;
            }
            else if (blockId == BLOCK_DOOR_N || blockId == BLOCK_DOOR_S) {
                allowLight = true;
                mixMask = mixMask & ~(1 << 4) & ~(1 << 5);
            }
            else if (blockId == BLOCK_DOOR_W || blockId == BLOCK_DOOR_E) {
                allowLight = true;
                mixMask = mixMask & ~(1 << 0) & ~(1 << 1);
            }
            
            if (allowLight) {
                //ivec3 imgCoordPrev = imgCoord + imgCoordOffset;
                // lightValue = mixNeighbours(ivec3(gl_LocalInvocationID), mixMask);
                // lightValue.rgb *= mixWeight * tint;
                vec4 lightMixed = mixNeighbours(ivec3(gl_LocalInvocationID), mixMask);
                lightMixed.rgb *= mixWeight * tint;
                lightValue += lightMixed;

                #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && LPV_SUN_SAMPLES > 0
                    vec4 shadowColorF = SampleShadow(blockLocalPos);

                    #ifdef LPV_GI
                        if (blockId != BLOCK_WATER) {
                            ivec3 bounceOffset = ivec3(sign(-localSunDirection));

                            // make sure diagonals dont exist
                            int bounceYF = int(step(0.5, abs(localSunDirection.y)) + 0.5);
                            bounceOffset.xz *= 1 - bounceYF;
                            bounceOffset.y *= bounceYF;

                            float sunUpF = smoothstep(-0.1, 0.3, localSunDirection.y);
                            float skyLightBrightF = mix(WorldMoonBrightnessF, WorldSunBrightnessF, sunUpF);
                            skyLightBrightF *= 1.0 - 0.8 * rainStrength;
                            // TODO: make darker at night

                            float skyLightRange = mix(1.0, 8.0, sunUpF);

                            float bounceF = GetLpvBounceF(voxelPos, bounceOffset);

                            #if DYN_LIGHT_MODE == DYN_LIGHT_LPV
                                skyLightBrightF *= DynamicLightAmbientF;
                            #endif

                            lightValue.rgb += (shadowColorF.rgb * skyLightBrightF) * (exp2(skyLightRange * bounceF * DynamicLightRangeF) - 1.0);
                        }
                    #endif

                    // if (blockId == BLOCK_WATER) {
                    //     vec3 waterLight = skyLightColor * shadowColorF.rgb * shadowColorF.a;

                    //     #if DYN_LIGHT_MODE == DYN_LIGHT_LPV
                    //         waterLight *= 0.0;
                    //     #endif

                    //     lightValue.rgb += waterLight;
                    // }

                    lightValue.a = max(lightValue.a, LPV_SKYLIGHT_RANGE * shadowColorF.a);
                #endif

                if (lightningBoltPosition.w > 0.5) {
                    vec3 offset = lightningBoltPosition.xyz;
                    offset.y = clamp(blockLocalPos.y, offset.y, WORLD_CLOUD_HEIGHT - cameraPosition.y);

                    offset -= blockLocalPos;
                    //offset.y = 0.0;

                    float dist = length(offset);
                    if (dist < 3.0) lightValue.rgb = vec3(8.0) * lightningBoltPosition.w;
                }
            }
        #if DYN_LIGHT_MODE == DYN_LIGHT_LPV
            }
        #endif

        if (frameIndex == 0)
            imageStore(imgSceneLPV_1, imgCoord, lightValue);
        else
            imageStore(imgSceneLPV_2, imgCoord, lightValue);

        //}
    #endif
}
