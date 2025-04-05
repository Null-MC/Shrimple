float GetMaterialPorosity(const in vec2 texcoord, const in float mip, const in float roughness, const in float metal_f0) {
    float porosity = 0.0;
    
    #if MATERIAL_POROSITY == POROSITY_LABPBR
        porosity = textureLod(specular, texcoord, mip).b;
        porosity = (porosity * 4.0) * step(porosity, 0.25);
    #elif MATERIAL_POROSITY == POROSITY_DEFAULT
        float metalInv = saturate(unmix(metal_f0, 0.04, (229.0/255.0)));
        porosity = sqrt(roughness) * metalInv;
    #endif

    return porosity;
}
