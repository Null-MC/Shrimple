vec2 GetParallaxCoord(const in vec2 texcoord, const in mat2 dFdXY, const in vec3 tanViewDir, const in float viewDist, out float texDepth, out vec3 traceDepth) {
    vec2 stepCoord = tanViewDir.xy * (ParallaxDepthF * MaterialTessellationOffset) / (1.0 + tanViewDir.z * MATERIAL_PARALLAX_SAMPLES);
    const float stepDepth = MaterialTessellationOffset / MATERIAL_PARALLAX_SAMPLES;

    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        vec2 atlasPixelSize = rcp(atlasSize);
        float prevTexDepth;
    #endif

    float viewDistF = 1.0 - saturate(viewDist / MATERIAL_DISPLACE_MAX_DIST);
    int maxSampleCount = int(viewDistF * MATERIAL_PARALLAX_SAMPLES);

    vec2 localSize = atlasSize * vIn.atlasBounds[1];
    if (all(greaterThan(localSize, EPSILON2)))
        stepCoord.y *= localSize.x / localSize.y;

    int i;
    texDepth = 1.0;
    float depthDist = 1.0;
    for (i = 0; i <= maxSampleCount && depthDist >= (1.0/255.0); i++) {
        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
            prevTexDepth = texDepth;
        #endif

        vec2 localTraceCoord = texcoord - i * stepCoord;

        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
            //vec2 traceAtlasCoord = GetAtlasCoord(localCoord - i * stepCoord, vIn.atlasBounds);
            //texDepth = TextureGradLinear(normals, traceAtlasCoord, atlasSize, dFdXY, 3);

            vec2 uv[4];
            vec2 atlasTileSize = vIn.atlasBounds[1] * atlasSize;
            vec2 f = GetLinearCoords(localTraceCoord, atlasTileSize, uv);

            uv[0] = GetAtlasCoord(uv[0], vIn.atlasBounds);
            uv[1] = GetAtlasCoord(uv[1], vIn.atlasBounds);
            uv[2] = GetAtlasCoord(uv[2], vIn.atlasBounds);
            uv[3] = GetAtlasCoord(uv[3], vIn.atlasBounds);

            texDepth = TextureGradLinear(normals, uv, dFdXY, f, 3);
        #else
            vec2 traceAtlasCoord = GetAtlasCoord(localTraceCoord, vIn.atlasBounds);
            texDepth = textureGrad(normals, traceAtlasCoord, dFdXY[0], dFdXY[1]).a;
            //texDepth = texture(normals, traceAtlasCoord).a;
        #endif

        depthDist = MaterialTessellationOffset - i * stepDepth - texDepth;
        //depthDist *= rcp(MaterialTessellationOffset);
        //if (texDepth >= 1.0 - i * stepDepth) break;
    }

    i = max(i - 1, 0);
    int pI = max(i - 1, 0);
    //traceDepth.xy = localCoord - pI * stepCoord;
    //traceDepth.z = 1.0 - pI * stepDepth;

    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        vec2 currentTraceOffset = texcoord - i * stepCoord;
        float currentTraceDepth = max(MaterialTessellationOffset - i * stepDepth, 0.0);
        vec2 prevTraceOffset = texcoord - pI * stepCoord;
        float prevTraceDepth = max(MaterialTessellationOffset - pI * stepDepth, 0.0);

        float t = (prevTraceDepth - prevTexDepth) / max(texDepth - prevTexDepth + prevTraceDepth - currentTraceDepth, EPSILON);
        t = clamp(t, 0.0, 1.0);

        traceDepth.xy = mix(prevTraceOffset, currentTraceOffset, t);
        traceDepth.z = mix(prevTraceDepth, currentTraceDepth, t);
    #else
        // shadow_tex.xy = prevTraceOffset;
        // shadow_tex.z = prevTraceDepth;
        traceDepth.xy = texcoord - pI * stepCoord;
        traceDepth.z = max(MaterialTessellationOffset - pI * stepDepth, 0.0);
    #endif

    //return GetAtlasCoord(localCoord - i * stepCoord);
    #if DISPLACE_MODE == DISPLACE_POM_SMOOTH
        //return i == 1 ? texcoord : GetAtlasCoord(traceDepth.xy);
        return GetAtlasCoord(traceDepth.xy, vIn.atlasBounds);
    #else
        return GetAtlasCoord(texcoord - i * stepCoord, vIn.atlasBounds);
    #endif
}

