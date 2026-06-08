#ifndef PH_SHARED_INCLUDE
#define PH_SHARED_INCLUDE

#include "/photonics/utility/color.glsl"

#include "/photonics/rendering/restir/direct/reservoir.glsl"
#include "/photonics/rendering/restir/indirect/reservoir.glsl"

#include "/photonics/utility/projection.glsl"
#include "/photonics/utility/normal_encoding.glsl"

#define RESTIR_LIGHTING_OUT 0
#define RESTIR_LIGHTING_VARIANCE_OUT 1
#define RESTIR_LIGHTING_SAMPLES_OUT 2

//ph_required: uniform sampler2D restir_position_history;
//ph_required: uniform sampler2D restir_normal_history;

//ph_required: uniform sampler2D prev_restir_position_history;
//ph_required: uniform sampler2D prev_restir_normal_history;

//ph_required: uniform sampler2D restir_lighting;
//ph_required: uniform sampler2D restir_lighting_variance;
//ph_required: uniform sampler2D restir_lighting_samples;

//ph_required: uniform sampler2D prev_restir_lighting;
//ph_required: uniform sampler2D prev_restir_lighting_variance;

struct SampleHistory {
    vec4 lighting;
    vec4 variance;
};

const SampleHistory NULL_HISTORY = SampleHistory(vec4(-999), vec4(-999));

bool sample_history_isnull(SampleHistory s1) {
    return s1.lighting.w < 0.0;
}

void sample_history_load(out SampleHistory smple) {
    smple.lighting = texelFetch(restir_lighting, frag_tex_coord, 0),
    smple.variance = vec4(0f);
}

SampleHistory sample_history_mix(SampleHistory s1, SampleHistory s2, float a) {
    if (sample_history_isnull(s1)) {
        a = 1f;
    } else if (sample_history_isnull(s2)) {
        a = 0f;
    } else if (sample_history_isnull(s1) && sample_history_isnull(s2)) {
        return NULL_HISTORY;
    }

    return SampleHistory(
        mix(s1.lighting, s2.lighting, a),
        mix(s1.variance, s2.variance, a)
    );
}

// SampleHistory sample_history_reproject_single(ivec2 texel, vec3 previous_player_pos) {
//     if (!frag_is_bad_angle) {
//         vec3 projected_player_pos = texelFetch(prev_restir_position_history, texel, 0).xyz;
//         vec3 d = projected_player_pos - previous_player_pos;
//         if (dot(d, d) > 0.1f) return NULL_HISTORY;
//     }

//     vec3 n = ph_decode_normal(texelFetch(prev_restir_normal_history, texel, 0).xy);
//     if (dot(n, frag_geo_normal) < 0.99f) return NULL_HISTORY;

//     vec4 lighting = texelFetch(prev_restir_lighting, ivec2(texel), 0);
//     if (any(isnan(lighting))) return NULL_HISTORY;

//     vec4 variance = texelFetch(prev_restir_lighting_variance, ivec2(texel), 0);
//     if (any(isnan(variance))) return NULL_HISTORY;

//     return SampleHistory(lighting, variance);
// }
SampleHistory sample_history_reproject_single(ivec2 texel, vec3 previous_player_pos) {
    if (frag_is_bad_angle) return NULL_HISTORY;

    // 1. Check position immediately using inline math
    // Reuses the position vec3 memory for the difference calculation
    vec3 projected_player_pos = texelFetch(prev_restir_position_history, texel, 0).xyz - previous_player_pos;
    if (dot(projected_player_pos, projected_player_pos) > 0.1f) return NULL_HISTORY;

    // 2. Decode and check normal immediately to free up register
    vec3 n = ph_decode_normal(texelFetch(prev_restir_normal_history, texel, 0).xy);
    if (dot(n, frag_geo_normal) < 0.99f) return NULL_HISTORY;

    // 3. Fetch lighting and check for NaN
    vec4 lighting = texelFetch(prev_restir_lighting, texel, 0);
    if (any(isnan(lighting))) return NULL_HISTORY;

    // 4. Fetch variance last so it does not sit in a register early
    vec4 variance = texelFetch(prev_restir_lighting_variance, texel, 0);
    if (any(isnan(variance))) return NULL_HISTORY;

    return SampleHistory(lighting, variance);
}

