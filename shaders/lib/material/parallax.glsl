vec2 GetParallaxCoord(const in vec2 texcoord, const in float mip, const in vec3 tanViewDir, const in float viewDist, out float texDepth, out vec3 traceDepth) {
    vec2 stepCoord = tanViewDir.xy * (ParallaxDepthF * MaterialParallaxOffset) / (1.0 + tanViewDir.z * MATERIAL_PARALLAX_SAMPLES);
    const float stepDepth = MaterialParallaxOffset / MATERIAL_PARALLAX_SAMPLES;

    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        vec2 atlasPixelSize = rcp(atlasSize);
        float prevTexDepth;
    #endif

    float viewDistF = 1.0 - saturate(viewDist / MATERIAL_DISPLACE_MAX_DIST);
    float maxSampleCount = viewDistF * MATERIAL_PARALLAX_SAMPLES + 0.5;

    vec2 localSize = atlasSize * vIn.atlasBounds[1];
    if (all(greaterThan(localSize, EPSILON2)))
        stepCoord.y *= localSize.x / localSize.y;

    float i;
    texDepth = 1.0;
    float depthDist = 1.0;
    for (i = 0.0; i < (MATERIAL_PARALLAX_SAMPLES+0.5); i += 1.0) {
        if (i > maxSampleCount || depthDist < (1.0/255.0)) break;

        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
            prevTexDepth = texDepth;
        #endif

        vec2 localTraceCoord = texcoord - i * stepCoord;

        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
            vec2 uv[4];
            vec2 atlasTileSize = vIn.atlasBounds[1] * atlasSize;
            vec2 f = GetLinearCoords(localTraceCoord, atlasTileSize, uv);

            uv[0] = GetAtlasCoord(uv[0], vIn.atlasBounds);
            uv[1] = GetAtlasCoord(uv[1], vIn.atlasBounds);
            uv[2] = GetAtlasCoord(uv[2], vIn.atlasBounds);
            uv[3] = GetAtlasCoord(uv[3], vIn.atlasBounds);

            texDepth = TextureLodLinear(normals, uv, mip, f, 3);
        #else
            vec2 traceAtlasCoord = GetAtlasCoord(localTraceCoord, vIn.atlasBounds);
            texDepth = textureLod(normals, traceAtlasCoord, mip).a;
        #endif

        depthDist = MaterialParallaxOffset - i * stepDepth - texDepth;
    }

    i = max(i - 1.0, 0.0);
    float pI = max(i - 1.0, 0.0);

    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        vec2 currentTraceOffset = texcoord - i * stepCoord;
        float currentTraceDepth = max(MaterialParallaxOffset - i * stepDepth, 0.0);
        vec2 prevTraceOffset = texcoord - pI * stepCoord;
        float prevTraceDepth = max(MaterialParallaxOffset - pI * stepDepth, 0.0);

        float t = (prevTraceDepth - prevTexDepth) / max(texDepth - prevTexDepth + prevTraceDepth - currentTraceDepth, EPSILON);
        t = clamp(t, 0.0, 1.0);

        traceDepth.xy = mix(prevTraceOffset, currentTraceOffset, t);
        traceDepth.z = mix(prevTraceDepth, currentTraceDepth, t);
    #else
        traceDepth.xy = texcoord - pI * stepCoord;
        traceDepth.z = max(MaterialParallaxOffset - pI * stepDepth, 0.0);
    #endif

    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        return GetAtlasCoord(traceDepth.xy, vIn.atlasBounds);
    #else
        return GetAtlasCoord(texcoord - i * stepCoord, vIn.atlasBounds);
    #endif
}

