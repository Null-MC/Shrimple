#include "/photonics/photonics.glsl"
#include "/photonics/common/util.glsl"

void sample_handheld(out vec4 color) {
    if (any(notEqual(handheld_color, vec3(0.0f)))) {
        vec4 direction_vert_out = direction_transformation_matrix_in * vec4(left_handed ? 1.0f : -1.0f, -1.0f, 0.0f, 1.0f);
        direction_vert_out.w = 1.0f / direction_vert_out.w;
        direction_vert_out.xyz *= direction_vert_out.w;

        ray.origin = direction_vert_out.xyz + rt_camera_position - relativeEyePosition;
        //                light_ray.origin.y = rt_camera_position.y - 0.5f;

        vec3 to_light = rt_pos - ray.origin;
        ray.direction = normalize(to_light);
        trace_ray(ray, true); // TODO: early terminate, if ray is too far away anyway

        float distance_squared = dot(to_light, to_light);
        float brightness = 2.1f / dot(vec2(1, distance_squared), vec2(0.9f, 0.1f));
        brightness = max(brightness, 0.02f);

        float hand_to_base_distance = distance(ray.origin, rt_pos);
        float hand_to_result_distance = distance(ray.origin, ray.result_position);
        brightness *= clamp(30.0f * (hand_to_result_distance - hand_to_base_distance + 0.05f), 0.0f, 1.0f);

        brightness *= dot(normal, -ray.direction);

        brightness *= (ph_h(frameCounter / 300.0f) * 0.1f + ph_h(frameCounter / 100.0f) * 0.05f) + 0.4f;

        color.xyz = brightness * handheld_color;
    } else {
        color.xyz = vec3(0.0f);
    }
}

// TODO: take sun light into account
vec3 ph_sample_indirect_impl() {
    ray.result_position = rt_pos;
    ray.result_normal = block_normal;

    //    bool is_axis_aligned = is_axis_aligned(base_normal);

    // If normal is not axis aligned, sample both hemispheres
    //    if (!is_axis_aligned) {
    //        light_ray.result_normal = vec3(0.0f);
    //    }

    vec3 indirect_color = vec3(1.0f);

    for (int i = 0; i < 2; i++) {
        lightEmittance = vec3(0.0f);
        ray.origin = ray.result_position + 0.1f * ray.result_normal;
        // TODO: use blue noise
        ray.direction = normalize(ray.result_normal + ph_sample_random_direction(rng_state));

        bool sun = ph_RandomFloat01(rng_state) < 0.25f && dot(ph_sun_direction, ray.result_normal) > 0.707f;
        if (sun) {
            ray.direction = ph_sun_direction;
        }

        breakOnEmpty = true;
        trace_ray(ray, true);
        breakOnEmpty = false;

        indirect_color *= result_tint_color;
        if (!ray.result_hit && !ray_iteration_bound_reached) {
//            if (!sun) {
//                indirect_color *= (float(i > 0) * 2 + 2) * indirect_light_color;
//            } else {
//                indirect_color *= (float(i > 0) * 15 + 1) * indirect_light_color;
//            }

            indirect_color *= indirect_light_color;

            return indirect_color;
        } else if (dot(lightEmittance, lightEmittance) > 0.0f) {
            indirect_color *= 2.0f * lightEmittance;
            //            indirect_color = vec3(0.0f);

            return indirect_color;
        }

        indirect_color *= ray.result_color;
    }

    return vec3(0.0f);
}

void sample_indirect() {
    vec3 sample_position = world_pos;
    ivec3 write = ph_write(sample_position, block_normal, modelview_projection, world_camera_position);

    uint w = imageAtomicAdd(gi_w, write, uint(1));
    if (w == 0) {
        ivec3 read = ph_read(sample_position, block_normal, previous_modelview_projection, previous_world_camera_position);

        vec4 result = vec4(0.0f);
        result.x += imageLoad(gi_x, read).x / 255.0f;
        result.y += imageLoad(gi_y, read).x / 255.0f;
        result.z += imageLoad(gi_z, read).x / 255.0f;
        result.w = imageLoad(gi_w, read).x;

        result *= 0.975f; // exponential decay

        imageAtomicAdd(gi_x, write, uint(result.x * 255.0f));
        imageAtomicAdd(gi_y, write, uint(result.y * 255.0f));
        imageAtomicAdd(gi_z, write, uint(result.z * 255.0f));
        imageAtomicAdd(gi_w, write, uint(result.w));
    } else if (w < 2048) {
        vec3 result = ph_sample_indirect_impl();

        imageAtomicAdd(gi_x, write, uint(result.x * 255.0f));
        imageAtomicAdd(gi_y, write, uint(result.y * 255.0f));
        imageAtomicAdd(gi_z, write, uint(result.z * 255.0f));
    } else {
        imageAtomicAdd(gi_w, write, uint(-1));
    }
}