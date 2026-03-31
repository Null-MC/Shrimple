#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;

    #ifdef RENDER_ENTITY
        vec3 localNormal;
    #else
        flat uint localNormal;
    #endif

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        flat float chunkFade;
    #endif

    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
        float waveHeight;
    #endif

    #if defined(MATERIAL_PBR_ENABLED) || defined(WATER_WAVE_ENABLED)
        flat uint localTangent;
        flat float localTangentW;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec3 tangentViewPos;
        flat uint atlasTilePos;
        flat uint atlasTileSize;
    #endif

//    #if defined(MATERIAL_PBR_ENABLED) || defined(REFLECT_ENABLED)
    #ifdef RENDER_TERRAIN
        flat int blockId;
    #endif

    #if defined(VELOCITY_ENABLED) && defined(RENDER_TERRAIN)
        vec3 velocity;
    #endif
} vIn;


uniform sampler2D gtexture;

#ifdef MATERIAL_PBR_ENABLED
    uniform sampler2D normals;
    uniform sampler2D specular;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef SHADOWS_ENABLED
    uniform SHADOW_SAMPLER TEX_SHADOW;

    #ifdef SHADOW_COLORED
        uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;

    #if defined(LIGHTING_HAND) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        uniform sampler2D texBlockLight;
    #endif
#endif

uniform float far;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherWetness;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec4 entityColor;
uniform int entityId;
uniform float alphaTestRef;
uniform vec3 sunLocalDir;
//uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform int isEyeInWater;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform ivec2 atlasSize;
uniform vec2 viewSize;

uniform int textureFilteringMode;
uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/oklab.glsl"
#include "/lib/hsv.glsl"
#include "/lib/fog.glsl"
#include "/lib/tbn.glsl"
#include "/lib/ign.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/sampling/linear.glsl"
#include "/lib/hash-noise.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water-absorb.glsl"
#include "/lib/lighting/attenuation.glsl"
#include "/lib/ssao.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"

    #ifdef MATERIAL_PBR_ENABLED
        #include "/lib/material/lazanyi.glsl"
    #endif
#endif

#ifdef MATERIAL_PARALLAX_ENABLED
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
    #include "/lib/water-waves.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

#ifdef LIGHTING_SPECULAR
    #include "/lib/lighting/specular.glsl"
#endif

#if defined(LIGHTING_HAND) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
    #ifdef LIGHTING_COLORED
        #include "/lib/sampling/block-light.glsl"
    #endif

    #include "/lib/lighting/hand.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void main() {
    float viewDist = length(vIn.localPos);

