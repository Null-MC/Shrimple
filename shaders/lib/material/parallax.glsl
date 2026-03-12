const float ParallaxDepthF = MATERIAL_PARALLAX_DEPTH * 0.01;
const float ParallaxSharpThreshold = 1.5/255.0;


struct ParallaxBounds {
    vec2 atlasTilePos;
    vec2 atlasTileSize;
    vec3 tanViewDir;
    float mip;
};

vec2 GetParallaxCoord(const in ParallaxBounds bounds, const in vec2 localCoord, const in float viewDist, out float texDepth, out vec3 traceDepth) {
    #ifdef MATERIAL_PARALLAX_OPTIMIZE
        vec2 atlasCoord = GetAtlasCoord(localCoord, bounds.atlasTilePos, bounds.atlasTileSize);
        float maxTexDepth = 1.0 - texelFetch(normals, ivec2(atlasCoord * atlasSize), 2).a;
        maxTexDepth = sqrt(maxTexDepth);
    #else
        const float maxTexDepth = 1.0;
    #endif

    vec2 stepCoord = bounds.tanViewDir.xy * (ParallaxDepthF * maxTexDepth) / (bounds.tanViewDir.z * MATERIAL_PARALLAX_SAMPLES + 1.0);
    const float stepDepth = maxTexDepth / MATERIAL_PARALLAX_SAMPLES;

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        vec2 atlasPixelSize = 1.0 / atlasSize;
        float prevTexDepth;
    #endif

    float viewDistF = 1.0 - saturate(viewDist / MATERIAL_PARALLAX_MAX_DIST);
    float maxSampleCount = viewDistF * MATERIAL_PARALLAX_SAMPLES + 0.5;

    vec2 localSize = atlasSize * vIn.atlasTileSize;
    if (all(greaterThan(localSize, vec2(EPSILON))))
        stepCoord.y *= localSize.x / localSize.y;

    float i;
    texDepth = 1.0;
    float depthDist = 1.0;
    for (i = 0.0; i < (MATERIAL_PARALLAX_SAMPLES+0.5); i += 1.0) {
        if (i > maxSampleCount || depthDist < (1.0/255.0)) break;

        #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
            prevTexDepth = texDepth;
        #endif

        vec2 localTraceCoord = localCoord - i * stepCoord;

        #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
            vec2 uv[4];
            vec2 atlasTileSize = vIn.atlasTileSize * atlasSize;
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

        depthDist = 1.0 - i * stepDepth - texDepth;
    }

    i = max(i - 1.0, 0.0);
    float pI = max(i - 1.0, 0.0);

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        vec2 currentTraceOffset = localCoord - i * stepCoord;
        float currentTraceDepth = max(1.0 - i * stepDepth, 0.0);
        vec2 prevTraceOffset = localCoord - pI * stepCoord;
        float prevTraceDepth = max(1.0 - pI * stepDepth, 0.0);

        float t = (prevTraceDepth - prevTexDepth) / max(texDepth - prevTexDepth + prevTraceDepth - currentTraceDepth, EPSILON);
        t = clamp(t, 0.0, 1.0);

        traceDepth.xy = mix(prevTraceOffset, currentTraceOffset, t);
        traceDepth.z = mix(prevTraceDepth, currentTraceDepth, t);
    #else
        traceDepth.xy = localCoord - pI * stepCoord;
        traceDepth.z = max(1.0 - pI * stepDepth, 0.0);
    #endif

    #if MATERIAL_PARALLAX_TYPE == PARALLAX_SMOOTH
        return GetAtlasCoord(traceDepth.xy, bounds.atlasTilePos, bounds.atlasTileSize);
    #else
        return GetAtlasCoord(localCoord - i * stepCoord, bounds.atlasTilePos, bounds.atlasTileSize);
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
