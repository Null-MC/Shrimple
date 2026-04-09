#include "/lib/lighting/attenuation.glsl"
#include "/lib/material/pbr.glsl"
#include "/lib/fresnel.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material/lazanyi.glsl"
#endif

#ifdef LIGHTING_SPECULAR
    #include "/lib/lighting/specular.glsl"
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
        float att = GetLightAttenuation(lightDist, light.block_radius, lightRadius);
    #else
        float att = 1.0 / (lightDistSq * light.falloff * light.attenuation.y + light.attenuation.x);
    #endif

    float NoLm = max(dot(texture_normal, light_dir), 0.0);
    NoLm *= step(EPSILON, dot(geometry_normal, light_dir));

    #ifdef LIGHTING_SPECULAR
        vec3 localPos = sample_pos - rt_camera_position;
        vec3 localViewDir = normalize(localPos);

        ivec2 uv = ivec2(gl_FragCoord.xy);
//        uvec2 albedoSpecularData = texelFetch(TEX_ALBEDO_SPECULAR, uv, 0).rg;
//        vec4 albedoData = unpackUnorm4x8(albedoSpecularData.r);
//        vec4 specularData = unpackUnorm4x8(albedoSpecularData.g);
        vec3 albedo = texelFetch(TEX_GB_COLOR, uv, 0).rgb;
        uvec2 specularMeta = texelFetch(TEX_GB_SPECULAR, uv, 0).rg;
        vec4 specularData = unpackUnorm4x8(specularMeta.r);
        albedo = RGBToLinear(albedo);

        #ifdef DEBUG_WHITEWORLD
            albedo = vec3(0.86);
        #endif

        // TODO: force Lab metalness when no PBR RP?
        float roughness = mat_roughness(specularData.r);
        float metalness = mat_metalness(specularData.g);
        float roughL = _pow2(roughness);

        vec3 lit = albedo/PI;

        // reduce diffuse for metals
        lit *= 1.0 - metalness * (1.0 - roughL);

        vec3 specular = SampleLightSpecular(albedo, texture_normal, light_dir, -localViewDir, NoLm, roughL, specularData.g);

        // TODO: decrease specular with roughness

        // apply metal tint
        lit += specular * mix(vec3(1.0), albedo, metalness);

        return att * NoLm * lit * light.color;
    #else
        return att * NoLm * light.color;
    #endif
}
