#version 430

/*
    -- INPUT VARIABLES --
*/
in vec4 direction_vert_out;

/*
    -- OUTPUT VARIABLES --
*/
layout(location = 2) out vec4 reservoir_frag_out;
layout(location = 3) out vec4 lighting_frag_out;

#ifdef PH_ENABLE_HANDHELD_LIGHT
    layout(location = 5) out vec4 handheld_frag_out;
#endif

#include "/photonics/common/header.glsl"

const float ph_spatial_reuse_radius = PH_RESTIR_SPATIAL_REUSE_RADIUS * PH_RENDER_SCALE;
vec3 ph_sun_direction = ph_signed_nudge(sun_direction);

#include "/photonics/restir/restir.glsl"
#include "/photonics/common/ph_lighting_common.glsl"

void main() {
    if (!is_in_world()) {
        lighting_frag_out = vec4(0f);
        handheld_frag_out = vec4(0f);
        
        return;
    }

    load_fragment_variables(albedo, world_pos, block_normal, normal);
    rt_pos = world_pos - world_offset;
    bad_angle = is_bad_angle(world_pos, block_normal);

    #ifdef PH_ENABLE_HANDHELD_LIGHT
        sample_handheld(handheld_frag_out);
    #endif

    #ifdef PH_ENABLE_GI
        RAY_ITERATION_COUNT = 20;

        // Detect edge
        // TODO: we probably should do fract(2.0f * base_position)
        ivec3 inside = ivec3(lessThan(abs(fract(rt_pos) - 0.5f), vec3(0.48f)));
        bool onEdge = inside.x + inside.y + inside.z <= 1;

        if (!onEdge) sample_indirect();

        RAY_ITERATION_COUNT = 100;
    #endif

    if (ph_light_count == 0) {
        lighting_frag_out = vec4(0f);
        return;
    }

    Reservoir reservoir = reservoir_new();
    vec4 frag = texelFetch(radiosity_reservoirs, tex_coord, 0);

    reservoir_decode(reservoir, frag, rt_pos, false);

    Reservoir temp_reservoir = reservoir_new();

    for (int i = 0; i < PH_RESTIR_SPATIAL_REUSE_SAMPLES; i++) {
        vec2 offset = 2.0 * vec2(rand_next_float(), rand_next_float()) - 1f;
        vec2 uv = tex_coord + offset * ph_spatial_reuse_radius;

        if (!reservoir_reuse(temp_reservoir, uv)) continue;

        reservoir_update(
            reservoir,
            temp_reservoir.light,
            temp_reservoir.light.weight * temp_reservoir.weight * temp_reservoir.samples,
            temp_reservoir.samples
        );
    }

    if (reservoir_is_valid(reservoir)) {
        #ifdef PH_RESTIR_SOFT_SHADOWS
            light_sample_trace_hit(reservoir.light, true);
        #else
            light_sample_trace_hit(reservoir.light, false);
        #endif

        reservoir_compute_weight(reservoir);

        reservoir_frag_out = reservoir_encode(reservoir);
        lighting_frag_out = vec4(reservoir.light.color * reservoir.weight * result_tint_color, 1f);
    } else {
        reservoir_frag_out = reservoir_encode(reservoir);
        lighting_frag_out = vec4(0f);
    }
}