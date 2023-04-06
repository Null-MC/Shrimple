float GetMaterialF0(const in float metal_f0) {
    return metal_f0 > 0.5 ? 0.96 : 0.04;
}

void GetMaterialSpecular(const in vec2 texcoord, out float roughness, out float metal_f0) {
    #ifdef MATERIAL_SPECULAR
        vec2 specularMap = texture(specular, texcoord).rg;
        roughness = 1.0 - specularMap.r;
        metal_f0 = specularMap.g;
    #else
        roughness = 1.0;
        metal_f0 = 0.04;
    #endif
}
