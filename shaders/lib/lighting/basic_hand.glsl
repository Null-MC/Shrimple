void SampleHandLight(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 fragLocalPos, const in vec3 fragLocalNormal, const in vec3 texNormal, const in vec3 albedo, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
    vec3 result = vec3(0.0);
    vec2 noiseSample = vec2(0.0);

    #ifdef DYN_LIGHT_FLICKER
        noiseSample = GetDynLightNoise(vec3(0.0));
    #endif

    float viewDist = length(fragLocalPos);
    vec3 localViewDir = -normalize(fragLocalPos);
    float distBiasScale = min(0.001*viewDist, 0.25);
    
    vec3 lightFragPos = fragLocalPos;
    lightFragPos += distBiasScale*fragLocalNormal;
    lightFragPos += distBiasScale*localViewDir;

    bool hasGeoNormal = !all(lessThan(abs(fragLocalNormal), EPSILON3));
    bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

    #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
        vec3 f0 = GetMaterialF0(albedo, metal_f0);
    #endif

    float lightNoVm = 1.0;
    if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), 0.0);

    float lightRangeR = GetSceneItemLightRange(heldItemId, heldBlockLightValue);
    float geoNoL;

    float invAO = saturate(1.0 - occlusion);

    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);

    if (lightRangeR > 0.0) {
        vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetR, 1.0)).xyz;

        #ifdef IS_IRIS
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;
            //if (!firstPersonCamera) lightLocalPos = HandLightPos1;
        #endif

        vec3 lightVec = lightLocalPos - lightFragPos;
        float traceDist2 = length2(lightVec);

        if (traceDist2 < _pow2(lightRangeR)) {
            vec3 lightColor = GetSceneItemLightColor(heldItemId, noiseSample);

            //lightColor = RGBToLinear(lightColor);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined RENDER_FRAG && (defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
                vec3 traceOrigin = GetVoxelBlockPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                #if defined LIGHT_HAND_SOFT_SHADOW && DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    //lightColor *= 1.0 - length(offset);
                    traceOrigin += offset * lightSize * 0.5;
                #endif

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    lightColor *= TraceRay(traceOrigin, traceEnd, lightRangeR);
                #else
                    lightColor *= TraceDDA(traceOrigin, traceEnd, lightRangeR);
                #endif
            #endif

            geoNoL = 1.0;
            vec3 lightDir = normalize(lightVec);
            if (hasGeoNormal) geoNoL = dot(fragLocalNormal, lightDir);

            float lightNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

            lightNoLm = max(lightNoLm - _pow2(invAO), 0.0);

            if (lightNoLm > EPSILON) {
                float lightAtt = GetLightAttenuation(lightVec, lightRangeR);

                vec3 lightH = normalize(lightDir + localViewDir);
                float lightLoHm = max(dot(lightDir, lightH), 0.0);

                vec3 F = vec3(0.0);
                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    //float invCosTheta = 1.0 - lightVoHm;
                    //F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                    F = F_schlickRough(lightVoHm, f0, roughL);
                #endif

                //accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;
                float D = SampleLightDiffuse(lightNoVm, lightNoLm, lightLoHm, roughL);
                accumDiffuse += D * lightAtt * lightColor * (1.0 - F);

                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);
                    float invGeoNoL = saturate(geoNoL*40.0 + 1.0);

                    accumSpecular += invGeoNoL * SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
                #endif
            }
        }
    }

    float lightRangeL = GetSceneItemLightRange(heldItemId2, heldBlockLightValue2);

    if (lightRangeL > 0.0) {
        vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetL, 1.0)).xyz;

        #ifdef IS_IRIS
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;
        #endif

        vec3 lightVec = lightLocalPos - lightFragPos;
        if (dot(lightVec, lightVec) < _pow2(lightRangeL)) {
            vec3 lightColor = GetSceneItemLightColor(heldItemId2, noiseSample);

            //lightColor = RGBToLinear(lightColor);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined RENDER_FRAG && (defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
                vec3 traceOrigin = GetVoxelBlockPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                #if defined LIGHT_HAND_SOFT_SHADOW && DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId2);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    //lightColor *= 1.0 - length(offset);
                    traceOrigin += offset * lightSize * 0.5;
                #endif

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    lightColor *= TraceRay(traceOrigin, traceEnd, lightRangeL);
                #else
                    lightColor *= TraceDDA(traceOrigin, traceEnd, lightRangeL);
                #endif
            #endif
            
            geoNoL = 1.0;
            vec3 lightDir = normalize(lightVec);
            if (hasGeoNormal) geoNoL = dot(fragLocalNormal, lightDir);

            float lightNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

            lightNoLm = max(lightNoLm - _pow2(invAO), 0.0);

            if (lightNoLm > EPSILON) {
                float lightAtt = GetLightAttenuation(lightVec, lightRangeL);

                vec3 lightH = normalize(lightDir + localViewDir);
                float lightLoHm = max(dot(lightDir, lightH), 0.0);

                vec3 F = vec3(0.0);
                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    //float invCosTheta = 1.0 - lightVoHm;
                    //F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                    F = F_schlickRough(lightVoHm, f0, roughL);
                #endif

                //accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;
                accumDiffuse += SampleLightDiffuse(lightNoVm, lightNoLm, lightLoHm, roughL) * lightAtt * lightColor * (1.0 - F);

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);
                    float invGeoNoL = saturate(geoNoL*40.0 + 1.0);

                    accumSpecular += invGeoNoL * SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
                #endif
            }
        }
    }

    blockDiffuse += accumDiffuse * DynamicLightBrightness;
    blockSpecular += accumSpecular * DynamicLightBrightness;
}
