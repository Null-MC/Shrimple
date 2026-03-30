#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat int materialId;
} vIn;


#ifdef RENDER_TRANSLUCENT
    uniform sampler2D depthtex0;

    #ifdef WATER_WAVE_ENABLED
        uniform sampler2D TEX_WATER_NORMAL;
    #endif
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
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

uniform float far;
uniform float nearPlane;
uniform float farPlane;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform float skyDayF;
uniform int hasSkylight;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int frameCounter;
uniform vec2 viewSize;

uniform int vxRenderDistance;
uniform float dhNearPlane;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/hsv.glsl"
#include "/lib/ign.glsl"
#include "/lib/fog.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/dh-noise.glsl"
#include "/lib/shadows.glsl"
#include "/lib/octohedral.glsl"

//#if defined(MATERIAL_PBR_ENABLED) || defined(DEFERRED_REFLECT_ENABLED)
//    #include "/lib/octohedral.glsl"
//    #include "/lib/fresnel.glsl"
//    #include "/lib/material/pbr.glsl"
//#endif

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

#ifdef LIGHTING_SPECULAR
    #include "/lib/lighting/specular.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void main() {
    vec3 localNormal = normalize(vIn.localNormal);
    float viewDist = length(vIn.localPos);
    vec3 localViewDir = vIn.localPos / viewDist;

    #ifdef RENDER_TRANSLUCENT
        float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;

        if (depth < 1.0) {
            vec3 vanillaNdcPos = vec3(gl_FragCoord.xy / viewSize, depth) * 2.0 - 1.0;
            vec3 vanillaViewPos = project(gbufferProjectionInverse, vanillaNdcPos);

            vec3 viewPos = mul3(gbufferModelView, vIn.localPos);
            if (vanillaViewPos.z > viewPos.z) {discard; return;}
        }
    #endif

    if (viewDist < dh_clipDistF * far) {
        discard;
        return;
    }

    vec4 color = vIn.color;

    vec3 albedo = RGBToLinear(color.rgb);
    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    #ifndef RENDER_TRANSLUCENT
        vec3 worldPos = vIn.localPos + cameraPosition;
        applyNoise(albedo, 1.0, worldPos, viewDist);
    #endif

    vec3 localTexNormal = localNormal;
    if (vIn.materialId == DH_BLOCK_WATER) {
        #ifndef WATER_TEXTURE_ENABLED
//            albedo = RGBToLinear(parameters.tinting.rgb);
            color.a = 0.04;
        #endif

        #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
            specularData = vec4(0.98, 0.02, 0.0, 0.0);
        #endif

        #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
            vec2 worldPos = vIn.localPos.xz + cameraPosition.xz;

            vec2 water_uv = worldPos / WaterNormalScale;
            vec3 waterNormal1 = texelFetch(TEX_WATER_NORMAL, ivec2(water_uv * WaterNormalResolution) % WaterNormalResolution, 0).xyz * 2.0 - 1.0;
            waterNormal1 = normalize(vec3(1.0,1.0,6.0) * waterNormal1);

            water_uv *= 5.0;
            vec3 waterNormal2 = texelFetch(TEX_WATER_NORMAL, ivec2(water_uv * WaterNormalResolution) % WaterNormalResolution, 0).xyz * 2.0 - 1.0;
            waterNormal2 = normalize(vec3(0.2,0.2,1.0) * waterNormal2);

            localTexNormal = normalize(waterNormal1 + waterNormal2).xzy;
        #endif
    }

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
        vec3 shadowPos = vIn.localPos;
        shadowPos += 0.08 * localNormal;
        shadowPos = mul3(shadowModelView, shadowPos);
//        shadowPos.z += 0.032 * viewDist;
//        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        float shadowCoverageF = smoothstep(0.92, 0.98, length(shadowPos.xy));

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        shadowCoverageF *= float(saturate(shadowPos.z) == shadowPos.z);

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

    #ifdef LIGHTING_SPECULAR
        float roughness = mat_roughness_lab(specularData.r);
        float metalness = mat_metalness_lab(specularData.g);

        float roughL = _pow2(roughness);
    #endif

    vec2 lmcoord = vIn.lmcoord;
    vec3 diffuseFinal = vec3(0.0);
    vec3 specularFinal = vec3(0.0);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        diffuseFinal = blockLight + MinAmbientF;

        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = shadow * GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);

            float skyLight_NoLm = dot(localSkyLightDir, localTexNormal);
