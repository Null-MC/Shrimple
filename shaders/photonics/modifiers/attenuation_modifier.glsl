//uniform usampler2D TEX_ALBEDO_SPECULAR;

#include "/lib/material/pbr.glsl"
#include "/lib/fresnel.glsl"
#include "/lib/brdf.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material/lazanyi.glsl"
#endif


vec3 modify_attenuation(
    const in Light light,
    const in vec3 to_light,
    const in vec3 sample_pos,
    const in vec3 source_pos,
    const in vec3 geometry_normal,
    const in vec3 texture_normal
) {
    float lightDistSq = dot(to_light, to_light);
    float lightDistInv = inversesqrt(lightDistSq);
    float lightDist = lightDistSq * lightDistInv;
    vec3 light_dir = to_light * lightDistInv;

    #ifdef PHOTONICS_SHRIMPLE_COLORS
        const float lightRadius = 0.5;
        float att = 3.0 * GetLightAttenuation_Diffuse(lightDist, light.block_radius, lightRadius);
    #else
        float att = 1.0 / (lightDistSq * light.falloff * light.attenuation.y + light.attenuation.x);
    #endif

    vec3 lit = vec3(1.0/PI);

    //    att *= max(dot(geometry_normal, light_dir), 0.0);
    float NoLm = max(dot(texture_normal, light_dir), 0.0);
    NoLm *= step(EPSILON, dot(geometry_normal, light_dir));

    #ifdef LIGHTING_SPECULAR
        vec3 localPos = sample_pos - rt_camera_position;
        vec3 localViewDir = normalize(localPos);

        vec3 H = normalize(light_dir - localViewDir);
        float NoH = max(dot(texture_normal, H), 0.0);
        float LoH = max(dot(light_dir, H), 0.0);
        float NoV = max(dot(texture_normal, -localViewDir), 0.0);

        ivec2 uv = ivec2(gl_FragCoord.xy);
        uvec2 albedoSpecularData = texelFetch(TEX_ALBEDO_SPECULAR, uv, 0).rg;
        vec4 albedoData = unpackUnorm4x8(albedoSpecularData.r);
        vec4 specularData = unpackUnorm4x8(albedoSpecularData.g);

        vec3 albedo = RGBToLinear(albedoData.rgb);
        lit *= albedo;

        float roughness = mat_roughness(specularData.r);
        float roughL = _pow2(roughness);

        #ifdef MATERIAL_PBR_ENABLED
            LazanyiF L = mat_f0_lazanyi(albedo, specularData.g);
            vec3 F = F_lazanyi(LoH, L.f0, L.f82);

            float smoothL = 1.0 - roughL;
            float metalness = mat_metalness(specularData.g);
            att *= 1.0 - metalness * smoothL;
        #else
            float f0 = mat_f0_lab(specularData.g);
            float F = F_schlick(LoH, f0, 1.0);
        #endif

        float alpha = max(_pow2(roughL), 0.0002);
        lit += D_GGX(NoH, alpha) * V_Approx(NoLm, NoV, alpha) * (1.0 - roughness) * F;
    #endif

    return NoLm * att * lit * light.color;
}
