mat2 GetBlurRotation() {
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float angle = dither * TAU;
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

vec3 GetBlur(const in vec2 texcoord, const in float fragDepthL, const in float viewDist, const in float distScale) {
    const uint maxSampleCount = 16;
    const float maxRadius = 12.0;

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 pixelSize = rcp(viewSize);

    // float depth = textureLod(depthtex0, texcoord, 0).r;
    // float depthL = linearizeDepthFast(depth, near, far);

    // vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
    // vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
    // float viewDist = length(viewPos);

    // float distScale = isEyeInWater == 1 ? 20.0 : 80.0;
    float distF = min(viewDist / distScale, 1.0);

    uint sampleCount = 1;
    if (distScale > EPSILON)
        sampleCount = uint(ceil(maxSampleCount * distF));

    const float goldenAngle = PI * (3.0 - sqrt(5.0));
    const float PHI = (1.0 + sqrt(5.0)) / 2.0;

    mat2 rotation = GetBlurRotation();

    float radius = distF * maxRadius;

    vec3 color = vec3(0.0);
    float maxWeight = 0.0;

    for (uint i = 0; i < sampleCount; i++) {
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
            float sampleDepth = texelFetch(depthtex1, sampleUV, 0).r;
            float sampleDepthL = linearizeDepthFast(sampleDepth, near, far);

            float minDepth = min(fragDepthL, sampleDepthL);
            sampleWeight *= min(minDepth / distScale, 1.0);
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
