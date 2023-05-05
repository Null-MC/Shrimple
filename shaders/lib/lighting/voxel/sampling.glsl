void SampleDynamicLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float roughL, const in float metal_f0, const in float sss, const in vec3 blockLightDefault) {
    uint gridIndex;
    float viewDist = length(localPos);
    vec3 localViewDir = -normalize(localPos);
    float distBiasScale = min(0.001*viewDist, 0.25);

    vec3 lightFragPos = localPos;
    lightFragPos += distBiasScale*localNormal;
    lightFragPos += distBiasScale*localViewDir;

    uint lightCount = GetSceneLights(lightFragPos, gridIndex);

    if (gridIndex != DYN_LIGHT_GRID_MAX) {
        bool hasGeoNormal = !all(lessThan(abs(localNormal), EPSILON3));
        bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

        #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
            float f0 = GetMaterialF0(metal_f0);
        #endif

        float lightNoVm = 1.0;
        if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), EPSILON);

        vec3 accumDiffuse = vec3(0.0);
        vec3 accumSpecular = vec3(0.0);

        vec3 traceEnd = GetLightGridPosition(lightFragPos);
        vec3 cameraOffset = fract(cameraPosition);

        for (uint i = 0u; i < lightCount; i++) {
            vec3 lightPos, lightColor, lightVec;
            float lightSize, lightRange, traceDist2;
            uvec4 lightData;

            //bool hasLight = false;
            //for (uint i2 = 0u; i2 < 16u; i2++) {
                lightData = GetSceneLight(gridIndex, i);
                ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                float traceRange2 = lightRange + 0.5;
                traceRange2 = _pow2(traceRange2);

                lightVec = lightFragPos - lightPos;
                traceDist2 = length2(lightVec);

                if (traceDist2 >= traceRange2) {
                    //i++;
                    continue;
                }

                //hasLight = true;
                //break;
            //}

            //if (!hasLight) continue;

            #if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                float pad = 0.5 - clamp(lightSize * 0.5, 0.06, 0.44);

                vec3 lightMin = floor(lightPos + cameraOffset) - cameraOffset + pad;
                vec3 lightMax = lightMin + 1.0 - 2.0*pad;

                //vec3 diffuseLightPos = lightPos;
                vec3 diffuseLightPos = clamp(lightFragPos, lightMin, lightMax);
            #else
                vec3 diffuseLightPos = lightPos;
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && !(defined RENDER_TRANSLUCENT || defined RENDER_COMPUTE)
                vec3 offset = GetLightPenumbraOffset() * lightSize * DynamicLightPenumbraF;

                #if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                    diffuseLightPos = clamp(diffuseLightPos + offset, lightMin, lightMax);
                #else
                    diffuseLightPos += offset;
                #endif
            #endif

            lightVec = lightFragPos - diffuseLightPos;
            if (abs(lightVec.x) < EPSILON) lightVec.x = EPSILON;
            if (abs(lightVec.y) < EPSILON) lightVec.y = EPSILON;
            if (abs(lightVec.z) < EPSILON) lightVec.z = EPSILON;

            lightColor = RGBToLinear(lightColor);

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                uint traceFace = 1u << GetLightMaskFace(lightVec);
                if ((lightData.z & traceFace) == traceFace) continue;
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                if ((lightData.z & 1u) == 1u) {
                    vec3 traceOrigin = traceEnd - lightVec;

                    if (!isSpectator) {
                    #ifdef RENDER_ENTITIES
                        if (entityId != ENTITY_PLAYER) {
                    #endif

                        #if DYN_LIGHT_PLAYER_SHADOW != PLAYER_SHADOW_NONE
                            vec3 playerPos = vec3(0.0, -0.8, 0.0);

                            #ifdef IS_IRIS
                                if (!firstPersonCamera) playerPos += eyePosition - cameraPosition;
                            #endif

                            playerPos = GetLightGridPosition(playerPos);

                            vec3 playerOffset = traceOrigin - playerPos;
                            if (length2(playerOffset) < traceDist2) {
                                #if DYN_LIGHT_PLAYER_SHADOW == PLAYER_SHADOW_CYLINDER
                                    bool hit = CylinderRayTest(traceOrigin - playerPos, traceEnd - traceOrigin, 0.36, 1.0);
                                #else
                                    vec3 boundsMin = vec3(-0.36, -1.0, -0.36);
                                    vec3 boundsMax = vec3( 0.36,  1.0,  0.36);

                                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                        bool hit = BoxPointTest(boundsMin, boundsMax, rayStart - playerPos);
                                    #else
                                        vec3 rayInv = rcp(traceEnd - traceOrigin);
                                        bool hit = BoxRayTest(boundsMin, boundsMax, traceOrigin - playerPos, rayInv);
                                    #endif
                                #endif
                                
                                if (hit) lightColor = vec3(0.0);
                            }
                        #endif

                    #ifdef RENDER_ENTITIES
                        }
                    #endif
                    }

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, lightRange);
                    #else
                        lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange);
                    #endif
                }
            #endif

            vec3 lightDir = normalize(-lightVec);
            float geoNoL = 1.0;
            if (hasGeoNormal) geoNoL = dot(localNormal, lightDir);

            float diffuseNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

            if (diffuseNoLm > EPSILON) {
                float lightAtt = GetLightAttenuation(lightVec, lightRange);

                vec3 lightH = normalize(lightDir + localViewDir);
                float lightLoHm = max(dot(lightDir, lightH), 0.0);

                float F = 0.0;
                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    //float invCosTheta = 1.0 - lightVoHm;
                    //F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                    F = F_schlickRough(lightVoHm, f0, roughL);
                #endif

                //accumDiffuse += SampleLightDiffuse(diffuseNoLm, F) * lightAtt * lightColor;
                accumDiffuse += SampleLightDiffuse(lightNoVm, diffuseNoLm, lightLoHm, roughL) * lightAtt * lightColor * (1.0 - F);

                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    #if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                        vec3 r = reflect(-localViewDir, texNormal);
                        vec3 L = lightPos - lightFragPos;
                        vec3 centerToRay = dot(L, r) * r - L;
                        vec3 closestPoint = L + centerToRay * saturate((lightSize * 0.5) / length(centerToRay));
                        lightDir = normalize(closestPoint);
                    #endif

                    lightH = normalize(lightDir + localViewDir);

                    float lightNoLm = max(dot(texNormal, lightDir), 0.0);
                    float lightNoHm = max(dot(texNormal, lightH), EPSILON);
                    float invGeoNoL = saturate(geoNoL*40.0 + 1.0);

                    accumSpecular += invGeoNoL * SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
                #endif
            }
        }

        accumDiffuse *= DynamicLightBrightness;
        accumSpecular *= DynamicLightBrightness;

        #ifdef DYN_LIGHT_FALLBACK
            // TODO: shrink to shadow bounds
            vec3 offsetPos = localPos + LightGridCenter;
            float fade = minOf(min(offsetPos, SceneLightSize - offsetPos)) / 8.0;
            accumDiffuse = mix(blockLightDefault, accumDiffuse, saturate(fade));
            accumSpecular = mix(vec3(0.0), accumSpecular, saturate(fade));
        #endif

        #if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
            accumSpecular *= invPI;
        #endif

        blockDiffuse += accumDiffuse;
        blockSpecular += accumSpecular;
    }
    else {
        #ifdef DYN_LIGHT_FALLBACK
            blockDiffuse += blockLightDefault;
        #endif
    }
}
