#define _IOR_to_f0(ior) (pow(abs(((ior) - 1.0) / ((ior) + 1.0)), 2.0))


vec3 GetMaterialFresnel(const in vec3 albedo, const in float metal_f0, const in float roughL, const in float theta, const in bool isUnderWater) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR
        float f0 = metal_f0;

        if (IsMetal(metal_f0)) {
            int hcm = int(metal_f0 * 255.0 + 0.5) - 230;

            vec3 n, k;
            GetHcmFresnel(albedo, hcm, n, k);
            return ComplexFresnel(n, k, theta);
        }
        else if (metal_f0 < (1.5/255.0)) {
            f0 = _IOR_to_f0(1.5);
        }

        if (isUnderWater) {
            float ior = F0ToIor(f0, 1.0);
            f0 = IorToF0(ior, 1.33);
        }

        return vec3(F_schlickRough(theta, f0, roughL));
    #else
        float f0 = mix(vec3(0.04), albedo, metal_f0);
        return vec3(F_schlickRough(theta, f0, roughL));
    #endif
}

// vec3 GetMaterialF0(const in vec3 albedo, const in float metal_f0) {
//     #if MATERIAL_SPECULAR == SPECULAR_LABPBR
//         vec3 f0 = vec3(metal_f0);

//         if (IsMetal(metal_f0)) {
//             int hcm = int(metal_f0 * 255.0 + 0.5) - 230;
//             f0 = GetHcmFresnel(albedo, hcm);
//         }
//         else if (metal_f0 < (1.5/255.0)) {
//             f0 = vec3(0.04);
//         }

//         return f0;
//     #else
//         //return IsMetal(metal_f0) ? albedo : vec3(0.04);
//         return mix(vec3(0.04), albedo, metal_f0);
//     #endif
// }
