#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_opaque
    #define MAT_PROJ_INV matProjInv
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_INV gbufferProjectionInverse
#endif

in vec2 texcoord;


#ifdef LOD_ENABLED
    uniform sampler2D texDepthLod_opaque;
#endif

uniform sampler2D depthtex0;
uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_GB_COLOR;
uniform sampler2D TEX_GB_NORMALS;
uniform usampler2D TEX_GB_SPECULAR;

#if defined(PHOTONICS_BLOCK_LIGHT_ENABLED) || defined(PHOTONICS_GI_ENABLED)
    uniform sampler2D texPhotonicsIndirect;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        uniform sampler2D texSkyTransmit;
        uniform sampler3D texSkyIrradiance;
    #endif
#else
    uniform sampler2D texLightmap;
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
    uniform sampler3D texFloodFill;

    #if defined(LIGHTING_HAND) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        uniform sampler2D texBlockLight;
    #endif
#endif

#ifdef SSAO_ENABLED
    uniform sampler2D TEX_SSAO;
#endif

uniform float far;
uniform float near;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 sunLocalDir;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float weatherWetness;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec3 eyePosition;
uniform int hasSkylight;
uniform int isEyeInWater;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int frameCounter;
uniform vec2 viewSize;
uniform vec2 taa_offset = vec2(0.0);

uniform float dhFarPlane;
uniform int vxRenderDistance;

#include "/lib/ign.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/shadows.glsl"
#include "/lib/hash-noise.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/sampling/linear.glsl"
#include "/lib/lighting/attenuation.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"

    #ifdef MATERIAL_PBR_ENABLED
        #include "/lib/material/lazanyi.glsl"
    #endif
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
    #if LIGHTING_RESOLUTION > 0
        #include "/lib/shadow-sample-pixelated.glsl"
    #else
        #include "/lib/shadow-sample.glsl"
    #endif
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif

#ifdef PHOTONICS_LIGHT_ENABLED
    #include "/photonics/photonics.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    outFinal = texelFetch(TEX_FINAL, uv, 0).rgb;
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    vec4 src = texelFetch(TEX_GB_COLOR, uv, 0);

    #ifdef LOD_ENABLED
        bool isSky = depth <= 0.0;
    #else
        bool isSky = depth >= 1.0;
    #endif

    if (src.a > 0.0 && !isSky) {
//        float depth = texelFetch(TEX_DEPTH, uv, 0).r;
//        vec4 color = texelFetch(TEX_GB_COLOR, uv, 0);
        vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);
        uvec2 specularMetaData = texelFetch(TEX_GB_SPECULAR, uv, 0).rg;

        vec3 albedo = RGBToLinear(src.rgb);
        vec3 localGeoNormal = OctDecode(normalData.xy);
        vec3 viewTexNormal = OctDecode(normalData.zw);
        vec4 specularData = unpackUnorm4x8(specularMetaData.r);
        vec4 meta = unpackUnorm4x8(specularMetaData.g);

        vec2 lmcoord = meta.xy;
        float occlusion = meta.z;

        #ifdef MATERIAL_PBR_ENABLED
            float tex_sss = mat_sss(specularData.b);
            float porosity = mat_porosity(specularData.rgb);
        #else
            const float tex_sss = 0.0;
            const float porosity = 0.8;
        #endif

        #ifdef LOD_ENABLED
            mat4 matProjInv = mat4(
                gbufferProjectionInverse[0][0], 0.0, 0.0, 0.0,
                0.0, gbufferProjectionInverse[1][1], 0.0, 0.0,
                0.0, 0.0, 0.0, 1.0/near,
                0.0, 0.0, -1.0, 0.0);
        #endif

        vec3 screenPos = vec3(texcoord, depth);
        #ifdef TAA_ENABLED
            screenPos.xy -= taa_offset;
        #endif
        vec3 ndcPos = screenToNdc(screenPos);
        vec3 viewPos = project(MAT_PROJ_INV, ndcPos);

        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        #if LIGHTING_RESOLUTION > 0
            vec3 snapOffset = fract(cameraPosition);

            localPos = (localPos + snapOffset) * LIGHTING_RESOLUTION;
            localPos += 0.99*localGeoNormal;
            localPos = floor(localPos) + 0.5;
            localPos = localPos / LIGHTING_RESOLUTION - snapOffset;
        #endif

        float viewDist = length(localPos);
        vec3 localViewDir = localPos / viewDist;
        vec3 localTexNormal = mat3(gbufferModelViewInverse) * viewTexNormal;

        #ifdef VOXEL_ENABLED
            vec3 voxelPos = GetVoxelPosition(localPos);
            vec3 lpvSamplePos = GetFloodFillSamplePos(voxelPos, localGeoNormal, localTexNormal);
        #endif

        #if defined(MATERIAL_WETNESS) && defined(WORLD_OVERWORLD)
            float skyExposure = smoothstep((13.5/15.0), (14.5/15.0), lmcoord.y);
            #ifdef VOXEL_ENABLED
                if (IsInVoxelBounds(lpvSamplePos))
                    skyExposure *= SampleFloodFill_SkyExposure(lpvSamplePos);
            #endif

            float wetness = weatherWetness * skyExposure * saturate(unmix(-0.4, 0.1, localTexNormal.y));
