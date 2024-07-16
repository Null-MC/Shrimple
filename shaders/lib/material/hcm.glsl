// vec3 f0_to_IOR(const in vec3 f0) {
//     vec3 sqrt_f0 = sqrt(max(f0, vec3(0.02)));
//     return (1.0 + sqrt_f0) / max(1.0 - sqrt_f0, EPSILON3);
// }


#ifdef HCM_LAZANYI
    const vec3 iron_f0  = vec3(0.78, 0.77, 0.74);
    const vec3 iron_f82 = vec3(0.74, 0.76, 0.76);

    const vec3 gold_f0  = vec3(1.00, 0.90, 0.61);
    const vec3 gold_f82 = vec3(1.00, 0.93, 0.73);

    const vec3 aluminum_f0  = vec3(1.00, 0.98, 1.00);
    const vec3 aluminum_f82 = vec3(0.96, 0.97, 0.98);

    const vec3 chrome_f0  = vec3(0.77, 0.80, 0.79);
    const vec3 chrome_f82 = vec3(0.74, 0.79, 0.78);

    const vec3 copper_f0  = vec3(1.00, 0.89, 0.73);
    const vec3 copper_f82 = vec3(1.00, 0.90, 0.80);

    const vec3 lead_f0  = vec3(0.79, 0.87, 0.85);
    const vec3 lead_f82 = vec3(0.83, 0.80, 0.83);

    const vec3 platinum_f0  = vec3(0.92, 0.90, 0.83);
    const vec3 platinum_f82 = vec3(0.89, 0.87, 0.81);

    const vec3 silver_f0  = vec3(1.00, 1.00, 0.91);
    const vec3 silver_f82 = vec3(1.00, 1.00, 0.95);

    const vec3 lazanyi_f0[8] = vec3[](
        iron_f0,
        gold_f0,
        aluminum_f0,
        chrome_f0,
        copper_f0,
        lead_f0,
        platinum_f0,
        silver_f0);

    const vec3 lazanyi_f82[8] = vec3[](
        iron_f82,
        gold_f82,
        aluminum_f82,
        chrome_f82,
        copper_f82,
        lead_f82,
        platinum_f82,
        silver_f82);


    // void GetHCM_IOR(const in vec3 albedo, const in int hcm, out vec3 f0, out vec3 f82) {
    //     if (hcm < 8) {
    //         // HCM conductor
    //         f0  = RGBToLinear(lazanyi_f0[hcm]);
    //         f82 = RGBToLinear(lazanyi_f82[hcm]);
    //     }
    //     else {
    //         // albedo-only conductor
    //         f0 = albedo;
    //         f82 = vec3(1.0); //albedo;
    //     }
    // }

    void GetHCM_f0(const in vec3 albedo, const in int hcm, out vec3 f0, out vec3 f82) {
        if (hcm < 8) {
            // HCM conductor
            f0  = RGBToLinear(lazanyi_f0[hcm]);
            f82 = RGBToLinear(lazanyi_f82[hcm]);
        }
        else {
            // albedo-only conductor
            f0 = albedo;
            f82 = vec3(1.0); //albedo;
        }
    }
