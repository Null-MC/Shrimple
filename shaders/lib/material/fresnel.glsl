vec3 GetMaterialF0(const in vec3 albedo, const in float metal_f0) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR
        vec3 f0 = vec3(metal_f0);

        if (IsMetal(metal_f0)) {
            int hcm = int(metal_f0 * 255.0 + 0.5) - 230;
            f0 = GetHCM_f0(albedo, hcm);
        }
        else if (metal_f0 < (1.5/255.0)) {
            f0 = vec3(0.04);
        }

        return f0;
    #else
        //return IsMetal(metal_f0) ? albedo : vec3(0.04);
        return mix(vec3(0.04), albedo, metal_f0);
    #endif
}