//            float porosity = mat_porosity(specularData.rgb);
            float surfaceWetness = wetness * porosity;

            if (surfaceWetness > 0.0) {
                albedo *= exp(-3.0 * surfaceWetness * (1.0 - albedo));
                specularData.r = mix(specularData.r, 1.0, 0.86*surfaceWetness);
            }
        #endif

        vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

        float cloudShadowF = 1.0;
        #ifdef SHADOW_CLOUDS
            cloudShadowF = SampleCloudShadow(localPos, localSkyLightDir);
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            vec3 shadow = vec3(1.0);
        #else
            float shadowF = 1.0;
        #endif

        #ifdef SHADOWS_ENABLED
            vec3 shadowPos = localPos;
            shadowPos += 0.08 * localGeoNormal;

            #if LIGHTING_RESOLUTION > 0
                #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                    shadow = SampleShadowColor(shadowPos, localGeoNormal);
                #else
                    shadowF = SampleShadow(shadowPos, localGeoNormal);
                #endif
            #else
//                vec3 shadowViewGeoNormal = mat3(shadowModelView) * localGeoNormal;

//                vec3 shadowPos = localPos;
//                shadowPos += 0.08 * localGeoNormal;
                vec3 shadowViewPos = mul3(shadowModelView, shadowPos);
                //        shadowPos.z += 0.20 * shadowViewGeoNormal.z;
                //        shadowPos.z += 0.032 * viewDist;
                vec3 shadowViewNormal = mat3(shadowModelView) * localGeoNormal;
                vec2 shadowScreenPos = (shadowProjection * vec4(shadowViewPos, 1.0)).xy;
                shadowViewPos.z += GetShadowBiasF(shadowScreenPos, shadowViewNormal.z);

                #ifdef MATERIAL_PBR_ENABLED
                    shadowViewPos.z += tex_sss;
                #endif

                shadowPos = (shadowProjection * vec4(shadowViewPos, 1.0)).xyz;

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
                //            shadow_geoNoL = mix(shadow_geoNoL, 1.0, tex_sss);
                //            shadow_geoNoL = pow(saturate(shadow_geoNoL), 0.2);
                //        #endif

                #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                    shadow = SampleShadowColor(shadowPos);
                    shadow = mix(shadow, vec3(pow4(lmcoord.y)), shadowCoverageF);
                #else
                    shadowF = SampleShadow(shadowPos);
                    shadowF = mix(shadowF, pow4(lmcoord.y), shadowCoverageF);
                #endif
            #endif

            #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                shadow *= cloudShadowF; // * shadow_geoNoL
            #else
                shadowF *= cloudShadowF; // * shadow_geoNoL
            #endif
        #endif

        #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
            lmcoord.x = 0.0;
        #endif

        #ifndef PHOTONICS_HAND_LIGHT_ENABLED
            #ifdef LIGHTING_HAND
                vec3 handLightPos = GetHandLightPosition();
                float handDist = distance(localPos, handLightPos);
            #endif

            #if defined(LIGHTING_HAND) && !defined(LIGHTING_COLORED)
                float handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
                float handLight = max(handLightLevel - handDist, 0.0) / 15.0;

                lmcoord.x = max(lmcoord.x, handLight);
            #endif
        #endif

        #ifdef LIGHTING_COLORED