//    #ifdef DISTANT_HORIZONS
//        if (viewDist > dh_clipDistF * far) {discard;}
//    #endif

    vec2 texcoord = vIn.texcoord;
	float mip = textureQueryLod(gtexture, texcoord).y;
    vec3 localViewDir = vIn.localPos / viewDist;

    #ifdef RENDER_ENTITY
        vec3 localGeoNormal = normalize(vIn.localNormal);
    #else
        vec3 localGeoNormal = OctDecode(unpackUnorm2x16(vIn.localNormal));
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        bool skipParallax = false;

        #ifdef RENDER_TERRAIN
            if (vIn.blockId == BLOCK_LAVA || vIn.blockId == BLOCK_WATER || vIn.blockId == BLOCK_END_PORTAL) skipParallax = true;
        #elif defined(RENDER_ENTITY)
            if (entityId == ENTITY_SHADOW) skipParallax = true;
        #endif

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(vIn.tangentViewPos);

        ParallaxBounds bounds;
        if (!skipParallax && viewDist < MATERIAL_PARALLAX_MAX_DIST) {
            bounds.atlasTilePos = unpackHalf2x16(vIn.atlasTilePos);
            bounds.atlasTileSize = unpackHalf2x16(vIn.atlasTileSize);
            bounds.tanViewDir = tanViewDir;
            bounds.mip = mip;

            vec2 localCoord = GetLocalCoord(texcoord, bounds.atlasTilePos, bounds.atlasTileSize);
            texcoord = GetParallaxCoord(bounds, localCoord, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureLod(gtexture, texcoord, mip);
    vec2 lmcoord = vIn.lmcoord;

    #ifdef RENDER_COLORWHEEL
        float ao;
        vec4 overlayColor;
        clrwl_computeFragment(color, color, lmcoord, ao, overlayColor);
        color.rgb = mix(color.rgb, overlayColor.rgb, overlayColor.a);
    #else
        #ifndef RENDER_SOLID
            if (color.a < alphaTestRef) discard;
        #endif
    #endif

    #if defined(RENDER_TERRAIN) && LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        color.rgb *= vIn.color.rgb;
    #else
        color *= vIn.color;
    #endif

    #ifdef RENDER_ENTITY
        color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

        if (entityId == BLOCK_PHYMOD_SNOW) {
            vec3 pixelPos = floor((vIn.localPos + cameraPosition) * 16.0) / 16.0;
            float noise = hash33(pixelPos).x;
            color.rgb *= noise * 0.06 + 0.94;
        }
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 normalData = textureLod(normals, texcoord, mip);
        vec3 tex_normal = mat_normal(normalData.xyz);
        float tex_occlusion = mat_occlusion(normalData.w);

        #if defined(MATERIAL_PARALLAX_ENABLED) && MATERIAL_PARALLAX_TYPE == PARALLAX_SHARP
            float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

            if (depthDiff >= ParallaxSharpThreshold) {
                tex_normal = GetParallaxSlopeNormal(bounds, texcoord, traceCoordDepth.z);
            }
        #endif
    #else
        vec3 tex_normal = vec3(0.0, 0.0, 1.0);
    #endif

    #if defined(MATERIAL_PBR_ENABLED) || (defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT))
        vec3 localTangent = OctDecode(unpackUnorm2x16(vIn.localTangent));
        mat3 matLocalTBN = BuildTBN(localGeoNormal, localTangent, vIn.localTangentW);
        vec3 localTexNormal = normalize(matLocalTBN * tex_normal);
    #else
        vec3 localTexNormal = localGeoNormal;
    #endif

    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
        if (vIn.blockId == BLOCK_WATER) {
            vec2 waterWorldPos = (vIn.localPos.xz + cameraPosition.xz);
            float waveHeight = wave_fbm(waterWorldPos / WaterNormalScale, 12);
            vec3 wavePos = vec3(vIn.localPos.xz, waveHeight);
            wavePos.z += vIn.localPos.y - vIn.waveHeight;

            vec3 dX = dFdx(wavePos);
            vec3 dY = dFdy(wavePos);
            localTexNormal = normalize(cross(normalize(dY), normalize(dX))).xzy;// * sign(localGeoNormal.y);
        }
    #endif

    #ifdef DISTANT_HORIZONS
        if (viewDist > dh_clipDistF * far) {discard;}
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 specularData = textureLod(specular, texcoord, mip);
        float sss = mat_sss(specularData.b);

        // TODO: DEBUG ONLY!
//        if (specularData.g >= 0.9) {
//            color.rgb = vec3(1.0);
//            specularData.rg = vec2(1.0);
//        }
    #else
        vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);
//        vec3 localTexNormal = localGeoNormal;
        const float tex_occlusion = 1.0;
        const float sss = 0.0;

        // TODO: if vanilla lighting, make foliage have "up" normals
//        #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
        #ifdef RENDER_TERRAIN
            bool isGrass = vIn.blockId == BLOCK_GRASS_SHORT
                || vIn.blockId == BLOCK_TALL_GRASS_LOWER
                || vIn.blockId == BLOCK_TALL_GRASS_UPPER;

            if (isGrass) localTexNormal = vec3(0,1,0);
        #endif
    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    #ifdef RENDER_TERRAIN
        if (vIn.blockId == BLOCK_WATER) {
            #ifndef WATER_TEXTURE_ENABLED
                albedo = vec3(0.0);//RGBToLinear(vIn.color.rgb);
                color.a = 0.02;
            #endif

            specularData = vec4(0.98, 0.02, 0.0, 0.0);
        }
    #endif

    #if defined(MATERIAL_PBR_ENABLED) && defined(WORLD_OVERWORLD)
        float skyExposure = smoothstep((13.5/15.0), (14.5/15.0), vIn.lmcoord.y);
        float wetness = weatherWetness * skyExposure * saturate(unmix(-0.4, 0.1, localTexNormal.y));
        float porosity = mat_porosity(specularData.rgb);
        float surfaceWetness = wetness * porosity;

        if (surfaceWetness > 0.0) {
            albedo *= exp(-3.0 * surfaceWetness * (1.0 - albedo));
            specularData.r = mix(specularData.r, 1.0, surfaceWetness);
        }
    #endif

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    float cloudShadowF = 1.0;
    #ifdef SHADOW_CLOUDS
        cloudShadowF = SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        vec3 shadow = vec3(1.0);
    #else
        float shadowF = 1.0;
    #endif

    #ifdef SHADOWS_ENABLED
        vec3 shadowViewGeoNormal = mat3(shadowModelView) * localGeoNormal;

        vec3 shadowPos = vIn.localPos;
        shadowPos += 0.08 * localGeoNormal;
        shadowPos = mul3(shadowModelView, shadowPos);
//        shadowPos.z += 0.20 * shadowViewGeoNormal.z;
//        shadowPos.z += 0.032 * viewDist;

        #ifdef MATERIAL_PBR_ENABLED
            shadowPos.z += sss;
        #endif

        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        float shadowLength = length(shadowPos.xy);
        float shadowCoverageF = smoothstep(0.98, 0.92, shadowLength);
//        shadowCoverageF *= float(saturate(shadowPos.z) == shadowPos.z);
        shadowCoverageF *= smoothstep(0.98, 0.92, abs(shadowPos.z));
        shadowCoverageF = 1.0 - shadowCoverageF;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        // TODO: this needs to move somewhere else and apply to diffuse only
//        float shadow_geoNoL = dot(localGeoNormal, localSkyLightDir);
//        #ifdef MATERIAL_PBR_ENABLED
//            shadow_geoNoL = mix(shadow_geoNoL, 1.0, sss);
//            shadow_geoNoL = pow(saturate(shadow_geoNoL), 0.2);
//        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            shadow = SampleShadowColor(shadowPos);
            shadow = mix(shadow, vec3(pow4(vIn.lmcoord.y)), shadowCoverageF);
            shadow *= cloudShadowF; // * shadow_geoNoL
        #else
            shadowF = SampleShadow(shadowPos);
            shadowF = mix(shadowF, pow4(vIn.lmcoord.y), shadowCoverageF);
            shadowF *= cloudShadowF; // * shadow_geoNoL
        #endif
    #endif

    #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
        lmcoord.x = 0.0;
    #endif

    #ifndef PHOTONICS_HAND_LIGHT_ENABLED
        #ifdef LIGHTING_HAND
            vec3 handLightPos = GetHandLightPosition();
            float handDist = distance(vIn.localPos, handLightPos);
        #endif

        #if defined(LIGHTING_HAND) && !defined(LIGHTING_COLORED)
            float handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
            float handLight = max(handLightLevel - handDist, 0.0) / 15.0;

            lmcoord.x = max(lmcoord.x, handLight);
        #endif
    #endif

    #ifdef LIGHTING_COLORED
        vec3 voxelPos = GetVoxelPosition(vIn.localPos);
        float lpvFade = GetVoxelFade(voxelPos);
    #endif

    #ifdef LIGHTING_SPECULAR
        #ifdef MATERIAL_PBR_ENABLED
            float roughness = mat_roughness(specularData.r);
            float metalness = mat_metalness(specularData.g);

//            LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
//            vec3 F = F_lazanyi(NoV, lF.f0, lF.f82);
        #else
            float roughness = mat_roughness_lab(specularData.r);
            float metalness = mat_metalness_lab(specularData.g);

//            float f0 = mat_f0_lab(specularData.g);
//            float F = F_schlick(NoV, f0, 1.0);
        #endif

        float roughL = _pow2(roughness);
    #endif

    vec3 diffuseFinal = vec3(0.0);
    vec3 specularFinal = vec3(0.0);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        shadow *= smoothstep((2.5/16.0), (13.5/16.0), lmcoord.y);

        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localGeoNormal, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos);
            blockLight = mix(blockLight, lpvSample, lpvFade);
        #endif

        diffuseFinal = blockLight + MinAmbientF;

        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = shadow * GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);

            float skyLight_NoLm = dot(localSkyLightDir, localTexNormal);
            #ifdef MATERIAL_PBR_ENABLED
                skyLight_NoLm = (skyLight_NoLm + sss) / (1.0 + sss);
            #endif

            skyLight_NoLm = max(skyLight_NoLm, 0.0);
            vec3 skyLight = skyLight_NoLm * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);
            #endif

            diffuseFinal += skyLight;

            #ifdef LIGHTING_SPECULAR
                if (skyLight_NoLm > 0.0 && dot(localGeoNormal, localSkyLightDir) > 0.0) {
                    vec3 skySpecularLightDir = GetAreaLightDir(localTexNormal, localViewDir, localSkyLightDir, 100.0, 8.0);
                    skySpecularLightDir = normalize(skySpecularLightDir + 0.1*localSkyLightDir);

                    specularFinal += SampleLightSpecular(albedo, localTexNormal, skySpecularLightDir, -localViewDir, skyLight_NoLm, roughL, specularData.g) * skyLightColor;
                }

                // apply metal tint
                specularFinal *= mix(vec3(1.0), albedo, metalness);
            #endif
        #endif
    #else
        #if defined(PHOTONICS_GI_ENABLED) && !defined(RENDER_TRANSLUCENT)
            #ifdef SHADOWS_ENABLED
                lmcoord.y = shadowF;
            #else
                lmcoord.y = _pow3(lmcoord.y);
            #endif
        #endif

        lmcoord.y = min(lmcoord.y, shadowF * (1.0 - AmbientLightF) + AmbientLightF);

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        lmcoord = LightMapTex(lmcoord);
        diffuseFinal = texture(lightmap, lmcoord).rgb;
        float oldLighting = GetOldLighting(localTexNormal);
        #ifdef MATERIAL_PBR_ENABLED
            oldLighting = mix(oldLighting, 1.0, sss);
        #endif
        diffuseFinal *= oldLighting;
        diffuseFinal = RGBToLinear(diffuseFinal);

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            diffuseFinal += lpvFade * lpvSample;
        #endif
    #endif

    #ifdef RENDER_TERRAIN
        float occlusion = _pow2(vIn.color.a);

