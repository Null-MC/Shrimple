mat2 GetBlurRotation() {
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float angle = dither * TAU;
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

vec3 GetBlur(const in sampler2D depthSampler, const in vec2 texcoord, const in float fragDepthL, const in float minDepth, const in float viewDist, const in float distScale) {
    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 pixelSize = rcp(viewSize);

    float distF = min(viewDist / distScale, 1.0);
    distF = pow(distF, 1.25);

    uint sampleCount = 1;
    if (distScale > EPSILON)
        sampleCount = uint(ceil(DIST_BLUR_SAMPLES * distF));

    const float goldenAngle = PI * (3.0 - sqrt(5.0));
    const float PHI = (1.0 + sqrt(5.0)) / 2.0;

    mat2 rotation = GetBlurRotation();
    float radius = distF * DIST_BLUR_RADIUS;

    vec3 color = vec3(0.0);
    float maxWeight = 0.0;

    for (uint i = 0; i < min(sampleCount, DIST_BLUR_SAMPLES); i++) {
        vec2 sampleCoord = texcoord;
        vec2 diskOffset = vec2(0.0);

        if (sampleCount > 1) {
            float r = sqrt((i + 0.5) / sampleCount);
            float theta = i * goldenAngle + PHI;
            
            float sine = sin(theta);
            float cosine = cos(theta);
            
            diskOffset = rotation * (vec2(cosine, sine) * r);
            sampleCoord = saturate(sampleCoord + diskOffset * radius * pixelSize);
        }

        ivec2 sampleUV = ivec2(sampleCoord * viewSize);
        vec3 sampleColor = texelFetch(BUFFER_FINAL, sampleUV, 0).rgb;
        float sampleWeight = exp(-length2(diskOffset));

        if (sampleCount > 1) {
            float sampleDepth = texelFetch(depthSampler, sampleUV, 0).r;
            float sampleDepthL = linearizeDepthFast(sampleDepth, near, far);
            sampleWeight *= step(minDepth, sampleDepth);

            float minSampleDepth = max(min(fragDepthL, sampleDepthL) - minDepth, 0.0);
            sampleWeight *= min(minSampleDepth / distScale, 1.0);
        }

        color += sampleColor * sampleWeight;
        maxWeight += sampleWeight;
    }

    if (maxWeight < 1.0) {
        color += textureLod(BUFFER_FINAL, texcoord, 0.0).rgb * (1.0 - maxWeight);
    }
    else {
        color /= maxWeight;
    }

    return color;
}
