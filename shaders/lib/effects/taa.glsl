void neighborClampColor(inout vec3 colorPrev, const in vec2 texcoord) {
    vec3 minColor = vec3(999.0);
    vec3 maxColor = vec3(0.0);

    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 sampleCoord = vec2(x, y) * pixelSize + texcoord;
            // vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, 0).rgb;
            vec3 sampleColor = texelFetch(BUFFER_FINAL, ivec2(sampleCoord * viewSize), 0).rgb;

            minColor = min(minColor, sampleColor);
            maxColor = max(maxColor, sampleColor);
        }
    }
    
    colorPrev = clamp(colorPrev, minColor, maxColor);
}

vec3 ApplyTAA(const in vec2 texcoord) {
    //vec2 uvNow = texcoord;

    //vec2 jitter = getJitterOffset(frameCounter);
    vec2 uvNowJitter = texcoord;// - 0.5*jitter;
    //uvNow -= 0.5*jitter;

    float depthNow = textureLod(depthtex1, uvNowJitter, 0).r;
    float depthNowHand = textureLod(depthtex2, uvNowJitter, 0).r;
    bool isHand = abs(depthNow - depthNowHand) > EPSILON;

    if (isHand) {
        depthNow = depthNow * 2.0 - 1.0;
        depthNow /= MC_HAND_DEPTH;
        depthNow = depthNow * 0.5 + 0.5;
    }

    float depthNowL = linearizeDepthFast(depthNow, near, farPlane);
    bool isDepthDh = false;

    #ifdef DISTANT_HORIZONS
        float dhDepth = textureLod(dhDepthTex1, uvNowJitter, 0).r;
        float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

        if (depthNow >= 1.0 || (dhDepthL < depthNowL && dhDepth > 0.0)) {
            depthNow = dhDepth;
            depthNowL = dhDepthL;
            isDepthDh = true;
        }
    #endif

    vec3 colorNow = textureLod(BUFFER_FINAL, texcoord, 0).rgb;
    vec4 velocity = textureLod(BUFFER_VELOCITY, texcoord, 0);

    vec3 clipPosRepro = getReprojectedClipPos(texcoord, depthNow, velocity.xyz, isDepthDh);

    vec2 uvPrev = clipPosRepro.xy;

    #ifdef EFFECT_TAA_SHARPEN
        vec3 colorPrev = sampleHistoryCatmullRom(uvPrev).rgb;
    #else
        vec3 colorPrev = textureLod(BUFFER_FINAL_PREV, uvPrev, 0).rgb;
    #endif

    neighborClampColor(colorPrev, texcoord);

    const float weightMax = rcp(EFFECT_TAA_MAX_ACCUM);

    float weight = weightMax;
    if (saturate(uvPrev) != uvPrev) weight = 1.0;
    vec3 colorFinal = mix(colorPrev, colorNow, weight);

    return clamp(colorFinal, 0.0, 65000.0);
}