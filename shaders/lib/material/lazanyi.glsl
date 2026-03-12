struct LazanyiF {
    vec3 f0;
    vec3 f82;
};

const LazanyiF lazanyi_hcm[8] = LazanyiF[](
    LazanyiF( // iron
        pow(vec3(0.953, 0.945, 0.914), vec3(2.2)),
        pow(vec3(0.933, 0.945, 0.953), vec3(2.2))),

    LazanyiF( // gold
        pow(vec3(1.000, 0.859, 0.596), vec3(2.2)),
        pow(vec3(0.973, 0.984, 0.961), vec3(2.2))),

    LazanyiF( // aluminum
        pow(vec3(0.961, 0.965, 0.965), vec3(2.2)),
        pow(vec3(0.961, 0.973, 0.980), vec3(2.2))),

    LazanyiF( // chrome
        pow(vec3(0.769, 0.773, 0.769), vec3(2.2)),
        pow(vec3(0.875, 0.882, 0.914), vec3(2.2))),

    LazanyiF( // copper
        pow(vec3(1.000, 0.827, 0.753), vec3(2.2)),
        pow(vec3(0.988, 0.972, 0.969), vec3(2.2))),

    LazanyiF( // lead
        pow(vec3(0.79, 0.87, 0.85), vec3(2.2)),
        pow(vec3(0.83, 0.80, 0.83), vec3(2.2))),

    LazanyiF( // platinum
        pow(vec3(0.980, 0.969, 0.918), vec3(2.2)),
        pow(vec3(0.976, 0.976, 0.973), vec3(2.2))),

    LazanyiF( // silver
        pow(vec3(0.996, 0.992, 0.984), vec3(2.2)),
        pow(vec3(0.996, 1.000, 1.000), vec3(2.2)))
);

vec3 f82_from_f0(const in vec3 f0) {
    return (2371179624770769.0 * f0 + 2041666790000000.0) / 4412846414770769.0;
}

LazanyiF mat_f0_lazanyi(const in vec3 albedo, const in float specular_g) {
    #if MATERIAL_FORMAT != MAT_DEFAULT
        float metalness = mat_metalness(specular_g);

        #if MATERIAL_FORMAT == MAT_LABPBR
            int hcm_i = int(specular_g * 255.0 - 229.5);

            if (hcm_i >= 0 && hcm_i < 8)
                return lazanyi_hcm[hcm_i];
        #endif

        vec3 f0  = mix(vec3(specular_g), sqrt(albedo), metalness);
        vec3 f82 = f82_from_f0(f0);
        return LazanyiF(f0, f82);
    #else
        return LazanyiF(vec3(0.04), vec3(1.00));
    #endif
}