float GetParallaxShadow(const in vec3 traceTex, const in float mip, const in vec3 tanLightDir) {
    vec2 stepCoord = tanLightDir.xy * ParallaxDepthF * rcp(1.0 + tanLightDir.z * MATERIAL_PARALLAX_SHADOW_SAMPLES);
    const float stepDepth = rcp(MATERIAL_PARALLAX_SHADOW_SAMPLES);

    float skip = floor(traceTex.z * MATERIAL_PARALLAX_SHADOW_SAMPLES + 0.5) / MATERIAL_PARALLAX_SHADOW_SAMPLES;

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float shadow = 1.0;
    for (float i = 0.0; i < (MATERIAL_PARALLAX_SHADOW_SAMPLES+0.5); i += 1.0) {
        if (i + skip > (MATERIAL_PARALLAX_SHADOW_SAMPLES+0.5)) break;
        if (shadow < 0.001) break;

        float stepF = i + dither;
        float traceDepth = stepF * stepDepth + traceTex.z;
        vec2 localCoord = stepF * stepCoord + traceTex.xy;

        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH && defined MATERIAL_PARALLAX_SHADOW_SMOOTH
            vec2 uv[4];
            vec2 atlasTileSize = vIn.atlasBounds[1] * atlasSize;
            vec2 f = GetLinearCoords(localCoord, atlasTileSize, uv);

            uv[0] = GetAtlasCoord(uv[0], vIn.atlasBounds);
            uv[1] = GetAtlasCoord(uv[1], vIn.atlasBounds);
            uv[2] = GetAtlasCoord(uv[2], vIn.atlasBounds);
            uv[3] = GetAtlasCoord(uv[3], vIn.atlasBounds);

            float texDepth = TextureLodLinear(normals, uv, mip, f, 3);
        #else
            vec2 atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
            float texDepth = textureLod(normals, atlasCoord, mip).a;
        #endif

        #ifdef MATERIAL_PARALLAX_SOFTSHADOW
            float depthF = max(texDepth - traceDepth, 0.0) / stepDepth;
            shadow -= PARALLAX_SOFTSHADOW_FACTOR * depthF * stepDepth;
        #else
            shadow *= step(texDepth + EPSILON, traceDepth);
        #endif
    }

    return max(shadow, 0.0);
}

#if DISPLACE_MODE == DISPLACE_POM_SHARP
    vec3 GetParallaxSlopeNormal(const in vec2 atlasCoord, const in float mip, const in float traceDepth, const in vec3 tanViewDir) {
        vec2 atlasPixelSize = rcp(atlasSize);
        float atlasAspect = atlasSize.x / atlasSize.y;

        vec2 tex_snapped = floor(atlasCoord * atlasSize) * atlasPixelSize;
        vec2 tex_offset = atlasCoord - (0.5 * atlasPixelSize + tex_snapped);

        vec2 stepSign = sign(tex_offset);
        vec2 viewSign = sign(-tanViewDir.xy);

        bool dir = abs(tex_offset.x  * atlasAspect) < abs(tex_offset.y);
        vec2 tex_x, tex_y;

        if (dir) {
            tex_x = vec2(viewSign.x, 0.0);
            tex_y = vec2(0.0, stepSign.y);
        }
        else {
            tex_x = vec2(stepSign.x, 0.0);
            tex_y = vec2(0.0, viewSign.y);
        }

        vec2 tX = GetLocalCoord(atlasCoord + tex_x * atlasPixelSize, vIn.atlasBounds);
        tX = GetAtlasCoord(tX, vIn.atlasBounds);

        vec2 tY = GetLocalCoord(atlasCoord + tex_y * atlasPixelSize, vIn.atlasBounds);
        tY = GetAtlasCoord(tY, vIn.atlasBounds);

        float height_x = textureLod(normals, tX, mip).a;
        float height_y = textureLod(normals, tY, mip).a;
        vec3 signMask = vec3(0.0);

        if (dir) {
            if (!(traceDepth > height_y && -viewSign.y != stepSign.y)) {
                if (traceDepth > height_x)
                    signMask.x = 1.0;
                else if (abs(tanViewDir.y) > abs(tanViewDir.x))
                    signMask.y = 1.0;
                else
                    signMask.x = 1.0;
            }
            else {
                signMask.y = 1.0;
            }
        }
        else {
            if (!(traceDepth > height_x && -viewSign.x != stepSign.x)) {
                if (traceDepth > height_y)
                    signMask.y = 1.0;
                else if (abs(tanViewDir.y) > abs(tanViewDir.x))
                    signMask.y = 1.0;
                else
                    signMask.x = 1.0;
            }
            else {
                signMask.x = 1.0;
            }
        }

        return signMask * vec3(viewSign, 0.0);
    }
#endif
