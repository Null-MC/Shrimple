const float ParallaxDepthF = MATERIAL_PARALLAX_DEPTH * 0.01;
const float ParallaxSharpThreshold = 1.5/255.0;


struct ParallaxBounds {
    vec2 atlasTilePos;
    vec2 atlasTileSize;
    vec3 tanViewDir;
    float mip;
};

float GetParallaxStepFactor(const in int step) {
    float stepF = float(step) / float(MATERIAL_PARALLAX_SAMPLES);
//    stepF = pow(stepF, 2.0);
    stepF = _pow2(stepF);
    return stepF;
}

vec2 GetParallaxCoord(const in ParallaxBounds bounds, const in vec2 srcCoord, const in float viewDist, out float texDepth, out vec3 traceDepthResult) {
    vec2 localCoord = GetLocalCoord(srcCoord, bounds.atlasTilePos, bounds.atlasTileSize);

    #if MATERIAL_PARALLAX_TYPE != PARALLAX_SMOOTH
        float depth = textureLod(normals, srcCoord, bounds.mip).a;
        if (depth > 0.999) {
            texDepth = 1.0;
            traceDepthResult = vec3(0.0, 0.0, 1.0);
            return srcCoord;
        }
    #endif

    #ifdef MATERIAL_PARALLAX_OPTIMIZE
        const int parallax_mip = 2;
        //vec2 atlasSize = textureSize(normals, 0);
        vec2 atlasMipSize = textureSize(normals, parallax_mip);

        vec2 atlasCoord = GetAtlasCoord(localCoord, bounds.atlasTilePos, bounds.atlasTileSize);
        float depth = texelFetch(normals, ivec2(atlasCoord * atlasSize), 0).a;
        float mipDepth = texelFetch(normals, ivec2(atlasCoord * atlasMipSize), parallax_mip).a;

        float maxTexDepth = min(depth, mipDepth);
//        float maxTexDepth = min(depth, mipDepth) - 2.0 * (mipDepth - depth);
//        maxTexDepth = saturate(maxTexDepth);

//        vec2 preStepCoord = bounds.tanViewDir.xy * ParallaxDepthF / (bounds.tanViewDir.z*3.0 + 1.0);
//        atlasCoord = GetAtlasCoord(localCoord - preStepCoord, bounds.atlasTilePos, bounds.atlasTileSize);
//        maxTexDepth = min(maxTexDepth, texelFetch(normals, ivec2(atlasCoord * atlasMipSize), parallax_mip).a);

        maxTexDepth = 1.0 - maxTexDepth;
//        maxTexDepth = max(maxTexDepth, 0.1);
    #else
        const float maxTexDepth = 1.0;
    #endif

    vec2 stepCoordMax = bounds.tanViewDir.xy * (ParallaxDepthF * maxTexDepth) / bounds.tanViewDir.z;

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        float prevTexDepth;
    #endif

//    float viewDistF = 1.0 - saturate(viewDist / MATERIAL_PARALLAX_MAX_DIST);
//    float maxSampleCount = viewDistF * MATERIAL_PARALLAX_SAMPLES + 0.5;

//    vec2 localSize = atlasSize * bounds.atlasTileSize;
//    if (all(greaterThan(localSize, vec2(EPSILON))))
//        stepCoord *= localSize / maxOf(localSize);
//        stepCoord.y *= localSize.x / localSize.y;

    int i;
    texDepth = 1.0;
    for (i = 1; i <= MATERIAL_PARALLAX_SAMPLES; i++) {
        #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
            prevTexDepth = texDepth;
        #endif

        float stepF = GetParallaxStepFactor(i);
        vec2 localTraceCoord = localCoord - stepF * stepCoordMax;

        #ifdef MATERIAL_PARALLAX_CUTOUT
            bool cutout = saturate(localTraceCoord) != localTraceCoord;
            if (localTraceCoord.x < 0.0 && bitfieldExtract(vIn.wrapMask, 0, 1) == 1u) cutout = false;
            if (localTraceCoord.y < 0.0 && bitfieldExtract(vIn.wrapMask, 1, 1) == 1u) cutout = false;
            if (localTraceCoord.x > 1.0 && bitfieldExtract(vIn.wrapMask, 2, 1) == 1u) cutout = false;
            if (localTraceCoord.y > 1.0 && bitfieldExtract(vIn.wrapMask, 3, 1) == 1u) cutout = false;
            if (cutout) discard;
        #endif

        #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
            vec2 uv[4];
            vec2 atlasTileSize = bounds.atlasTileSize * atlasSize;
            vec2 f = GetLinearCoords(localTraceCoord, atlasTileSize, uv);

            uv[0] = GetAtlasCoord(uv[0], bounds.atlasTilePos, bounds.atlasTileSize);
            uv[1] = GetAtlasCoord(uv[1], bounds.atlasTilePos, bounds.atlasTileSize);
            uv[2] = GetAtlasCoord(uv[2], bounds.atlasTilePos, bounds.atlasTileSize);
            uv[3] = GetAtlasCoord(uv[3], bounds.atlasTilePos, bounds.atlasTileSize);

            texDepth = TextureLodLinear(normals, uv, bounds.mip, f, 3);
        #else
            vec2 traceAtlasCoord = GetAtlasCoord(localTraceCoord, bounds.atlasTilePos, bounds.atlasTileSize);
            texDepth = textureLod(normals, traceAtlasCoord, bounds.mip).a;
        #endif

        float traceDepth = 1.0 - stepF * maxTexDepth;
        if (traceDepth - texDepth < (1.0/255.0)) break;
    }

    float stepF = GetParallaxStepFactor(i);
    vec2 currentTraceOffset = localCoord - stepF * stepCoordMax;

    int i_prev = max(i - 1, 0);
    float stepF_prev = GetParallaxStepFactor(i_prev);
    vec2 prevTraceOffset = localCoord - stepF_prev * stepCoordMax;
    float prevTraceDepth = max(1.0 - stepF_prev * maxTexDepth, 0.0);

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        float currentTraceDepth = max(1.0 - stepF * maxTexDepth, 0.0);

        float t = (prevTraceDepth - prevTexDepth) / max(texDepth - prevTexDepth + prevTraceDepth - currentTraceDepth, EPSILON);
        t = saturate(t);

        traceDepthResult.xy = mix(prevTraceOffset, currentTraceOffset, t);
        traceDepthResult.z = mix(prevTraceDepth, currentTraceDepth, t);
    #else
        traceDepthResult.xy = prevTraceOffset;
        traceDepthResult.z = prevTraceDepth;
    #endif

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        return GetAtlasCoord(traceDepthResult.xy, bounds.atlasTilePos, bounds.atlasTileSize);
    #else
        return GetAtlasCoord(currentTraceOffset, bounds.atlasTilePos, bounds.atlasTileSize);
    #endif
}