//            vec3 voxelPos = GetVoxelPosition(localPos);
            float lpvFade = GetVoxelFade(voxelPos);
        #endif

        #ifdef LIGHTING_SPECULAR
            #ifdef MATERIAL_PBR_ENABLED
                float roughness = mat_roughness(specularData.r);
                float metalness = mat_metalness(specularData.g);
            #else
                float roughness = mat_roughness_lab(specularData.r);
                float metalness = mat_metalness_lab(specularData.g);
            #endif

            float roughL = _pow2(roughness);
        #endif

        bool isLod = false;
        #ifdef LOD_ENABLED
            float vDepth = texelFetch(depthtex0, uv, 0).r;
            isLod = vDepth >= 1.0;
        #endif

        vec3 diffuseFinal;
        vec3 specularFinal = vec3(0.0);

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            shadow *= smoothstep((2.5/16.0), (13.5/16.0), lmcoord.y);

            lmcoord = _pow3(lmcoord);

            const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
            vec3 blockLight = lmcoord.x * blockLightColor;

            #if defined(LIGHTING_COLORED) && !defined(PHOTONICS_BLOCK_LIGHT_ENABLED)
//                vec3 samplePos = GetFloodFillSamplePos(voxelPos, localGeoNormal, localTexNormal);
                vec3 lpvSample = SampleFloodFill(lpvSamplePos);
                blockLight = mix(blockLight, lpvSample, lpvFade);
            #endif

            diffuseFinal = blockLight + MinAmbientF;

            #ifdef WORLD_OVERWORLD
                vec3 skyLightColor = shadow * GetSkyLightColor(localPos, sunLocalDir.y, localSkyLightDir.y);

                float skyLight_NoLm = dot(localSkyLightDir, localTexNormal);
                #ifdef MATERIAL_PBR_ENABLED
                    skyLight_NoLm = (skyLight_NoLm + tex_sss) / (1.0 + tex_sss);
                #endif

                skyLight_NoLm = max(skyLight_NoLm, 0.0);
                vec3 skyLight = skyLight_NoLm * skyLightColor;

                #ifndef SHADOWS_ENABLED
                    skyLight *= lmcoord.y;
                #endif

                diffuseFinal += skyLight;

                #ifdef LIGHTING_SPECULAR
                    if (skyLight_NoLm > 0.0 && dot(localGeoNormal, localSkyLightDir) > 0.0) {
                        vec3 skySpecularLightDir = GetAreaLightDir(localTexNormal, localViewDir, localSkyLightDir, 100.0, 8.0);
                        skySpecularLightDir = normalize(skySpecularLightDir + 0.1*localSkyLightDir);

                        specularFinal += SampleLightSpecular(albedo, localTexNormal, skySpecularLightDir, -localViewDir, skyLight_NoLm, roughL, specularData.g) * skyLightColor;
                    }
                #endif
            #endif
        #else
            #ifdef PHOTONICS_GI_ENABLED
                #ifdef SHADOWS_ENABLED
                    lmcoord.y = shadowF;
                #else
