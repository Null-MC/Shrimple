void SampleHandLight(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 fragLocalPos, const in vec3 fragLocalNormal, const in vec3 texNormal, const in float roughL, const in float metal_f0, const in float sss) {
    vec2 noiseSample = GetDynLightNoise(vec3(0.0));
    vec3 result = vec3(0.0);

    vec3 lightFragPos = fragLocalPos + 0.06 * fragLocalNormal;

    bool hasGeoNormal = !all(lessThan(abs(fragLocalNormal), EPSILON3));
    bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

    #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
        float f0 = GetMaterialF0(metal_f0);
        vec3 localViewDir = -normalize(fragLocalPos);

        float lightNoVm = 1.0;
        if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), 0.0);
    #endif

    float lightRangeR = GetSceneItemLightRange(heldItemId, heldBlockLightValue);
    float geoNoLm;

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

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    lightColor *= 1.0 - length(offset);
                    traceOrigin += offset * lightSize * 0.5;
                #endif

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    lightColor *= TraceRay(traceOrigin, traceEnd, lightRangeR);
                #else
                    lightColor *= TraceDDA(traceEnd, traceOrigin, lightRangeR);
                #endif
            #endif

            geoNoLm = 1.0;
            vec3 lightDir = normalize(lightVec);
            if (hasGeoNormal) geoNoLm = max(dot(fragLocalNormal, lightDir), 0.0);

            float lightNoLm = GetLightNoL(geoNoLm, texNormal, lightDir, sss);

            if (lightNoLm > EPSILON) {
                float lightAtt = GetLightAttenuation(lightVec, lightRangeR);

                float F = 0.0;
                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    vec3 lightH = normalize(lightDir + localViewDir);
                    float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    float invCosTheta = 1.0 - lightVoHm;
                    F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                #endif

                accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;

                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);

                    accumSpecular += SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
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

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                vec3 traceEnd = traceOrigin - 0.99*lightVec;

                #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && !defined RENDER_TRANSLUCENT
                    float lightSize = GetSceneItemLightSize(heldItemId2);
                    //ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    vec3 offset = GetLightPenumbraOffset();
                    lightColor *= 1.0 - length(offset);
                    traceOrigin += offset * lightSize * 0.5;
                #endif

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    lightColor *= TraceRay(traceOrigin, traceEnd, lightRangeL);
                #else
                    lightColor *= TraceDDA(traceEnd, traceOrigin, lightRangeL);
                #endif
            #endif
            
            geoNoLm = 1.0;
            vec3 lightDir = normalize(lightVec);
            if (hasGeoNormal) geoNoLm = max(dot(fragLocalNormal, lightDir), 0.0);

            float lightNoLm = GetLightNoL(geoNoLm, texNormal, lightDir, sss);

            if (lightNoLm > EPSILON) {
                float lightAtt = GetLightAttenuation(lightVec, lightRangeL);

                float F = 0.0;
                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    vec3 lightH = normalize(lightDir + localViewDir);
                    float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                    float invCosTheta = 1.0 - lightVoHm;
                    F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                #endif

                accumDiffuse += SampleLightDiffuse(lightNoLm, F) * lightAtt * lightColor;

                #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                    float lightNoHm = max(dot(texNormal, lightH), 0.0);

                    accumSpecular += SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
                #endif
            }
        }
    }

    blockDiffuse += accumDiffuse * DynamicLightBrightness;
    blockSpecular += accumSpecular * DynamicLightBrightness;
}
