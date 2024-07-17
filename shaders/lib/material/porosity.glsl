float GetMaterialPorosity(const in vec2 texcoord, const in mat2 dFdXY, const in float roughness, const in float metal_f0) {
    float porosity = 0.0;
    #if MATERIAL_POROSITY == POROSITY_LABPBR
        porosity = textureGrad(specular, texcoord, dFdXY[0], dFdXY[1]).b;
        porosity = (porosity * 4.0) * step(porosity, 0.25);
    #elif MATERIAL_POROSITY == POROSITY_DEFAULT
        // float metalInv = min(metal_f0 / 229.0, 1.0);
        float metalInv = saturate(unmix(metal_f0, 0.04, (229.0/255.0)));
        // porosity = roughness * step(metal_f0, 0.5);
        porosity = sqrt(roughness) * metalInv;
    #endif

    return porosity;
}