//                    lmcoord.y = _pow3(lmcoord.y);
                    lmcoord.y = 0.5 * _pow3(lmcoord.y);
                #endif
            #endif

            lmcoord.y = min(lmcoord.y, shadowF * (1.0 - AmbientLightF) + AmbientLightF);

            vec2 sample_lmcoord = lmcoord;
            #ifdef LIGHTING_COLORED
                sample_lmcoord.x *= 1.0 - lpvFade;
            #endif
            sample_lmcoord = LightMapTex(sample_lmcoord);

            #if MC_VERSION >= 12111
                // lightmap sampling has no interpolation in 1.21.11+
                diffuseFinal = TexelFetchLinearRGB(texLightmap, sample_lmcoord * 16.0, 0);
            #else
                diffuseFinal = texture(texLightmap, sample_lmcoord).rgb;
            #endif

            float oldLighting = GetOldLighting(localTexNormal);

            #ifdef MATERIAL_PBR_ENABLED
                oldLighting = mix(oldLighting, 1.0, tex_sss);
            #endif

            diffuseFinal *= oldLighting;
            diffuseFinal = RGBToLinear(diffuseFinal);

            #ifdef LIGHTING_COLORED
                vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
                vec3 lpvSample = SampleFloodFill(samplePos, pow(lmcoord.x, 2.2));
                diffuseFinal += lpvFade * lpvSample;
            #endif
        #endif

        #if defined(PHOTONICS_BLOCK_LIGHT_ENABLED) || defined(PHOTONICS_GI_ENABLED)
            if (!isLod) diffuseFinal += texture(texPhotonicsIndirect, texcoord).rgb;
        #endif

        bool skip_GI = false;
        #ifdef PHOTONICS_GI_ENABLED
            if (!isLod) skip_GI = true;
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            if (!skip_GI) diffuseFinal += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);
        #endif

        #if SSAO_MODE != SSAO_FULL
            diffuseFinal *= _pow2(occlusion);
        #endif

        #ifdef SSAO_ENABLED
            diffuseFinal *= texelFetch(TEX_SSAO, uv, 0).r;
        #endif

        #ifndef LIGHTING_SPECULAR
            vec2 uvcoord = gl_FragCoord.xy / viewSize;
            #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
                diffuseFinal += sample_photonics_direct(uvcoord);
            #endif

            #ifdef PHOTONICS_HAND_LIGHT_ENABLED
                diffuseFinal += sample_photonics_handheld(uvcoord);
            #endif
        #endif

        #if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
            if (heldItemId >= 0) {
                vec3 lightColor;
                float lightRange;
                GetBlockColorRange(heldItemId, lightColor, lightRange);

                const float lightRadius = 0.5;
                float att = GetLightAttenuation(handDist, lightRange, lightRadius);
                vec3 handLightDir = normalize(handLightPos - localPos);
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
                vec3 handLightDir = normalize(handLightPos - localPos);
                float hand_NoLm = max(dot(localTexNormal, handLightDir), 0.0);

                diffuseFinal += att * hand_NoLm * lightColor;
                #ifdef LIGHTING_SPECULAR
                    specularFinal += att * SampleLightSpecular(albedo, localTexNormal, handLightDir, -localViewDir, hand_NoLm, roughL, specularData.g) * lightColor;
                #endif
            }
        #endif

        #ifdef LIGHTING_SPECULAR
            float NoV = dot(localTexNormal, -localViewDir);

            float smoothL = 1.0 - roughness; //roughL;
            smoothL = _pow2(smoothL);

            #ifdef MATERIAL_PBR_ENABLED
                LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
                vec3 F = F_lazanyi(NoV, lF.f0, lF.f82);

                diffuseFinal *= 1.0 - metalness * smoothL;
            #else
                float f0 = mat_f0_lab(specularData.g);
                float F = F_schlick(NoV, f0, 1.0);
            #endif

            diffuseFinal *= 1.0 - F * smoothL;

            #if !(defined(SSR_ENABLED) || defined(PHOTONICS_REFLECT_ENABLED))
                // TODO: reflect in view space to avoid view-bob
                vec3 reflectLocalDir = normalize(reflect(localViewDir, localTexNormal));

                vec3 reflectColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), reflectLocalDir);
                reflectColor *= _pow2(lmcoord.y);

                specularFinal += smoothL * F * reflectColor;
            #endif

            // apply metal tint
            specularFinal *= mix(vec3(1.0), albedo, metalness);
        #endif

        #ifdef MATERIAL_PBR_ENABLED
            float emission = mat_emission(specularData);
            TransformEmission(emission);
            diffuseFinal += emission;
        #endif

        #ifdef DEBUG_WHITEWORLD
            albedo = vec3(0.86);
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            outFinal = albedo/PI * diffuseFinal + specularFinal;
        #else
            outFinal = albedo * diffuseFinal + specularFinal;
        #endif

        #ifdef LIGHTING_SPECULAR
            vec2 uvcoord = gl_FragCoord.xy / viewSize;
            #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
                outFinal += sample_photonics_direct(uvcoord);
            #endif

            #ifdef PHOTONICS_HAND_LIGHT_ENABLED
                outFinal += sample_photonics_handheld(uvcoord);
            #endif
        #endif

        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = max(borderFogF, envFogF);

//        #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
//            fogF = max(fogF, 1.0 - vIn.chunkFade);
//        #endif

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

        outFinal = mix(outFinal, fogColorFinal, fogF);

//        outFinal = vec3(lmcoord, 0.0);
//        outFinal = texture(texLightmap, gl_FragCoord.xy / viewSize).rgb;
//        outFinal = TextureLinearRGB(texLightmap, gl_FragCoord.xy / viewSize, vec2(16.0));
    }
}
