#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef DEFERRED_BUFFER_ENABLED
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out uvec4 outDeferredData;
    layout(location = 2) out vec3 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,3,9,7 */
        layout(location = 3) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,3,9 */
    #endif
#else
    layout(location = 0) out vec4 outFinal;

    #ifdef EFFECT_SSAO_ENABLED
        layout(location = 1) out vec3 outDeferredTexNormal;

        #ifdef EFFECT_TAA_ENABLED
            /* RENDERTARGETS: 0,9,7 */
            layout(location = 2) out vec4 outVelocity;
        #else
            /* RENDERTARGETS: 0,9 */
        #endif
    #else
        #ifdef EFFECT_TAA_ENABLED
            /* RENDERTARGETS: 0,7 */
            layout(location = 1) out vec4 outVelocity;
        #else
            /* RENDERTARGETS: 0 */
        #endif
    #endif
#endif

float computeBlockEmission(uint blockId) {
//    uint lightType = GetSceneLightType(blockId);
//
//    float range = GetSceneLightRange(lightType);
//    float emission = range / 15.0;
//
//    //float emission = GetSceneLightEmission(lightType);
//    emission = _pow3(emission);
//    return emission * Lighting_Brightness;

    return 0.0;
}

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    // Get base properties

    vec3 base_color = parameters.sampledColour.rgb * parameters.tinting.rgb;
    base_color = RGBToLinear(base_color);

    // from Cortex
    vec3 normal = vec3(
        uint((parameters.face >> 1) == 2),
        uint((parameters.face >> 1) == 0),
        uint((parameters.face >> 1) == 1)
    ) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    uint material_mask = max(parameters.customId - 10000u, 0u);

    float roughness = GetBlockRoughness(parameters.customId);
    float emission = computeBlockEmission(parameters.customId);
    float metal_f0 = GetBlockMetalF0(parameters.customId);
    float sss = GetBlockSSS(parameters.customId);
    const float occlusion = 1.0;
    const float porosity = 0.0;

    const float parallaxShadow = 0.0;
    vec2 lmFinal = LightMapNorm(parameters.lightMap);

    // Encode gbuffer data
//    gbuffer_data_0.x  = pack_unorm_2x8(base_color.rg);
//    gbuffer_data_0.y  = pack_unorm_2x8(base_color.b, clamp01(float(material_mask) * rcp(255.0)));
//    gbuffer_data_0.z  = pack_unorm_2x8(encode_unit_vector(normal));
//    gbuffer_data_0.w  = pack_unorm_2x8(parameters.lightMap);

    #if defined DEFERRED_BUFFER_ENABLED || defined EFFECT_SSAO_ENABLED
        outDeferredTexNormal = normal * 0.5 + 0.5;
    #endif

    #ifdef DEFERRED_BUFFER_ENABLED
        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
            ApplySkyWetness(roughness, porosity, skyWetness, puddleF);
        #endif

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        color.rgb = LinearToRGB(albedo);

        // color.r = (vIn.blockId % 4) / 4.0;
        // color.g = (vIn.blockId % 8) / 8.0;
        // color.b = (vIn.blockId % 16) / 16.0;

//        if (!all(lessThan(abs(texNormal), EPSILON3)))
//            texNormal = texNormal * 0.5 + 0.5;

        outDeferredColor = color + dither;

        outDeferredData.r = packUnorm4x8(vec4(normal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(0.0, parallaxShadow, 0.0, 0.0) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        // TODO
    #endif
}