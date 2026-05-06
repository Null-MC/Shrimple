void copyToShared(in ivec2 uv, const in int i_shared) {
    if (i_shared >= sharedSize) return;

    uv = clamp(uv, ivec2(0), ivec2(viewSize)-1);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    #ifdef LOD_ENABLED
        depth = near / depth;
    #else
        depth = linearizeDepth(fma(depth, 2.0, -1.0), nearPlane, farPlane);
    #endif

    sharedDepth[i_shared] = depth;
    sharedColor[i_shared] = texelFetch(TEX_SOURCE, uv, 0).rgb;
}

vec3 SampleBlur(const in float center_depth, const in int base_i) {
    float rate = isEyeInWater == 1 ? 0.40 : 0.05;
    float radius = 4.0;//clamp(center_depth * rate, 0.0, 16.0);
    const float sigma_xy = 5.0;

    float radius_max = int(ceil(radius));

    float weight_max = gaussian(sigma_xy, 0);
    vec3 color = sharedColor[base_i] * weight_max;

    for (int i = 1; i <= radius_max; i++) {
        float f_xy = gaussian(sigma_xy, i);
        //float f_z = gaussian(sigma_z, abs(center_depth - sample_depth));
        float sample_weight = f_xy;// * f_z;

        float sample_depth = sharedDepth[base_i + i];
        color += sharedColor[base_i - i] * sample_weight;
        color += sharedColor[base_i + i] * sample_weight;

        weight_max += sample_weight;
    }

    color /= weight_max;

    // TODO: mix with non-blurred if radius < 1.0

    return color;
}
