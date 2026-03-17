#version 430

/*
    -- INPUT VARIABLES --
*/
in vec4 direction_vert_out;

/*
    -- OUTPUT VARIABLES --
*/
layout(location = 0) out vec4 position_frag_out;
layout(location = 1) out vec4 normal_frag_out;

#ifdef PH_ENABLE_BLOCKLIGHT
    layout(location = 2) out vec4 direct_frag_out;
    layout(location = 3) out vec4 direct_soft_frag_out;
#endif

#ifdef PH_ENABLE_HANDHELD_LIGHT
    layout(location = 4) out vec4 handheld_frag_out;
#endif

struct Frag {
    vec4 direct;
    vec4 direct_soft;
};

const Frag NULL4 = Frag(vec4(-999), vec4(-999));

#include "/photonics/common/header.glsl"

vec3 ph_sun_direction = ph_signed_nudge(sun_direction);

#include "/photonics/common/ph_lighting_common.glsl"


vec3 ph_sample_direct_lighting(vec3 position, vec3 normal, vec3 mapped_normal, Light light) {
    ray.origin = position + ray_local_offset + normal * ray_normal_scale;

    vec3 to_light = light.position - ray.origin;
    float lightDist = length(to_light);
    ray.direction = to_light / lightDist;

    // light attenuation
    #ifdef PHOTONICS_SHRIMPLE_COLORS
        const float lightRadius = 0.5;
        light.color *= GetLightAttenuation_Diffuse(lightDist, light.block_radius, lightRadius);
    #else
        float distance_squared = dot(to_light, to_light) * light.falloff;
        light.color /= dot(vec2(1.0, distance_squared), light.attenuation);
    #endif

    if (floor(light.position) == floor(position)) {
        return light.color;
    }

    if (dot(ray.direction, normal) <= 0.01f) {
        return vec3(0.0f);
    }

    float cosine = clamp(dot(mapped_normal, ray.direction) * 2.0, 0.0, 1.0);
    light.color *= cosine;
    if (ph_luminance(light.color) < 0.001) {
        return vec3(0.0f);
    }

    ray_target = ivec3(light.position);
    RAY_ITERATION_COUNT = 20;
    trace_ray(ray, true);
    RAY_ITERATION_COUNT = 100;

    if (!ray.result_hit && light.attenuation.y == 0.0f) {
        light.color = vec3(0f);
    }

    if (floor(light.position) != floor(ray.result_position)) {
        light.color = vec3(0f);
    }

    light.color *= result_tint_color;

    return light.color;
}

void ph_process_direct(inout Frag frag, int light_offset, int light_count, int soft_light_count) {
    for (; frag.direct.w < light_count - soft_light_count; frag.direct.w++) {
        int index = light_registry_array[soft_light_count + int(frag.direct.w) + light_offset + 1];
        Light light = load_light(index);
        frag.direct.xyz += ph_sample_direct_lighting(rt_pos, block_normal, normal, light);
    }

    for (int i = 0; i < soft_light_count; i++) {
        int index = light_registry_array[(int(frag.direct_soft.w) % soft_light_count) + light_offset + 1];
        Light light = load_light(index);
        jitter_sample_position(light.position);
        frag.direct_soft.xyz += soft_light_count * ph_sample_direct_lighting(rt_pos, block_normal, normal, light);
        frag.direct_soft.w++;
    }
}

Frag ph_mixNullable4(Frag s1, Frag s2, float a) {
    if (s1 == NULL4) {
        a = 1.0f;
    } else if (s2 == NULL4) {
        a = 0.0f;
    }

    vec4 direct = mix(s1.direct, s2.direct, a);
    vec4 direct_soft = mix(s1.direct_soft, s2.direct_soft, a);

    return Frag(direct, direct_soft);
}

Frag ph_get(vec2 uv) {
    vec3 d = texelFetch(prev_radiosity_position, ivec2(uv), 0).xyz - world_pos;
    if (dot(d, d) >= 0.1f) {
        return NULL4;
    }

    vec3 n = texelFetch(prev_radiosity_normal, ivec2(uv), 0).xyz;
    if (dot(n, block_normal) < 0.99f) {
        return NULL4;
    }

    vec4 direct = texelFetch(prev_radiosity_direct, ivec2(uv), 0);
    vec4 direct_soft = texelFetch(prev_radiosity_direct_soft, ivec2(uv), 0);

    return Frag(direct, direct_soft);
}

Frag ph_get_mixed(vec2 center) {
    ivec2 icenter = ivec2(center);

    Frag c_00 = ph_get(icenter + ivec2(0, 0));
    Frag c_10 = ph_get(icenter + ivec2(1, 0));
    Frag c_01 = ph_get(icenter + ivec2(0, 1));
    Frag c_11 = ph_get(icenter + ivec2(1, 1));

    Frag frag = ph_mixNullable4(
        ph_mixNullable4(c_00, c_10, fract(center.x)),
        ph_mixNullable4(c_01, c_11, fract(center.x)),
        fract(center.y)
    );

    return frag;
}

// TODO: reproject in voxel pattern to hide noise in texture
void sample_direct() {
    vec2 center = ph_reprojectf(previous_modelview_projection, world_pos + 0.01f * block_normal, vec2(viewWidth, viewHeight), get_taa_jitter());

    center -= 0.5f;
    Frag frag = ph_get_mixed(center);

    if (frag == NULL4 || rand_next_float() > 0.995f) {
        frag.direct = vec4(0.0f);
        frag.direct_soft = vec4(0.0f);
    }

    // direct light
    int light_offset = load_light_offset(rt_pos);

    int light_count = light_registry_array[light_offset];
    int soft_light_count = min(3, light_count);

    ph_process_direct(frag, light_offset, light_count, soft_light_count);

    #ifdef PH_ENABLE_BLOCKLIGHT
        frag.direct.w = max(frag.direct.w, 0.01f);
        direct_frag_out = frag.direct;
        frag.direct_soft.w = max(frag.direct_soft.w, 0.01f);
        direct_soft_frag_out = frag.direct_soft;
    #endif
}

void main() {
    if (!is_in_world()) {
        #ifdef PH_ENABLE_BLOCKLIGHT
            direct_frag_out = vec4(0f);
            direct_soft_frag_out = vec4(0f, 0f, 0f, 1f);
        #endif

        #ifdef PH_ENABLE_HANDHELD_LIGHT
            handheld_frag_out = vec4(0f);
        #endif

        return;
    }

    load_fragment_variables(albedo, world_pos, block_normal, normal);
    rt_pos = world_pos - world_offset;
    bad_angle = is_bad_angle(world_pos, block_normal);

    position_frag_out = vec4(world_pos, 1f);
    normal_frag_out = vec4(block_normal, 1f);

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

    #ifdef PH_ENABLE_BLOCKLIGHT
        if (ph_light_count == 0) {
            direct_frag_out = vec4(0f);
            direct_soft_frag_out = vec4(0f, 0f, 0f, 1f);
            return;
        }

        sample_direct();
    #endif
}
