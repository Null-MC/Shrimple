#ifdef RENDER_VERTEX
    void PrepareNormalMap() {
        vec3 viewTangent = gl_NormalMatrix * at_tangent.xyz;
        vOut.localTangent.xyz = mat3(gbufferModelViewInverse) * viewTangent;
        vOut.localTangent.w = at_tangent.w;
    }
#endif

#ifdef RENDER_FRAG
    vec3 GenerateNormal(const in vec2 texcoord, const in float mip) {
        #ifdef RENDER_ENTITIES
            vec2 texSize = textureSize(gtexture, 0);
        #else
            vec2 texSize = atlasSize;
        #endif

        vec2 tileSize = vIn.atlasBounds[1] * texSize * MATERIAL_NORMAL_SCALE;
        vec2 tilePixelSize = rcp(tileSize);

        #ifdef PARALLAX_ENABLED
            vec2 texcoordSnapped = GetLocalCoord(texcoord, vIn.atlasBounds);
        #else
            vec2 texcoordSnapped = vIn.localCoord;
        #endif

        texcoordSnapped = floor(texcoordSnapped * tileSize) / tileSize;

        vec2 texcoordX1 = GetAtlasCoord(texcoordSnapped - vec2(tilePixelSize.x, 0.0), vIn.atlasBounds);
        vec2 texcoordX2 = GetAtlasCoord(texcoordSnapped + vec2(tilePixelSize.x, 0.0), vIn.atlasBounds);
        vec2 texcoordY1 = GetAtlasCoord(texcoordSnapped - vec2(0.0, tilePixelSize.y), vIn.atlasBounds);
        vec2 texcoordY2 = GetAtlasCoord(texcoordSnapped + vec2(0.0, tilePixelSize.y), vIn.atlasBounds);

        vec4 texColorX1 = textureLod(gtexture, texcoordX1, mip);
        vec4 texColorX2 = textureLod(gtexture, texcoordX2, mip);
        vec4 texColorY1 = textureLod(gtexture, texcoordY1, mip);
        vec4 texColorY2 = textureLod(gtexture, texcoordY2, mip);

        float texHeightX1 = luminance(RGBToLinear(texColorX1.rgb) * texColorX1.a);
        float texHeightX2 = luminance(RGBToLinear(texColorX2.rgb) * texColorX2.a);
        float texHeightY1 = luminance(RGBToLinear(texColorY1.rgb) * texColorY1.a);
        float texHeightY2 = luminance(RGBToLinear(texColorY2.rgb) * texColorY2.a);

        #if MATERIAL_NORMAL_EDGE != 0
            vec2 texcoordC = GetAtlasCoord(texcoordSnapped, vIn.atlasBounds);
            vec4 texColorC = textureLod(gtexture, texcoordC, mip);
            float texHeightC = luminance(RGBToLinear(texColorC.rgb) * texColorC.a);

            #if MATERIAL_NORMAL_EDGE == 1
                texHeightX1 = max(texHeightC, texHeightX1);
                texHeightX2 = max(texHeightC, texHeightX2);
                texHeightY1 = max(texHeightC, texHeightY1);
                texHeightY2 = max(texHeightC, texHeightY2);
            #else
                texHeightX1 = min(texHeightC, texHeightX1);
                texHeightX2 = min(texHeightC, texHeightX2);
                texHeightY1 = min(texHeightC, texHeightY1);
                texHeightY2 = min(texHeightC, texHeightY2);
            #endif
        #endif

        float dX = texHeightX2 - texHeightX1;
        float dY = texHeightY2 - texHeightY1;

        vec3 aX = vec3(1.0, 0.0, dX * MaterialNormalStrengthF);
        vec3 aY = vec3(0.0, 1.0, dY * MaterialNormalStrengthF);

        return normalize(cross(aX, aY));
    }

    vec3 GenerateRoundNormal() {
        vec2 roundTex = vIn.localCoord * 2.0 - 1.0;

        vec2 edgeTex = abs(roundTex) - (1.0 - MaterialNormalRoundF);
        roundTex = max(edgeTex * rcp(MaterialNormalRoundF), 0.0) * sign(roundTex);

        return normalize(vec3(roundTex, 1.0));
    }

    bool GetMaterialNormal(const in vec2 texcoord, const in float mip, inout vec3 normal) {
        bool valid = false;
        #if MATERIAL_NORMALS == NORMALMAP_LABPBR
            vec2 texNormalLab = textureLod(normals, texcoord, mip).rg;

            if (any(greaterThan(texNormalLab.rg, EPSILON2))) {
                normal.xy = texNormalLab.xy * 2.0 - (254.0/255.0);
                normal.z = sqrt(max(1.0 - dot(normal.xy, normal.xy), 0.0));
                valid = true;
            }
        #elif MATERIAL_NORMALS == NORMALMAP_OLDPBR
            vec3 texNormalOld = textureLod(normals, texcoord, mip).rgb;

            if (any(greaterThan(texNormalOld, EPSILON3))) {
                normal = normalize(texNormalOld * 2.0 - (254.0/255.0));
                valid = true;
            }
        #elif MATERIAL_NORMALS == NORMALMAP_GENERATED
            #if defined RENDER_ENTITIES && MATERIAL_NORMAL_ROUND > 0
                normal = GenerateRoundNormal();
            #else
                normal = GenerateNormal(texcoord, mip);
            #endif
            valid = true;
        #endif

        return valid;
    }
#endif
