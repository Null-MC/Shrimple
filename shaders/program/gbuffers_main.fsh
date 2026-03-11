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

    #ifdef MATERIAL_PBR_ENABLED
        flat uint localTangent;
        flat float localTangentW;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec3 tangentViewPos;
        flat uint atlasTilePos;
        flat uint atlasTileSize;
    #endif

//    #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
    #ifdef RENDER_TERRAIN
        flat int blockId;
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
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;
#endif

#if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
    uniform sampler2D texBlockLight;
#endif

uniform float far;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float rainStrength;
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
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform ivec2 eyeBrightnessSmooth;
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
#include "/lib/hash-noise.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water.glsl"
#include "/lib/ssao.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
    #include "/lib/fresnel.glsl"
    #include "/lib/material.glsl"
#endif

#ifdef MATERIAL_PARALLAX_ENABLED
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/sampling/linear.glsl"
    #include "/lib/parallax.glsl"
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

#ifdef LIGHTING_HAND
    #include "/lib/hand-light.glsl"
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

    #if defined(RENDER_TRANSLUCENT) && defined(DISTANT_HORIZONS)
        if (viewDist > dh_clipDistF * far) {
            discard;
            return;
        }
    #endif

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
            bounds.atlasTilePos = unpackUnorm2x16(vIn.atlasTilePos);
            bounds.atlasTileSize = unpackUnorm2x16(vIn.atlasTileSize);
            bounds.tanViewDir = tanViewDir;
            bounds.mip = mip;

            vec2 localCoord = GetLocalCoord(texcoord, bounds.atlasTilePos, bounds.atlasTileSize);
            texcoord = GetParallaxCoord(bounds, localCoord, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureLod(gtexture, texcoord, mip);

    #ifndef RENDER_SOLID
        if (color.a < alphaTestRef) discard;
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

        vec3 localTangent = OctDecode(unpackUnorm2x16(vIn.localTangent));
        mat3 matLocalTBN = BuildTBN(localGeoNormal, localTangent, vIn.localTangentW);
        vec3 localTexNormal = normalize(matLocalTBN * tex_normal);

        vec4 specularData = textureLod(specular, texcoord, mip);
        float sss = mat_sss(specularData.b);

        // TODO: DEBUG ONLY!
//        if (specularData.g >= 0.9) {
//            color.rgb = vec3(1.0);
//            specularData.rg = vec2(1.0);
//        }
    #else
        vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);
        vec3 localTexNormal = localGeoNormal;
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

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if (defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)) && defined(RENDER_TERRAIN)
        if (vIn.blockId == BLOCK_WATER) {
            // TODO: add option to make clear?
//            albedo = vec3(0.0);
            specularData = vec4(0.98, 0.02, 0.0, 0.0);
        }
    #endif

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    float shadow = 1.0;
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

        float shadowCoverageF = smoothstep(0.92, 0.98, length(shadowPos.xy));

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        shadowCoverageF *= float(saturate(shadowPos.z) == shadowPos.z);

        float shadow_NoL = dot(localTexNormal, localSkyLightDir);

//        if (saturate(shadowPos) == shadowPos) {
            shadow = SampleShadows(shadowPos);

            #ifdef MATERIAL_PBR_ENABLED
                shadow_NoL = mix(shadow_NoL, 1.0, sss);
            #endif
//        }
//        else {
//            shadow = pow5(vIn.lmcoord.y);
//        }
        shadow = mix(shadow, pow4(vIn.lmcoord.y), shadowCoverageF);

        shadow *= pow(saturate(shadow_NoL), 0.2);
    #endif

    #ifdef SHADOW_CLOUDS
        shadow *= SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    vec2 lmcoord = vIn.lmcoord;

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

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos) * 3.0;
            blockLight = mix(blockLight, lpvSample, lpvFade);
        #endif

        vec3 skyLight = vec3(0.0);
        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);
            float skyLight_NoLm = max(dot(localSkyLightDir, localTexNormal), 0.0);

            #ifdef MATERIAL_PBR_ENABLED
                skyLight_NoLm = mix(skyLight_NoLm, 1.0, 0.7*sss);
            #endif

            skyLight = skyLight_NoLm * shadow * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);
            #endif
        #endif

        color.rgb = albedo * (blockLight + skyLight + MinAmbientF);
    #else
        lmcoord.y = min(lmcoord.y, shadow * (1.0 - AmbientLightF) + AmbientLightF);

        float oldLighting = GetOldLighting(localTexNormal);
        #ifdef MATERIAL_PBR_ENABLED
            oldLighting = mix(oldLighting, 1.0, sss);
        #endif
        lmcoord.y *= oldLighting;

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        lmcoord = LightMapTex(lmcoord);
        vec3 lit = texture(lightmap, lmcoord).rgb;
        lit = RGBToLinear(lit);

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            lit += lpvFade * lpvSample;
        #endif

        color.rgb = albedo * lit;
    #endif

    #ifdef RENDER_TERRAIN
        float occlusion = _pow2(vIn.color.a);

