vec3 GetMaterialFresnel(const in vec3 albedo, const in float metal_f0, const in float roughL, const in float theta, const in bool isUnderWater) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR
        vec3 f0 = vec3(metal_f0);
        int hcm = int(metal_f0 * 255.0 + 0.5);

        if (hcm >= 230 && hcm < 255) {
            // int hcm = int(metal_f0 * 255.0 + 0.5) - 230;

            vec3 n, k;
            GetHcmFresnel(albedo, hcm, n, k);
            return ComplexFresnel(n, k, theta);
        }
        else if (hcm >= 255) {
            f0 = pow(albedo, vec3(HCM_AlbedoGammaInv));
        }
        else if (metal_f0 < (1.5/255.0)) {
            f0 = vec3(0.04);
        }

        if (isUnderWater) {
            vec3 ior = F0ToIor(f0, vec3(1.0));
            f0 = IorToF0(ior, vec3(1.33));
        }

        return F_schlickRough(theta, f0, roughL);
    #else
        float f0 = mix(vec3(0.04), albedo, metal_f0);
        return vec3(F_schlickRough(theta, f0, roughL));
    #endif
}