// SampleHistory sample_history_reproject_mixed(vec2 center, vec3 previous_player_pos) {
//     ivec2 icenter = ivec2(center);

//     SampleHistory c_00 = sample_history_reproject_single(icenter + ivec2(0, 0), previous_player_pos);
//     SampleHistory c_10 = sample_history_reproject_single(icenter + ivec2(1, 0), previous_player_pos);
//     SampleHistory c_01 = sample_history_reproject_single(icenter + ivec2(0, 1), previous_player_pos);
//     SampleHistory c_11 = sample_history_reproject_single(icenter + ivec2(1, 1), previous_player_pos);

//     SampleHistory result = sample_history_mix(
//         sample_history_mix(c_00, c_10, fract(center.x)),
//         sample_history_mix(c_01, c_11, fract(center.x)),
//         fract(center.y)
//     );

//     if (result == NULL_HISTORY)
//         return SampleHistory(vec4(0.0f), vec4(0.0f));

//     return result;
// }
SampleHistory sample_history_reproject_mixed(vec2 center, vec3 previous_player_pos) {
    ivec2 icenter = ivec2(center);
    vec2 f = fract(center); // Calculate fractions once to save registers

    // 1. Fetch and mix the bottom two texels (X direction)
    SampleHistory mix_bottom = sample_history_reproject_single(icenter, previous_player_pos);
    SampleHistory temp = sample_history_reproject_single(icenter + ivec2(1, 0), previous_player_pos);
    mix_bottom = sample_history_mix(mix_bottom, temp, f.x);

    // 2. Fetch and mix the top two texels (X direction) using the same temp register
    SampleHistory mix_top = sample_history_reproject_single(icenter + ivec2(0, 1), previous_player_pos);
    temp = sample_history_reproject_single(icenter + ivec2(1, 1), previous_player_pos);
    mix_top = sample_history_mix(mix_top, temp, f.x);

    // 3. Final mix in the Y direction
    SampleHistory result = sample_history_mix(mix_bottom, mix_top, f.y);

    // 4. Clean up invalid results
    if (sample_history_isnull(result))
        result = SampleHistory(vec4(0.0f), vec4(0.0f));

    return result;
}

void sample_history_reproject(out SampleHistory smple) {
    vec3 previous_player_pos;
    vec2 center = (ph_reproject_player_pos(
        frag_player_pos,
        frag_is_hand,
        get_taa_jitter(),
        previous_player_pos
    ).xy * PH_VIEW_SIZE) - 0.5f;

    smple = sample_history_reproject_mixed(center, previous_player_pos);
}

void sample_history_combine_lighting(inout SampleHistory history, in SampleHistory smple) {
#if PH_RESTIR_DENOISER_PASSES != 0
    history.lighting.w = min(history.lighting.w, PH_RESTIR_ACCUMULATION_FRAMES);
    history.lighting.rgb = mix(history.lighting.rgb, smple.lighting.rgb, 1f / (++history.lighting.w));
#else
    if (history.lighting.a >= PH_RESTIR_ACCUMULATION_FRAMES - 1f)
        history.lighting *= ((PH_RESTIR_ACCUMULATION_FRAMES - 1f) / history.lighting.a);

    history.lighting.rgb+= smple.lighting.rgb;
    history.lighting.a++;
#endif
}

void sample_history_combine_moment(inout SampleHistory history, in SampleHistory smple) {
    float moment_alpha = 1f / history.lighting.a;
    vec2 moments = vec2(0f);

    moments.x = dot(smple.lighting.rgb, vec3(0.299, 0.587, 0.114));
    moments.y = moments.x * moments.x;

    history.variance.xy = mix(history.variance.xy, moments, moment_alpha);
    history.variance.w = 1f;
}

void sample_history_compute_variance(inout SampleHistory history, in SampleHistory smple) {
#if PH_RESTIR_ACCUMULATION_FRAMES < 4
    #define PH_MIN_VARIANCE 1f
#else
    #define PH_MIN_VARIANCE (samples < 4f) ? 10f : 0
#endif

    float samples = history.lighting.a;
    float sample_variance = max(
        history.variance.y - (history.variance.x * history.variance.x),

        // With few samples, variance estimate is unreliable — use a high floor
        PH_MIN_VARIANCE
    );

    history.variance.z = sample_variance / samples;
}

#endif
