#version 430

/*
    -- INPUT VARIABLES --
*/
in vec4 direction_vert_out;

/*
    -- OUTPUT VARIABLES --
*/
layout(location = 0) out vec3 color_frag_out;
layout(location = 1) out float variance_frag_out;

#include "/photonics/common/header.glsl"
#include "/photonics/restir/restir.glsl"

//ph_required: uniform int atrous_iteration;
//ph_required: uniform float near, far;



// 3×3 Gaussian Kernel & Offsets
const float kernel[9] = float[](
    1.0/6., 2.0/3., 1.0/6.,
    2.0/3., 1.0   , 2.0/3.,
    1.0/6., 2.0/3., 1.0/6.
);

const ivec2 offset[9] = ivec2[](
    ivec2(-1, -1), ivec2(0, -1), ivec2(1, -1),
    ivec2(-1,  0), ivec2(0,  0), ivec2(1,  0),
    ivec2(-1,  1), ivec2(0,  1), ivec2(1,  1)
);

// Rec.709 luminance coefficients
const vec3 LUM_COEFF = vec3(0.2126, 0.7152, 0.0722);

float normal_edge_stopping_weight(vec3 center_normal, vec3 sample_normal) {
    const float power = 48.0f;

    return pow(clamp(dot(center_normal, sample_normal), 0.0f, 1.0f), power);
}

float depth_edge_stopping_weight(float center_depth, float sample_depth) {
    const float phi = 0.5f;

    // TODO: paper also uses dz/dx
    // TODO: linear or non-linear depth?
    return exp(-abs(center_depth - sample_depth) / phi);
}

float luma_edge_stopping_weight(float center_luma, float sample_luma, float phi) {
    return exp(-abs(center_luma - sample_luma) / phi);
}

float ph_linearize_depth(float d) {
    return near * far / (far + d * (near - far));
}

#include "/photonics/modifiers/restir_denoiser_depth_fetch_modifier.glsl"

#ifdef PH_RESTIR_DENOISER_DEPTH_FETCH_MODIFIER_DISABLED
    #define PH_DEPTH_MODIFIER(p) p
#else
    #define PH_DEPTH_MODIFIER(p) modify_denoiser_depth_fetch(p)
#endif

void main() {
    if (ph_light_count == 0 || !is_in_world()) {
        color_frag_out = vec3(0f);
        variance_frag_out = 1f;

        return;
    }

    load_fragment_variables(albedo, world_pos, block_normal, normal);
    rt_pos = world_pos - world_offset;
    bad_angle = is_bad_angle(world_pos, block_normal);

    if (atrous_iteration == -1) {
        // Firefly rejection
        //        vec3 center;
        //        vec3 maxNeighbour = vec3(0.0f);
        //        for (int x = -1; x <= 1; x++) {
        //            for (int y = -1; y <= 1; y++) {
        //                vec4 color = texelFetch(radiosity_lighting, pix + ivec2(x, y), 0);
        //
        //                if (x == 0 && y == 0) {
        //                    center = color.xyz;
        //                } else {
        //                    maxNeighbour = max(maxNeighbour, color.xyz);
        //                }
        //            }
        //        }
        //
        //        vec4 color = vec4(min(center, maxNeighbour), 1.0f);
        vec3 color = texelFetch(radiosity_lighting, tex_coord, 0).rgb;
        if (any(isnan(color))) color = vec3(0f); // TODO: Find cause of this nan

        color_frag_out = color;
        variance_frag_out = texelFetch(radiosity_lighting_variance, tex_coord, 0).z;

        return;
    }

    int step_width = 1 << atrous_iteration;

    // Center fetches
    vec3  C0 = texelFetch(prev_denoise_color, tex_coord, 0).rgb;
    float L0 = dot(C0, LUM_COEFF);
    vec3  N0 = ph_decode_normal(texelFetch(radiosity_normal, tex_coord, 0).zw);
    float D0 = ph_linearize_depth( texelFetch(depthtex0, PH_DEPTH_MODIFIER(tex_coord), 0).r );

    float V0 = 0.0f;
    float sumw = 0.0f;
    for (int i = 0; i < 9; ++i) {
        ivec2 p = tex_coord + step_width * offset[i];
        float Vi = texelFetch(prev_denoise_variance, p, 0).x;
        float k   = kernel[i];

        V0 += Vi * k;
        sumw += k;
    }
    V0 /= sumw;

    // TODO: prefilter variance texture using 3x3 gaussian blur
    float pV = 6.0f * sqrt(max(0.0f, V0)) + 1e-10;

    // 2) Bilateral‐style filter with adaptive color weight
    vec3 C_sum = vec3(0.0f);
    float W_sum = 0.0f;
    float V_sum = 0.0f;

    for (int i = 0; i < 9; ++i) {
        ivec2 p  = tex_coord + step_width * offset[i];
        vec3  Ci = texelFetch(prev_denoise_color, p, 0).rgb;
        float Vi = texelFetch(prev_denoise_variance, p, 0).x;
        float Li = dot(Ci.xyz, LUM_COEFF);
        vec3  Ni = ph_decode_normal(texelFetch(radiosity_normal, p, 0).zw);
        float Di = ph_linearize_depth( texelFetch(depthtex0, PH_DEPTH_MODIFIER(tex_coord), 0).x );
        float k  = kernel[i];

        // Color (luminance) weight
        float wC = luma_edge_stopping_weight(L0, Li, pV);

        // Normal weight
        float wN = normal_edge_stopping_weight(N0, Ni);

        // Position weight
        float wP = depth_edge_stopping_weight(D0, Di);

        float w = wC * wN * wP * k;
        W_sum += w;
        C_sum += Ci.xyz * w;
        V_sum += Vi * w * w;
    }

    W_sum = max(0.0001f, W_sum);
    V_sum = max(0.0001f, V_sum);

    color_frag_out = C_sum / W_sum;
    variance_frag_out = max(V_sum / (W_sum * W_sum), 0.0f);
    // TODO: write result of 1st wavelet iteration to color history

    //    if (atrous_iteration == 0) {
    //        float age = texelFetch(denoise.raw, pix, 0).a + 1;
    //        raw_frag_out = vec4(age * color_frag_out, age);
    //    }
}
