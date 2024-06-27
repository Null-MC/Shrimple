#if LIGHTING_TRACE_SAMPLE_MAX > 0 && LIGHTING_MODE == LIGHTING_MODE_TRACED && !(defined RENDER_TRANSLUCENT || defined RENDER_VERTEX)
    #define DYN_LIGHT_INTERLEAVE_ENABLED
#endif

float GetBias_RT(const in float viewDist) {
    return clamp(0.004 * viewDist, 0.002, 0.2);
}

void SampleDynamicLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {//, const in vec3 blockLightDefault) {
    uint gridIndex;
    float viewDist = length(localPos);
    vec3 localViewDir = -normalize(localPos);
    //float distBiasScale = 0.02 + min(0.01*viewDist, 0.2);

    // vec3 lightFragPos = localPos;
    // lightFragPos += distBiasScale*localNormal;
    //lightFragPos += distBiasScale*localViewDir;

    vec3 surfacePos = localPos;
    #ifndef RENDER_BILLBOARD
        surfacePos += localNormal * 0.02;
    #endif

    vec3 surfacePosF = fract(surfacePos + cameraPosition);

    uint lightCount = GetVoxelLights(surfacePos, gridIndex);

    bool hasGeoNormal = !all(lessThan(abs(localNormal), EPSILON3));
    bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

    #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
        vec3 f0 = GetMaterialF0(albedo, metal_f0);
    #endif

    float lightNoVm = 1.0;
    if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), EPSILON);

    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);

    // vec3 traceEnd = GetVoxelBlockPosition(surfacePos);
    vec3 cameraOffset = fract(cameraPosition);

    uint iOffset = 0u;
    uint iStep = 1u;
    #ifdef DYN_LIGHT_INTERLEAVE_ENABLED
        uint interleaveCount = uint(ceil(lightCount / float(LIGHTING_TRACE_SAMPLE_MAX)));

        if (interleaveCount > 1u) {
            iStep = interleaveCount;

            float n = InterleavedGradientNoise();
            iOffset = uint(n * interleaveCount + frameCounter % interleaveCount);
            //iOffset = uint(n * interleaveCount + frameCounter % interleaveCount);
        }
    #endif

    #if LIGHTING_TRACE_SAMPLE_MAX > 0
        const int MaxSampleCount = min(LIGHTING_TRACE_SAMPLE_MAX, LIGHT_BIN_MAX_COUNT);
    #else
        const int MaxSampleCount = LIGHT_BIN_MAX_COUNT;
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED && LIGHTING_TRACE_PENUMBRA > 0 && !(defined RENDER_TRANSLUCENT || defined RENDER_COMPUTE)
        vec3 offset = GetLightPenumbraOffset() * Lighting_PenumbraF;

        #define LIGHTING_RAYCOUNT 2u
    #else
        #define LIGHTING_RAYCOUNT 1u
    #endif

    for (uint rayIndex = 0u; rayIndex < LIGHTING_RAYCOUNT; rayIndex++) {
        #if LIGHTING_MODE == LIGHTING_MODE_TRACED && LIGHTING_TRACE_PENUMBRA > 0 && !(defined RENDER_TRANSLUCENT || defined RENDER_COMPUTE)
            if (rayIndex > 0) offset = -offset;
        #endif
    for (uint i = 0u; i < min(lightCount, MaxSampleCount); i++) {
        vec3 lightPos, lightColor, lightVec;
        float lightSize, lightRange, traceDist2;
        uvec4 lightData;

        //bool hasLight = false;
        //for (uint i2 = 0u; i2 < 16u; i2++) {
            uint lightIndex = (i * iStep + iOffset) % lightCount;
            if (i * iStep >= lightCount) break;
            //if (lightIndex >= lightCount) break;

            lightData = GetVoxelLight(gridIndex, lightIndex % lightCount);
            ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

            lightColor = RGBToLinear(lightColor);

            #ifdef DYN_LIGHT_INTERLEAVE_ENABLED
                lightColor *= interleaveCount;
                //lightColor *= min(iStep, lightCount);
            #endif

            float traceRange2 = lightRange + 0.5;
            traceRange2 = _pow2(traceRange2);

            lightVec = surfacePos - lightPos;
            traceDist2 = length2(lightVec);

            if (traceDist2 >= traceRange2) {
                //i++;
                continue;
            }

            //hasLight = true;
            //break;
        //}

        //if (!hasLight) continue;

        vec3 diffuseLightPos = lightPos;

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED && LIGHTING_TRACE_PENUMBRA > 0 && !(defined RENDER_TRANSLUCENT || defined RENDER_COMPUTE)
            //vec3 offset = GetLightPenumbraOffset() * Lighting_PenumbraF;
            diffuseLightPos += lightSize * offset;
        #endif

        vec3 lightSurfacePos = surfacePos;
        #ifndef RENDER_BILLBOARD
            //lightSurfacePos += localNormal * 0.0002;
        #endif

        lightVec = diffuseLightPos - lightSurfacePos;
        // if (abs(lightVec.x) < EPSILON) lightVec.x = EPSILON;
        // if (abs(lightVec.y) < EPSILON) lightVec.y = EPSILON;
        // if (abs(lightVec.z) < EPSILON) lightVec.z = EPSILON;

        vec3 lightDir = normalize(lightVec);
        // vec3 nextDist = (sign(lightDir) * 0.5 + 0.5 - surfacePosF) / lightDir;
        // lightVec -= lightDir * minOf(nextDist);

        //lightSurfacePos += fragLocalNormal * 0.0002;

        //lightColor = RGBToLinear(lightColor);

        uint traceFace = 1u << GetLightMaskFace(-lightVec);
        if ((lightData.z & traceFace) == traceFace) continue;

        // #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined RENDER_FRAG
            if ((lightData.z & 1u) == 1u) {
                vec3 traceOrigin = GetVoxelBlockPosition(diffuseLightPos);
                vec3 traceEnd = traceOrigin - lightVec;

                //vec3 traceOrigin = traceEnd - lightVec;

                #if LIGHTING_TRACED_PLAYER_SHADOW != PLAYER_SHADOW_NONE
                    if (!isSpectator) {
                    #ifdef RENDER_ENTITIES
                        if (entityId != ENTITY_PLAYER) {
                    #endif

                        vec3 playerPos = vec3(0.0, -0.8, 0.0);

                        #ifdef IS_IRIS
                            if (!firstPersonCamera) playerPos += eyePosition - cameraPosition;
                        #endif

                        playerPos = GetVoxelBlockPosition(playerPos);

                        vec3 playerOffset = traceOrigin - playerPos;
                        if (length2(playerOffset) < traceDist2) {
                            #if LIGHTING_TRACED_PLAYER_SHADOW == PLAYER_SHADOW_CYLINDER
                                bool hit = CylinderRayTest(traceOrigin - playerPos, traceEnd - traceOrigin, 0.36, 1.0);
                            #else
                                vec3 boundsMin = vec3(-0.36, -1.0, -0.36);
                                vec3 boundsMax = vec3( 0.36,  1.0,  0.36);

                                vec3 rayInv = rcp(traceEnd - traceOrigin);
                                bool hit = BoxRayTest(boundsMin, boundsMax, traceOrigin - playerPos, rayInv);
                            #endif
                            
                            if (hit) lightColor = vec3(0.0);
                        }

                    #ifdef RENDER_ENTITIES
                        }
                    #endif
                    }
                #endif

                bool traceSelf = ((lightData.z >> 1u) & 1u) == 1u;

                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange, traceSelf);
            }
        // #endif

        //vec3 lightDir = normalize(-lightVec);
        float geoNoL = 1.0;
        if (hasGeoNormal) geoNoL = dot(localNormal, lightDir);

        float diffuseNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

        float invAO = saturate(1.0 - occlusion);
        diffuseNoLm = max(diffuseNoLm - _pow2(invAO), 0.0);

        if (diffuseNoLm > EPSILON) {
            float lightAtt = GetLightAttenuation(lightVec, lightRange);

            vec3 lightH = normalize(lightDir + localViewDir);
            float lightLoHm = max(dot(lightDir, lightH), 0.0);

            vec3 F = vec3(0.0);
            #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                //float invCosTheta = 1.0 - lightVoHm;
                //F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                F = F_schlickRough(lightVoHm, f0, roughL);
            #endif

            //accumDiffuse += SampleLightDiffuse(diffuseNoLm, F) * lightAtt * lightColor;
            accumDiffuse += SampleLightDiffuse(lightNoVm, diffuseNoLm, lightLoHm, roughL) * lightAtt * lightColor * (1.0 - F);

            #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                // #if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                //     vec3 r = reflect(-localViewDir, texNormal);
                //     vec3 L = lightPos - surfacePos;
                //     vec3 centerToRay = dot(L, r) * r - L;
                //     vec3 closestPoint = L + centerToRay * saturate((lightSize * 0.5) / length(centerToRay));
                //     lightDir = normalize(closestPoint);
                // #endif

                //lightH = normalize(lightDir + localViewDir);

                float lightNoLm = max(dot(texNormal, lightDir), 0.0);
                float lightNoHm = max(dot(texNormal, lightH), EPSILON);
                float invGeoNoL = saturate(geoNoL*40.0 + 1.0);

                accumSpecular += invGeoNoL * SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, lightVoHm, F, roughL) * lightAtt * lightColor;
            #endif
        }
    }
    }

    blockDiffuse += accumDiffuse/LIGHTING_RAYCOUNT * Lighting_Brightness;
    blockSpecular += accumSpecular/LIGHTING_RAYCOUNT * Lighting_Brightness;
}