//            #ifdef MATERIAL_PBR_ENABLED
//                skyLight_NoLm = mix(skyLight_NoLm, 1.0, 0.7*sss);
//            #endif

            skyLight_NoLm = max(skyLight_NoLm, 0.0);
            vec3 skyLight = skyLight_NoLm * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);

            diffuseFinal += skyLight;

            #ifdef LIGHTING_SPECULAR
                if (skyLight_NoLm > 0.0) {
                    vec3 skySpecularLightDir = GetAreaLightDir(localTexNormal, localViewDir, localSkyLightDir, 100.0, 8.0);
                    skySpecularLightDir = normalize(skySpecularLightDir + 0.1*localSkyLightDir);

                    vec3 H = normalize(skySpecularLightDir - localViewDir);
                    float sky_NoH = max(dot(localTexNormal, H), 0.0);
                    float sky_LoH = max(dot(skySpecularLightDir, H), 0.0);
                    float sky_NoV = max(dot(localTexNormal, -localViewDir), 0.0);

//                    #ifdef MATERIAL_PBR_ENABLED
//                        LazanyiF sky_L = mat_f0_lazanyi(albedo, specularData.g);
//                        vec3 sky_F = F_lazanyi(sky_LoH, sky_L.f0, sky_L.f82);
//                    #else
                        float f0 = mat_f0_lab(specularData.g);
                        float sky_F = F_schlick(sky_LoH, f0, 1.0);
//                    #endif

                    float alpha = max(roughL, 0.02);
                    specularFinal += skyLight_NoLm * D_GGX(sky_NoH, alpha) * V_Approx(skyLight_NoLm, sky_NoV, alpha) * sky_F * skyLightColor;
                }

                // apply metal tint
                specularFinal *= mix(vec3(1.0), albedo, metalness);
            #endif
        #endif

//        color.rgb = albedo * (blockLight + skyLight);
    #else
        lmcoord.y = min(lmcoord.y, shadowF * (1.0 - AmbientLightF) + AmbientLightF);

        lmcoord = LightMapTex(lmcoord);
        diffuseFinal = texture(texLightmap, lmcoord).rgb;
        float oldLighting = GetOldLighting(localTexNormal);
//        #ifdef MATERIAL_PBR_ENABLED
//            oldLighting = mix(oldLighting, 1.0, sss);
//        #endif
        diffuseFinal *= oldLighting;
        diffuseFinal = RGBToLinear(diffuseFinal);
    #endif

//    #ifdef REFLECT_ENABLED
//        float NoV = dot(localNormal, -localViewDir);
//        diffuseFinal *= 1.0 - F_schlick(NoV, f0, 1.0) * _pow2(smoothness);
//    #endif

    #ifdef LIGHTING_SPECULAR
        float NoV = dot(localTexNormal, -localViewDir);

        float smoothness = 1.0 - roughness;
        float f0 = mat_f0_lab(specularData.g);
        float F = F_schlick(NoV, f0, 1.0);

        color.a = max(color.a, F);

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
        diffuseFinal += albedo * emission;
    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        color.rgb = albedo/PI * diffuseFinal * color.a + specularFinal;
    #else
        color.rgb = albedo * diffuseFinal + specularFinal;
    #endif

    #if !defined(SSAO_ENABLED) || defined(RENDER_TRANSLUCENT)
        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = max(borderFogF, envFogF);

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);
    #endif

    outFinal = color;
    outMeta = 0u;

    #ifdef RENDER_TRANSLUCENT
//        outTint = vec4(1.0, 1.0, 1.0, 0.0);
        vec3 tint = LinearToRGB(albedo * color.a);
        uint matID = 0;

        if (vIn.materialId == DH_BLOCK_WATER) {
            matID = MAT_WATER;
            tint = vIn.color.rgb;
        }

//        if (parameters.customId >= BLOCK_STAINED_GLASS_BLACK && parameters.customId <= BLOCK_TINTED_GLASS)
//            matID = MAT_STAINED_GLASS;

        outTint = vec4(tint, (matID + 0.5) / 255.0);
    #endif

    #if defined(VELOCITY_ENABLED)
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_NORMAL_ENABLED
        vec3 viewNormal = mat3(gbufferModelView) * localTexNormal;
        outNormal = vec4(OctEncode(localNormal), OctEncode(viewNormal));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outAlbedoSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), lmcoord.y)),
            packUnorm4x8(specularData));
    #endif
}
