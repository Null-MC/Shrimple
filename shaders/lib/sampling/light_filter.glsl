const vec2 lightSigma = vec2(1.6, 0.2);


void light_GaussianFilter(out vec3 blockDiffuse, out vec3 blockSpecular, const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in float roughL) {
    // const float c_halfSamplesX = LIGHTING_TRACE_FILTER;
    // const float c_halfSamplesY = LIGHTING_TRACE_FILTER;

    const float lightBufferScale = exp2(LIGHTING_TRACE_RES);
    const float lightBufferScaleInv = rcp(lightBufferScale);

    vec2 lightBufferSize = viewSize * lightBufferScaleInv;
    vec2 blendPixelSize = rcp(lightBufferSize);

    float total = 0.0;
    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);

    bool hasNormal = any(greaterThan(normal, EPSILON3));
    ivec2 centerCoord = ivec2(texcoord * lightBufferSize);
    
    for (float iy = -LIGHTING_TRACE_FILTER; iy <= LIGHTING_TRACE_FILTER; iy++) {
        float fy = Gaussian(lightSigma.x, iy);

        for (float ix = -LIGHTING_TRACE_FILTER; ix <= LIGHTING_TRACE_FILTER; ix++) {
            float fx = Gaussian(lightSigma.x, ix);

            // vec2 sampleBlendTex = texcoord - vec2(ix, iy) * blendPixelSize;
            ivec2 iOffset = ivec2(ix, iy);
            ivec2 srcCoord = centerCoord + iOffset;
            vec3 sampleDiffuse = texelFetch(BUFFER_BLOCK_DIFFUSE, srcCoord, 0).rgb;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec4 sampleSpecular = texelFetch(BUFFER_BLOCK_SPECULAR, srcCoord, 0);

                // TODO: WTF is this?!
                sampleSpecular.rgb *= 1.0 - min(4.0 * abs(sampleSpecular.a - roughL), 1.0);
            #endif

            // #if LIGHTING_TRACE_RES == 2
            //     ivec2 depthCoord = GetTemporalSampleCoord(ivec2(gl_FragCoord.xy+iOffset*lightBufferScale));// * 4 * pixelSize;
            // #elif LIGHTING_TRACE_RES == 1
            //     ivec2 depthCoord = GetTemporalSampleCoord(ivec2(gl_FragCoord.xy+iOffset*lightBufferScale));// * 2 * pixelSize;
            // #else
            //     ivec2 depthCoord = ivec2(gl_FragCoord.xy + iOffset);
            // #endif

            #if LIGHTING_TRACE_RES > 0
                ivec2 depthCoord = _GetTemporalSampleCoord(srcCoord) + iOffset*int(lightBufferScale);
            #else
                ivec2 depthCoord = ivec2(gl_FragCoord.xy) + iOffset;
            #endif

            #ifdef RENDER_OPAQUE_FINAL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif

            //float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;

            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);
            
            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_FINAL
                    float dhDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                if (dhDepthL < sampleDepthL || sampleDepth >= 1.0) {
                    //sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
                }
            #endif

            float normalWeight = 0.0;
            if (hasNormal) {
                //vec3 sampleNormal = textureLod(BUFFER_LIGHT_NORMAL, srcCoord, 0).rgb;
                uint sampleDeferredDataR = texelFetch(BUFFER_DEFERRED_DATA, depthCoord, 0).r;
                vec3 sampleNormal = unpackUnorm4x8(sampleDeferredDataR).xyz;

                if (any(greaterThan(sampleNormal, EPSILON3))) {
                    sampleNormal = normalize(sampleNormal * 2.0 - 1.0);

                    normalWeight = 1.0 - max(dot(normal, sampleNormal), 0.0);
                    //normalWeight = smootherstep(normalWeight);
                }
            }
            
            float fv = Gaussian(lightSigma.y, abs(sampleDepthL - linearDepth) + 2.0*normalWeight);
            
            float weight = fx*fy*fv;
            accumDiffuse += weight * sampleDiffuse;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                accumSpecular += weight * sampleSpecular.rgb;
            #endif

            total += weight;
        }
    }
    
    //total = max(total, EPSILON);
    if (total > EPSILON) {
        blockDiffuse = accumDiffuse / total;
        blockSpecular = accumSpecular / total;
    }
    else {
        blockDiffuse = vec3(0.0);
        blockSpecular = vec3(0.0);
    }
}
