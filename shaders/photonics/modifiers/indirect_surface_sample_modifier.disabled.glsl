vec3 modify_indirect_surface_sample(RayResult hit, vec3 sample_rt_pos, vec3 sample_geo_normal,
    int bounce, // The bounce the sample is for, where -1 is the ray from the fragment to `hit`
    inout uint rnd_state
) {
    Light hit_light = ray_result_light_data(hit);
    vec3 light_color = vec3(0.0f);

    if (light_is_valid(hit_light) && hit_light.type == LIGHT_TYPE_NOT_TRACED) {
        light_color = light_sample_at(
            hit_light,
            sample_rt_pos,
            floor(ray_result_position(hit)) + 0.5,
            sample_geo_normal,
            sample_geo_normal);
    }

    return light_color;
}
