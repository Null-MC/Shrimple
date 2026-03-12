#include "/lib/constants.glsl"
#include "/lib/common.glsl"


#include "/lib/blocks.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/shadows.glsl"

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    vec4 color = parameters.sampledColour;
    color.rgb *= parameters.tinting.rgb;

    vec3 ndcPos = gl_FragCoord.xyz;
    ndcPos.xy /= viewSize;
    ndcPos = ndcPos * 2.0 - 1.0;

    vec3 viewPos = project(vxProjInv, ndcPos);
    vec3 localPos = mul3(vxModelViewInv, viewPos);

    vec3 localNormal = vec3(
        uint((parameters.face >> 1) == 2),
        uint((parameters.face >> 1) == 0),
        uint((parameters.face >> 1) == 1)
    ) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    // TODO: if vanilla lighting, make foliage have "up" normals
    #ifndef MATERIAL_PBR_ENABLED
        bool isGrass = parameters.customId == BLOCK_GRASS_SHORT
            || parameters.customId == BLOCK_TALL_GRASS_LOWER
            || parameters.customId == BLOCK_TALL_GRASS_UPPER;

        if (isGrass) localNormal = vec3(0,1,0);
    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
        if (parameters.customId == BLOCK_WATER) {
            // TODO: add option to make clear?
            // albedo = vec3(0.0);
            specularData = vec4(0.98, 0.02, 0.0, 0.0);
        }
    #endif

    float viewDist = length(localPos);
    vec2 lmcoord_in = LightMapNorm(parameters.lightMap);

    vec3 localSkyLightDir = normalize(mat3(vxModelViewInv) * shadowLightPosition);

    float shadow = pow4(lmcoord_in.y);
    #ifdef SHADOW_CLOUDS
        shadow *= SampleCloudShadow(localPos, localSkyLightDir);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        vec2 lmcoord = _pow3(lmcoord_in);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        vec3 skyLight = vec3(0.0);
        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = GetSkyLightColor(localPos, sunLocalDir.y, localSkyLightDir.y);
            float skyLight_NoLm = max(dot(localSkyLightDir, localNormal), 0.0);
            skyLight = skyLight_NoLm * shadow * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localNormal);
            #endif
        #endif

        color.rgb = albedo.rgb * (blockLight + skyLight + MinAmbientF);
    #else
        vec2 lmcoord = lmcoord_in;

        lmcoord.y = min(lmcoord.y, shadow * (1.0 - AmbientLightF) + AmbientLightF);

        lmcoord.y *= GetOldLighting(localNormal);

        lmcoord = LightMapTex(lmcoord);
        vec3 lit = texture(lightmap, lmcoord).rgb;
        lit = RGBToLinear(lit);

        color.rgb = albedo.rgb * lit;
    #endif

    #if !defined(SSAO_ENABLED) || defined(RENDER_TRANSLUCENT)
        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = saturate(max(borderFogF, envFogF));

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 localViewDir = normalize(localPos);
        vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);
    #endif

    outFinal = color;

    #ifdef DEFERRED_NORMAL_ENABLED
        outGeoNormal = packUnorm2x16(OctEncode(localNormal));

        vec3 viewNormal = mat3(gbufferModelView) * localNormal;
        outTexNormal = packUnorm2x16(OctEncode(viewNormal));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outReflectSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), lmcoord_in.y)),
            packUnorm4x8(specularData));
    #endif
}
