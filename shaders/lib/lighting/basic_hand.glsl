void OffsetPlayerHandLight(inout vec3 lightLocalPos) {
    if (firstPersonCamera) {
        lightLocalPos = mul3(gbufferModelViewInverse, lightLocalPos);
    }
    else {
        const vec3 world_up = vec3(0.0, 1.0, 0.0);
        vec3 player_right = normalize(cross(playerBodyVector, world_up));
        vec3 player_forward = normalize(cross(world_up, player_right));

        // vec3 up = cross(playerBodyVector, right);

        mat3 rotation = mat3(player_right, world_up, player_forward);

        // mat3 rotation = rotateY(?);

        lightLocalPos = rotation * lightLocalPos;
        lightLocalPos -= relativeEyePosition;
    }
}

void SampleHandLight(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 fragLocalPos, const in vec3 fragLocalNormal, const in vec3 texNormal, const in vec3 albedo, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
    vec3 result = vec3(0.0);
    vec2 noiseSample = vec2(0.0);

    #ifdef LIGHTING_FLICKER
        noiseSample = GetDynLightNoise(vec3(0.0));
    #endif

    vec3 surfacePos = fragLocalPos;
    //surfacePos -= fragLocalNormal * 0.002;

    vec3 localViewDir = -normalize(fragLocalPos);
    bool hasGeoNormal = !all(lessThan(abs(fragLocalNormal), EPSILON3));
    bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

    float lightNoVm = 1.0;
    if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), 0.0);

    float lightRangeR = GetSceneItemLightRange(heldItemId, heldBlockLightValue);
    float geoNoL;

    #ifdef LIGHTING_TRACE_AO_SHADOWS
        float invAO = saturate(1.0 - occlusion);
        invAO = _pow2(invAO);
    #endif

    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);

    if (lightRangeR > 0.0) {
        vec3 lightLocalPos = HandLight_OffsetR;
        OffsetPlayerHandLight(lightLocalPos);

        vec3 lightVec = lightLocalPos - surfacePos;
        float traceDist2 = length2(lightVec);

        if (traceDist2 < _pow2(lightRangeR)) {
            vec3 lightColor = GetSceneItemLightColor(heldItemId, noiseSample);

            //lightColor = RGBToLinear(lightColor);

            #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE_HAND == HAND_LIGHT_TRACED && defined RENDER_FRAG //&& (defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
                #if LIGHTING_TRACE_PENUMBRA > 0 //&& !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    //lightColor *= 1.0 - length(offset);

                    lightLocalPos += offset * lightSize * 0.5;
                #endif

                vec3 lightDir = normalize(lightVec);

                // vec3 nextDist = (sign(lightDir) * 0.5 + 0.5 - fract(surfacePos + cameraPosition)) / lightDir;
                // vec3 _surfacePos = surfacePos + lightDir * minOf(nextDist);
                // _surfacePos += fragLocalNormal * 0.0002;
                lightVec = lightLocalPos - surfacePos;

                vec3 traceOrigin = GetVoxelBlockPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                bool traceSelf = false; //lightData.z & 1u;

                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRangeR, traceSelf);
            #else
                vec3 lightDir = normalize(lightVec);
            #endif

            geoNoL = 1.0;
            if (hasGeoNormal) geoNoL = dot(fragLocalNormal, lightDir);

            float lightNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

            #ifdef LIGHTING_TRACE_AO_SHADOWS
                lightNoLm = max(lightNoLm - invAO, 0.0);
            #endif

            if (lightNoLm > EPSILON) {
                vec2 lightAtt = GetLightAttenuation(lightVec, lightRangeR);

                vec3 lightH = normalize(lightDir + localViewDir);
                float lightLoHm = max(dot(lightDir, lightH), 0.0);

                vec3 F = vec3(0.0);
                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    // float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    F = GetMaterialFresnel(albedo, metal_f0, roughL, lightLoHm, false);
                #endif

                //accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;
                float D = SampleLightDiffuse(lightNoVm, lightNoLm, lightLoHm, roughL);
                accumDiffuse += D * lightAtt.x * lightColor * (1.0 - F);

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    //float invGeoNoL = saturate(geoNoL*40.0 + 1.0);
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);

                    float invGeoNoL = 1.0;// - saturate(-geoNoL*40.0);
                    accumSpecular += invGeoNoL * SampleLightSpecular(lightNoLm, lightNoHm, lightLoHm, F, roughL) * lightAtt.y * lightColor;
                #endif
            }
        }
    }

    float lightRangeL = GetSceneItemLightRange(heldItemId2, heldBlockLightValue2);

    if (lightRangeL > 0.0) {
        vec3 lightLocalPos = HandLight_OffsetL;
        OffsetPlayerHandLight(lightLocalPos);

        vec3 lightVec = lightLocalPos - fragLocalPos;
        if (length2(lightVec) < _pow2(lightRangeL)) {
            vec3 lightColor = GetSceneItemLightColor(heldItemId2, noiseSample);

            //lightColor = RGBToLinear(lightColor);

            #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE_HAND == HAND_LIGHT_TRACED && defined RENDER_FRAG //&& (defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
                #if LIGHTING_TRACE_PENUMBRA > 0 //&& !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId2);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    //lightColor *= 1.0 - length(offset);
                    lightLocalPos += offset * lightSize * 0.5;
                #endif

                vec3 lightDir = normalize(lightVec);

                // vec3 nextDist = (sign(lightDir) * 0.5 + 0.5 - fract(surfacePos + cameraPosition)) / lightDir;
                // vec3 _surfacePos = surfacePos + lightDir * minOf(nextDist);
                // _surfacePos += fragLocalNormal * 0.0002;
                lightVec = lightLocalPos - surfacePos;

                vec3 traceOrigin = GetVoxelBlockPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                bool traceSelf = false; //lightData.z & 1u;

                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRangeL, traceSelf);
            #else
                vec3 lightDir = normalize(lightVec);
            #endif
            
            geoNoL = 1.0;
            if (hasGeoNormal) geoNoL = dot(fragLocalNormal, lightDir);

            float lightNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

            #ifdef LIGHTING_TRACE_AO_SHADOWS
                lightNoLm = max(lightNoLm - invAO, 0.0);
            #endif

            if (lightNoLm > EPSILON) {
                vec2 lightAtt = GetLightAttenuation(lightVec, lightRangeL);

                vec3 lightH = normalize(lightDir + localViewDir);
                float lightLoHm = max(dot(lightDir, lightH), 0.0);

                vec3 F = vec3(0.0);
                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    // float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    F = GetMaterialFresnel(albedo, metal_f0, roughL, lightLoHm, false);
                #endif

                //accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;
                accumDiffuse += SampleLightDiffuse(lightNoVm, lightNoLm, lightLoHm, roughL) * lightAtt.x * lightColor * (1.0 - F);

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    float invGeoNoL = saturate(geoNoL*40.0 + 1.0);
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);

                    accumSpecular += invGeoNoL * SampleLightSpecular(lightNoLm, lightNoHm, lightLoHm, F, roughL) * lightAtt.y * lightColor;
                #endif
            }
        }
    }

    blockDiffuse += accumDiffuse * Lighting_Brightness;
    blockSpecular += accumSpecular * Lighting_Brightness;
}
