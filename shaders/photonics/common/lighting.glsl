#include "/photonics/photonics.glsl"
#include "/photonics/common/util.glsl"

#if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
    #ifdef LIGHTING_COLORED
        uniform sampler3D texFloodFillA;
        uniform sampler3D texFloodFillB;
    #endif

    #include "/lib/hsv.glsl"
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

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

vec3 ph_sample_indirect_impl() {
    ray.origin = rt_pos + 0.1 * block_normal;
    ray.direction = normalize(normal + ph_sample_random_direction(rng_state));

    breakOnEmpty = true;
    trace_ray(ray, true);
    breakOnEmpty = false;

    vec3 indirect_color;
    vec3 tint = result_tint_color;

    if (!ray.result_hit && !ray_iteration_bound_reached) {
        // hit sky
        ivec2 uv = ivec2(gl_FragCoord.xy);
        vec3 worldPos = rt_pos + world_offset;
        indirect_color = get_sky_color(uv, worldPos, ray.direction);
    }
    else {
        vec3 hitAlbedo = RGBToLinear(ray.result_color);
        vec3 hitLocalPos = ray.result_position - rt_camera_position;
        vec3 hitLocalNormal = ray.result_normal;

        // trace sun
        ray.origin = ray.result_position;
        ray.direction = ph_sun_direction;

        breakOnEmpty = true;
        trace_ray(ray, true);
        breakOnEmpty = false;

        vec3 sample_color = vec3(0.0);

        if (!ray.result_hit && !ray_iteration_bound_reached) {
            sample_color += indirect_light_color * result_tint_color;
        }

        // other lighting
        // TODO: support block light trace?

        #if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
            sample_color += SampleFloodFill(samplePos) * 3.0;
        #endif

        indirect_color += sample_color * hitAlbedo;
    }

    return indirect_color * tint;
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