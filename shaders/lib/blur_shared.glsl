void copyToShared(in ivec2 uv, const in int i_shared) {
    if (i_shared >= sharedSize) return;

    uv = clamp(uv, ivec2(0), ivec2(viewSize)-1);

    sharedColor[i_shared] = texelFetch(TEX_SOURCE, uv, 0).rgb;
}

vec3 SampleBlur(const in int base_i) {
    const float sigma_xy = 7.0;

    float weight_max = gaussian(sigma_xy, 0);
    vec3 color = sharedColor[base_i] * weight_max;

    for (int i = 1; i <= 16; i++) {
        float f_xy = gaussian(sigma_xy, i);
        //float f_z = gaussian(sigma_z, abs(center_depth - sample_depth));
        float sample_weight = f_xy;// * f_z;

//        float sample_depth = sharedDepth[base_i + i];
        color += sharedColor[base_i - i] * sample_weight;
        color += sharedColor[base_i + i] * sample_weight;

        weight_max += sample_weight*2.0;
    }

    color /= weight_max;

    return color;
}