#else
    const vec3 ior_n_iron = vec3(2.9114, 2.9497, 2.5845);
    //const vec3 ior_k_iron = vec3(3.4040, 3.1710, 2.8060);

    const vec3 ior_n_gold = vec3(0.18299, 0.42108, 1.3734);
    //const vec3 ior_k_gold = vec3(3.6123, 2.3459, 1.8135);

    const vec3 ior_n_aluminum = vec3(1.3456, 0.96521, 0.61722);
    //const vec3 ior_k_aluminum = vec3(7.6635, 6.4581, 5.0699);

    const vec3 ior_n_chrome = vec3(3.1071, 3.1812, 2.3230);
    //const vec3 ior_k_chrome = vec3(4.3511, 4.2311, 3.7505);

    const vec3 ior_n_copper = vec3(0.27105, 0.67693, 1.3164);
    //const vec3 ior_k_copper = vec3(3.8090, 2.6248, 2.2981);

    const vec3 ior_n_lead = vec3(1.9100, 1.8300, 1.4400);
    //const vec3 ior_k_lead = vec3(4.1709, 4.1823, 4.1552);

    const vec3 ior_n_platinum = vec3(2.3757, 2.0847, 1.8453);
    //const vec3 ior_k_platinum = vec3(4.3677, 3.7153, 3.0211);

    const vec3 ior_n_silver = vec3(0.15943, 0.14512, 0.13547);
    //const vec3 ior_k_silver = vec3(4.0728, 3.1900, 2.1997);


    #define IOR_to_f0(ior) (pow(((ior) - 1.0) / ((ior) + 1.0), vec3(2)))

    const vec3 hcm_f0[8] = vec3[](
        IOR_to_f0(ior_n_iron),
        IOR_to_f0(ior_n_gold),
        IOR_to_f0(ior_n_aluminum),
        IOR_to_f0(ior_n_chrome),
        IOR_to_f0(ior_n_copper),
        IOR_to_f0(ior_n_lead),
        IOR_to_f0(ior_n_platinum),
        IOR_to_f0(ior_n_silver));


    // void GetHCM_IOR(const in vec3 albedo, const in int hcm, out vec3 n, out vec3 k) {
    //     if (hcm < 8) {
    //         // HCM conductor
    //         n = ior_n[hcm];
    //         k = ior_k[hcm];
    //     }
    //     else {
    //         // albedo-only conductor
    //         n = vec3(f0_to_IOR(albedo));
    //         k = albedo;
    //     }
    // }

    // vec3 IOR_to_f0(const in vec3 ior) {
    //     return pow2((ior - 1.0) / (ior + 1.0));
    // }

    //vec3 GetHCM_f0(const in vec3 albedo, const in int hcm, out vec3 n, out vec3 k) {
    vec3 GetHCM_f0(const in vec3 albedo, const in int hcm) {
        if (hcm < 8) {
            // HCM conductor
            //n = IOR_to_f0(ior_n[hcm]);
            //k = IOR_to_f0(ior_k[hcm]);
            return hcm_f0[hcm];
        }
        else {
            // albedo-only conductor
            //n = albedo;
            //k = 0.0;//albedo;
            return albedo;
        }
    }
#endif

bool IsMetal(const in float metal_f0) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR
        return metal_f0 >= (229.5/255.0);
    #else
        //return mix(vec3(1.0), albedo, metal_f0);
        return metal_f0 >= 0.5;
    #endif
}

// vec3 GetHCM_Tint(const in vec3 albedo, const in int hcm) {
//     if (hcm < 0) return vec3(1.0);
//     //else if (hcm < 8) return IORToF0(ior_n[hcm]);

//     #ifndef MATERIAL_HCM_ALBEDO_TINT
//         if (hcm < 8) return vec3(1.0);
//     #endif

//     return albedo;
// }

vec3 GetMetalTint(const in vec3 albedo, const in float metal_f0) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR

        #ifndef MATERIAL_HCM_ALBEDO_TINT
            int hcm = int(metal_f0 * 255.0 + 0.5) - 230;
            //if (hcm < 0) return vec3(1.0);
            if (hcm < 8) return vec3(1.0);
        #else
            if (!IsMetal(metal_f0)) return vec3(1.0);
        #endif

        //return IsMetal(metal_f0) ? albedo : vec3(1.0);
        return albedo;
    #else
        return mix(vec3(1.0), albedo, metal_f0);
    #endif
}

void ApplyMetalDarkening(inout vec3 diffuse, inout vec3 specular, const in vec3 albedo, const in float metal_f0, const in float roughL) {
    #if MATERIAL_SPECULAR == SPECULAR_LABPBR
        float metalF = IsMetal(metal_f0) ? 1.0 : 0.0;
    #else
        float metalF = metal_f0;
    #endif

    diffuse *= mix(1.0, MaterialMetalBrightnessF, metalF * (1.0 - _pow2(roughL)));
    specular *= GetMetalTint(albedo, metal_f0);
}
