float GetLightAttenuation_Diffuse(float lightDist, const in float lightRange, const in float lightRadius) {
    lightDist = max(lightDist - lightRadius, 0.0);
    float lightDistF = 1.0 - saturate(lightDist / lightRange);

    float invSq = 1.0 / (_pow2(lightDist) + lightRadius);
    float linear = pow5(lightDistF);

    return mix(linear, invSq, lightDistF);
}


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

    att *= max(dot(geometry_normal, light_dir), 0.0);
    att *= max(dot(texture_normal, light_dir), 0.0);

    return att * light.color;
}