//        #if defined(VOXY) || defined(DISTANT_HORIZONS)
//            occlusion = mix(occlusion, 1.0, SSAO_GetFade(viewDist));
//        #endif

        color.rgb *= occlusion;
    #endif

    // TODO: move to ambient lighting?
    color.rgb *= tex_occlusion;

    #if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        float handLight1 = max(heldBlockLightValue  - handDist, 0.0) / 15.0;
        float handLight2 = max(heldBlockLightValue2 - handDist, 0.0) / 15.0;

        vec3 handLightColor1 = vec3(1.0);
        if (heldItemId >= 0) {
            ivec2 blockLightUV1 = ivec2(heldItemId % 256, heldItemId / 256);
            vec4 lightColorRange1 = texelFetch(texBlockLight, blockLightUV1, 0);
            handLightColor1 = RGBToLinear(lightColorRange1.rgb);
        }

        vec3 handLightColor2 = vec3(1.0);
        if (heldItemId2 >= 0) {
            ivec2 blockLightUV2 = ivec2(heldItemId2 % 256, heldItemId2 / 256);
            vec4 lightColorRange2 = texelFetch(texBlockLight, blockLightUV2, 0);
            handLightColor2 = RGBToLinear(lightColorRange2.rgb);
        }

        vec3 lightDir = normalize(vIn.localPos - handLightPos);
        float NoLm = max(dot(localTexNormal, -lightDir), 0.0);

        if (heldBlockLightValue > 0 || heldBlockLightValue2 > 0) {
            color.rgb += albedo * NoLm * (_pow2(handLight1) * handLightColor1 + _pow2(handLight2) * handLightColor2);
        }
    #endif

    #ifdef LIGHTING_REFLECT_ENABLED
        #ifdef MATERIAL_PBR_ENABLED
            float smoothness = 1.0 - mat_roughness(specularData.r);
            float metalness = mat_metalness(specularData.g);
            float f0 = mat_f0(specularData.g);

            color.rgb *= 1.0 - metalness * sqrt(smoothness);
        #else
            float smoothness = 1.0 - mat_roughness_lab(specularData.r);
            float f0 = mat_f0_lab(specularData.g);
        #endif

        float NoV = dot(localTexNormal, -localViewDir);
        color.rgb *= 1.0 - F_schlick(NoV, f0, 1.0) * _pow2(smoothness);
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        float emission = mat_emission(specularData);
        TransformEmission(emission);
        color.rgb += albedo * emission;
    #endif


//    color.rgb = localTexNormal * 0.5 + 0.5;
//    color.rgb = vec3(lmcoord, 0);


    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        #ifdef RENDER_TRANSLUCENT
            color.a *= vIn.chunkFade;
        #else
            fogF = max(fogF, 1.0 - vIn.chunkFade);
        #endif
    #endif

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        if (isEyeInWater == 1) {
            color.rgb *= GetWaterAbsorption(viewDist);
        }
    #endif

    outFinal = color;

    #ifdef DEFERRED_NORMAL_ENABLED
        outGeoNormal = packUnorm2x16(OctEncode(localGeoNormal));

        vec3 viewTexNormal = mat3(gbufferModelView) * localTexNormal;
        outTexNormal = packUnorm2x16(OctEncode(viewTexNormal));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outReflectSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), vIn.lmcoord.y)),
            packUnorm4x8(specularData));
    #endif
}