//float GetParallaxShadow(const in vec3 traceTex, const in float mip, const in vec3 tanLightDir) {
//    vec2 stepCoord = tanLightDir.xy * ParallaxDepthF * (1.0 / (1.0 + tanLightDir.z * MATERIAL_PARALLAX_SHADOW_SAMPLES));
//    const float stepDepth = 1..0 / MATERIAL_PARALLAX_SHADOW_SAMPLES;
//
//    float skip = floor(traceTex.z * MATERIAL_PARALLAX_SHADOW_SAMPLES + 0.5) / MATERIAL_PARALLAX_SHADOW_SAMPLES;
//
//    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
//
//    float shadow = 1.0;
//    for (float i = 0.0; i < (MATERIAL_PARALLAX_SHADOW_SAMPLES+0.5); i += 1.0) {
//        if (i + skip > (MATERIAL_PARALLAX_SHADOW_SAMPLES+0.5)) break;
//        if (shadow < 0.001) break;
//
//        float stepF = i + dither;
//        float traceDepth = stepF * stepDepth + traceTex.z;
//        vec2 localCoord = stepF * stepCoord + traceTex.xy;
//
//        #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH && defined MATERIAL_PARALLAX_SHADOW_SMOOTH
//            vec2 uv[4];
//            vec2 atlasTileSize = vIn.atlasTileSize * atlasSize;
//            vec2 f = GetLinearCoords(localCoord, atlasTileSize, uv);
//
//            uv[0] = GetAtlasCoord(uv[0], vIn.atlasTilePos, vIn.atlasTileSize);
//            uv[1] = GetAtlasCoord(uv[1], vIn.atlasTilePos, vIn.atlasTileSize);
//            uv[2] = GetAtlasCoord(uv[2], vIn.atlasTilePos, vIn.atlasTileSize);
//            uv[3] = GetAtlasCoord(uv[3], vIn.atlasTilePos, vIn.atlasTileSize);
//
//            float texDepth = TextureLodLinear(normals, uv, mip, f, 3);
//        #else
//            vec2 atlasCoord = GetAtlasCoord(localCoord, vIn.atlasTilePos, vIn.atlasTileSize);
//            float texDepth = textureLod(normals, atlasCoord, mip).a;
//        #endif
//
//        #ifdef MATERIAL_PARALLAX_SOFTSHADOW
//            float depthF = max(texDepth - traceDepth, 0.0) / stepDepth;
//            shadow -= PARALLAX_SOFTSHADOW_FACTOR * depthF * stepDepth;
//        #else
//            shadow *= step(texDepth + EPSILON, traceDepth);
//        #endif
//    }
//
//    return max(shadow, 0.0);
//}