//        #if defined(VOXY) || defined(DISTANT_HORIZONS)
//            occlusion = mix(occlusion, 1.0, SSAO_GetFade(viewDist));
//        #endif

//        albedo *= occlusion;// * 0.5 + 0.5;

        diffuseFinal *= occlusion;
    #endif

    // TODO: move to ambient lighting?
    diffuseFinal *= tex_occlusion;

    #if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        if (heldItemId >= 0) {
            vec3 lightColor;
            float lightRange;
            GetBlockColorRange(heldItemId, lightColor, lightRange);

            const float lightRadius = 0.5;
            float att = GetLightAttenuation(handDist, lightRange, lightRadius);
            vec3 handLightDir = normalize(handLightPos - vIn.localPos);
            float hand_NoLm = max(dot(localTexNormal, handLightDir), 0.0);

            diffuseFinal += att * hand_NoLm * lightColor;
            #ifdef LIGHTING_SPECULAR
                specularFinal += att * SampleLightSpecular(albedo, localTexNormal, handLightDir, -localViewDir, hand_NoLm, roughL, specularData.g) * lightColor;
            #endif
        }

        if (heldItemId2 >= 0) {
            vec3 lightColor;
            float lightRange;
            GetBlockColorRange(heldItemId2, lightColor, lightRange);

            const float lightRadius = 0.5;
            float att = GetLightAttenuation(handDist, lightRange, lightRadius);
            vec3 handLightDir = normalize(handLightPos - vIn.localPos);
            float hand_NoLm = max(dot(localTexNormal, handLightDir), 0.0);

            diffuseFinal += att * hand_NoLm * lightColor;
            #ifdef LIGHTING_SPECULAR
                specularFinal += att * SampleLightSpecular(albedo, localTexNormal, handLightDir, -localViewDir, hand_NoLm, roughL, specularData.g) * lightColor;
            #endif
        }
    #endif

    #ifdef LIGHTING_SPECULAR
        float NoV = dot(localTexNormal, -localViewDir);

        float smoothness = 1.0 - roughness;
        #ifdef MATERIAL_PBR_ENABLED
            LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
            vec3 F = F_lazanyi(NoV, lF.f0, lF.f82);

            diffuseFinal *= 1.0 - metalness * sqrt(smoothness);
            color.a = max(color.a, maxOf(F));
        #else
            float f0 = mat_f0_lab(specularData.g);
            float F = F_schlick(NoV, f0, 1.0);

            color.a = max(color.a, F);
        #endif

        diffuseFinal *= 1.0 - F * _pow2(smoothness);

        #if !(defined(SSR_ENABLED) || defined(PHOTONICS_REFLECT_ENABLED))
            // TODO: reflect in view space to avoid view-bob
