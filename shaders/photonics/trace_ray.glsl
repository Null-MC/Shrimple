bool trace_ray(inout RayIterator ray, inout RayResult hit, inout vec3 tint) {
    #ifdef PHOTONICS_BLOCK_TINT_ENABLED
        bool is_hit = false;

        while (ray_iter_has_next(ray) && !is_hit) {
            hit = ray_iter_next(ray);

            if (!ray_iter_is_in_bounds(ray)) {
                break;
            }
            else if (ray_result_is_transparent(hit)) {
                // do transparency stuff
                VoxelData trace_voxel_data = ray_result_voxel_data(hit);
                vec4 trace_albedo = voxel_data_albedo(trace_voxel_data);
                trace_albedo.rgb = RGBToLinear(trace_albedo.rgb);

                trace_albedo.rgb = mix(vec3(1.0), trace_albedo.rgb, trace_albedo.a);
                tint *= normalize(trace_albedo.rgb + EPSILON) * (1.0 - trace_albedo.a);

                ray_iter_skip_block(ray);
            }
            else if (ray_result_is_hit(hit)) {
                is_hit = true;
            }
        }

        return is_hit;
    #else
        hit = ray_iter_next(ray);
        return ray_iter_is_in_bounds(ray) && ray_result_is_hit(hit);
    #endif
}