vec2 GetParallaxCoord(const in mat2 dFdXY, const in vec3 tanViewDir, const in float viewDist, out float texDepth, out vec3 traceDepth) {
    return GetParallaxCoord(vIn.localCoord, dFdXY, tanViewDir, viewDist, texDepth, traceDepth);
}

float GetParallaxShadow(const in vec3 traceTex, const in mat2 dFdXY, const in vec3 tanLightDir) {
    vec2 stepCoord = tanLightDir.xy * ParallaxDepthF * rcp(1.0 + tanLightDir.z * MATERIAL_PARALLAX_SHADOW_SAMPLES);
    const float stepDepth = rcp(MATERIAL_PARALLAX_SHADOW_SAMPLES);

    float skip = floor(traceTex.z * MATERIAL_PARALLAX_SHADOW_SAMPLES + 0.5) / MATERIAL_PARALLAX_SHADOW_SAMPLES;

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    int i;
    float shadow = 1.0;
    for (i = 0; i + skip < MATERIAL_PARALLAX_SHADOW_SAMPLES; i++) {
        if (shadow < 0.001) break;

        float stepF = i + dither;
        float traceDepth = traceTex.z + stepF * stepDepth;
        vec2 localCoord = traceTex.xy + stepF * stepCoord;

        #if DISPLACE_MODE == DISPLACE_POM_SMOOTH && defined MATERIAL_PARALLAX_SHADOW_SMOOTH
            vec2 uv[4];
            vec2 atlasTileSize = vIn.atlasBounds[1] * atlasSize;
            vec2 f = GetLinearCoords(localCoord, atlasTileSize, uv);

            uv[0] = GetAtlasCoord(uv[0], vIn.atlasBounds);
            uv[1] = GetAtlasCoord(uv[1], vIn.atlasBounds);
            uv[2] = GetAtlasCoord(uv[2], vIn.atlasBounds);
            uv[3] = GetAtlasCoord(uv[3], vIn.atlasBounds);

            float texDepth = TextureGradLinear(normals, uv, dFdXY, f, 3);
        #else
            vec2 atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
            float texDepth = textureGrad(normals, atlasCoord, dFdXY[0], dFdXY[1]).a;
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
    vec3 GetParallaxSlopeNormal(const in vec2 atlasCoord, const in mat2 dFdXY, const in float traceDepth, const in vec3 tanViewDir) {
        vec2 atlasPixelSize = 1.0 / atlasSize;
        float atlasAspect = atlasSize.x / atlasSize.y;

        vec2 tex_snapped = floor(atlasCoord * atlasSize) * atlasPixelSize;
        vec2 tex_offset = atlasCoord - (tex_snapped + 0.5 * atlasPixelSize);

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

        float height_x = textureGrad(normals, tX, dFdXY[0], dFdXY[1]).a;
        float height_y = textureGrad(normals, tY, dFdXY[0], dFdXY[1]).a;

        if (dir) {
            if (!(traceDepth > height_y && -viewSign.y != stepSign.y)) {
                if (traceDepth > height_x) return vec3(viewSign.x, 0.0, 0.0);

                if (abs(tanViewDir.y) > abs(tanViewDir.x))
                    return vec3(0.0, viewSign.y, 0.0);
                else
                    return vec3(viewSign.x, 0.0, 0.0);
            }

            return vec3(0.0, viewSign.y, 0.0);
        }
        else {
            if (!(traceDepth > height_x && -viewSign.x != stepSign.x)) {
                if (traceDepth > height_y) return vec3(0.0, viewSign.y, 0.0);

                if (abs(tanViewDir.y) > abs(tanViewDir.x))
                    return vec3(0.0, viewSign.y, 0.0);
                else
                    return vec3(viewSign.x, 0.0, 0.0);
            }

            return vec3(viewSign.x, 0.0, 0.0);
        }
    }
#endif
