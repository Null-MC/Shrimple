// https://www.shadertoy.com/view/4tcXD2

vec3 encodePalYuv(vec3 rgb) {
    // rgb = RGBToLinear(rgb);

    return vec3(
        dot(rgb, vec3(0.299, 0.587, 0.114)),
        dot(rgb, vec3(-0.14713, -0.28886, 0.436)),
        dot(rgb, vec3(0.615, -0.51499, -0.10001))
    );
}

vec3 decodePalYuv(vec3 yuv) {
    vec3 rgb = vec3(
        dot(yuv, vec3(1.0, 0.0, 1.13983)),
        dot(yuv, vec3(1.0, -0.39465, -0.58060)),
        dot(yuv, vec3(1.0, 2.03211, 0.0))
    );

    // return LinearToRGB(rgb);
    return rgb;
}


vec4 ApplyTAA(const in vec2 uv) {
    float depth = textureLod(depthtex1, uv, 0).r;
    vec3 velocity = textureLod(BUFFER_VELOCITY, texcoord, 0).xyz;
    vec2 uvLast = getReprojectedClipPos(texcoord, depth, velocity, false).xy;

	//vec2 uv = fragCoord.xy / iResolution.xy;
    //vec4 lastColor = textureLod(BUFFER_FINAL_PREV, uvLast, 0);

    #ifdef EFFECT_TAA_SHARPEN
        vec4 lastColor = sampleHistoryCatmullRom(uvLast);
    #else
        vec4 lastColor = textureLod(BUFFER_FINAL_PREV, uvLast, 0);
    #endif
    
    vec3 antialiased = lastColor.rgb;
    float mixRate = min(lastColor.a, 0.5);
    
    vec2 off = pixelSize;// 1.0 / iResolution.xy;
    vec3 in0 = textureLod(BUFFER_FINAL, uv, 0).rgb;
    
    antialiased = mix(antialiased * antialiased, in0 * in0, mixRate);
    antialiased = sqrt(antialiased);
    
    vec3 in1 = textureLod(BUFFER_FINAL, uv + vec2(+off.x, 0.0), 0).rgb;
    vec3 in2 = textureLod(BUFFER_FINAL, uv + vec2(-off.x, 0.0), 0).rgb;
    vec3 in3 = textureLod(BUFFER_FINAL, uv + vec2(0.0, +off.y), 0).rgb;
    vec3 in4 = textureLod(BUFFER_FINAL, uv + vec2(0.0, -off.y), 0).rgb;
    vec3 in5 = textureLod(BUFFER_FINAL, uv + vec2(+off.x, +off.y), 0).rgb;
    vec3 in6 = textureLod(BUFFER_FINAL, uv + vec2(-off.x, +off.y), 0).rgb;
    vec3 in7 = textureLod(BUFFER_FINAL, uv + vec2(+off.x, -off.y), 0).rgb;
    vec3 in8 = textureLod(BUFFER_FINAL, uv + vec2(-off.x, -off.y), 0).rgb;
    
    antialiased = encodePalYuv(antialiased);
    in0 = encodePalYuv(in0);
    in1 = encodePalYuv(in1);
    in2 = encodePalYuv(in2);
    in3 = encodePalYuv(in3);
    in4 = encodePalYuv(in4);
    in5 = encodePalYuv(in5);
    in6 = encodePalYuv(in6);
    in7 = encodePalYuv(in7);
    in8 = encodePalYuv(in8);
    
    vec3 minColor = min(min(min(in0, in1), min(in2, in3)), in4);
    vec3 maxColor = max(max(max(in0, in1), max(in2, in3)), in4);

    minColor = mix(minColor,
       min(min(min(in5, in6), min(in7, in8)), minColor), 0.5);

    maxColor = mix(maxColor,
       max(max(max(in5, in6), max(in7, in8)), maxColor), 0.5);
    
   	vec3 preclamping = antialiased;
    antialiased = clamp(antialiased, minColor, maxColor);
    
    mixRate = rcp(1.0 / mixRate + 1.0);
    
    vec3 diff = antialiased - preclamping;
    float clampAmount = dot(diff, diff);
    
    const float weightMax = rcp(EFFECT_TAA_MAX_ACCUM);
    
    mixRate += clampAmount * 4.0;
    mixRate = clamp(mixRate, weightMax, 0.5);
    
    antialiased = decodePalYuv(antialiased);
        
    return vec4(antialiased, mixRate);
}
