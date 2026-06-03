bool trace_light_vis(
    vec3 rt_pos,
    vec3 direction,
    vec3 light_rt_pos,
    int max_iterations,
    out vec3 tint_color,
    out float light_transmittance
) {
    RayIterator ray;
    ray_iter_begin(ray, rt_pos, direction);

    light_transmittance = 1.0f;

    #ifdef PHOTONICS_BLOCK_TINT_ENABLED
        RayResult result = missed_ray_result();
        vec4 running_tint_color = vec4(0.0f);

        while (ray_iter_has_next_block(ray, light_rt_pos)) {
            result = ray_iter_next_block(ray, light_rt_pos);

            if (ray_result_is_transparent(result)) {
                VoxelData voxel_data = ray_result_voxel_data(result);
                vec4 albedo = voxel_data_albedo(voxel_data);

                light_transmittance *= 1.0f - albedo.a;
                ray_iter_apply_transparency(running_tint_color, albedo);
                ray_iter_skip_block(ray);

                continue;
            }

            break;
        }
    #else
        RayResult result = ray_iter_next_block(ray, light_rt_pos);
    #endif

    if (!ray_result_is_hit(result)) return false;
    if (floor(ray_result_position(result)) != floor(light_rt_pos)) return false;

    #ifdef PHOTONICS_BLOCK_TINT_ENABLED
        tint_color = running_tint_color.a == 0.0f ? vec3(1.0f) : running_tint_color.rgb;
    #else
        tint_color = vec3(1.0f);
    #endif

    return true;
}