//            vec3 reflectViewDir = normalize(reflect(viewDir, texViewNormal));
            vec3 reflectLocalDir = normalize(reflect(localViewDir, localTexNormal));

//            vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
            vec3 reflectColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), reflectLocalDir);
//            reflectColor *= _pow3(lmcoord.y);
            reflectColor *= lmcoord.y;

            // apply metal tint
            reflectColor *= mix(vec3(1.0), albedo, metalness);

            specularFinal += F * _pow2(smoothness) * reflectColor;
        #endif
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        float emission = mat_emission(specularData);
        TransformEmission(emission);
        diffuseFinal += emission;
    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        #ifdef RENDER_TRANSLUCENT
            color.a *= vIn.chunkFade;
        #endif
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        color.rgb = albedo/PI * diffuseFinal * color.a + specularFinal;
    #else
        color.rgb = albedo * diffuseFinal * color.a + specularFinal;
    #endif

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        #ifndef RENDER_TRANSLUCENT
            fogF = max(fogF, 1.0 - vIn.chunkFade);
        #endif
    #endif

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);
    color.a = max(color.a, fogF);

//    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
//        if (isEyeInWater == 1) {
//            color.rgb *= GetWaterAbsorption(viewDist);
//        }
//    #endif

//    color.rgb = localTexNormal * 0.5 + 0.5;
//    color.a = 1.0;
//    #ifdef RENDER_TRANSLUCENT
//        color.rgb = 0.5 * (color.rgb + vec3(1,0,0));
//    #else
//        color.rgb = 0.5 * (color.rgb + vec3(0,0,1));
//    #endif

    outFinal = color;

    outMeta = 0u;
    #ifdef RENDER_HAND
        outMeta = 1u;
    #endif

    #if defined(VELOCITY_ENABLED)
        #if defined(RENDER_TERRAIN)
            outVelocity = vIn.velocity;
        #else
            outVelocity = vec3(0.0);
        #endif
    #endif

    #ifdef RENDER_TRANSLUCENT
        vec3 tint = vec3(1.0);
        uint matID = 0;

        #ifdef RENDER_TERRAIN
            int blockId = vIn.blockId;
        #else
            int blockId = currentRenderedItemId;
        #endif

        #ifdef RENDER_TERRAIN
            if (blockId == BLOCK_WATER) {
                matID = MAT_WATER;
                tint = vIn.color.rgb * 0.6;
            }
        #endif

        #if defined(RENDER_TERRAIN) || defined(RENDER_HAND)
            if (blockId >= BLOCK_STAINED_GLASS_BLACK && blockId <= BLOCK_TINTED_GLASS) {
                matID = MAT_STAINED_GLASS;
                tint = LinearToRGB(normalize(albedo) * color.a);
            }
        #endif

        outTint = vec4(tint, (matID + 0.5) / 255.0);
    #endif

    #ifdef DEFERRED_NORMAL_ENABLED
        vec3 viewTexNormal = mat3(gbufferModelView) * localTexNormal;
        outNormal = vec4(OctEncode(localGeoNormal), OctEncode(viewTexNormal));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outAlbedoSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), vIn.lmcoord.y)),
            packUnorm4x8(specularData));
    #endif
}