#if MATERIAL_PARALLAX_TYPE == PARALLAX_SHARP
    vec3 GetParallaxSlopeNormal(const in ParallaxBounds bounds, const in vec2 atlasCoord, const in float traceDepth) {
        vec2 atlasPixelSize = 1.0 / atlasSize;
        float atlasAspect = float(atlasSize.x) / float(atlasSize.y);

        vec2 tex_snapped = floor(atlasCoord * atlasSize) * atlasPixelSize;
        vec2 tex_offset = atlasCoord - (0.5 * atlasPixelSize + tex_snapped);

        vec2 stepSign = sign(tex_offset);
        vec2 viewSign = sign(-bounds.tanViewDir.xy);

        bool dir = abs(tex_offset.x  * atlasAspect) < abs(tex_offset.y);

        vec2 tex_x = vec2(dir ? viewSign.x : stepSign.x, 0.0);
        vec2 tex_y = vec2(0.0, dir ? stepSign.y : viewSign.y);

        vec2 tX = GetLocalCoord(atlasCoord + tex_x * atlasPixelSize, bounds.atlasTilePos, bounds.atlasTileSize);
        tX = GetAtlasCoord(tX, bounds.atlasTilePos, bounds.atlasTileSize);

        vec2 tY = GetLocalCoord(atlasCoord + tex_y * atlasPixelSize, bounds.atlasTilePos, bounds.atlasTileSize);
        tY = GetAtlasCoord(tY, bounds.atlasTilePos, bounds.atlasTileSize);

        float height_x = textureLod(normals, tX, bounds.mip).a;
        float height_y = textureLod(normals, tY, bounds.mip).a;

        bool preferY = abs(bounds.tanViewDir.y) > abs(bounds.tanViewDir.x);

        float heightA = dir ? height_y : height_x;
        float heightB = dir ? height_x : height_y;

        float viewA = dir ? viewSign.y : viewSign.x;
        float stepA = dir ? stepSign.y : stepSign.x;

        bool chooseY = (traceDepth > heightA) && (-viewA != stepA)
            ? dir : (traceDepth > heightB ? !dir : preferY);

        vec3 signMask = vec3(0.0);
        signMask[chooseY ? 1 : 0] = 1.0;
        return signMask * vec3(viewSign, 0.0);
    }
#endif
