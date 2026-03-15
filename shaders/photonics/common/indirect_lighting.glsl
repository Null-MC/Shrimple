#if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;

    #include "/lib/hsv.glsl"
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif


vec3 sample_cosine_weighted_hemisphere(out float pdf) {
    float x = rand_next_float();

    float r = sqrt(x);
    float phi = 2.0 * PI * rand_next_float();

    vec3 dir;
    dir.x = r * cos(phi);
    dir.y = r * sin(phi);
    dir.z = sqrt(1.0 - x);

    pdf = dir.z / PI;

    return dir;
}

vec3 transform_to_world(const in vec3 normal, const in vec3 local_dir) {
    float sign = step(0.0, normal.z) * 2.0 - 1.0;

    float a = -1.0 / (sign + normal.z);
    float b = normal.x * normal.y * a;
    vec3 tangent = vec3(1.0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x);
    vec3 bitangent = vec3(b, sign + normal.y * normal.y * a, -normal.y);
    mat3 tbn = mat3(tangent, bitangent, normal);

    return tbn * local_dir;
}

vec3 ph_sample_indirect_impl() {
    float pdf;
    vec3 trace_tangentDir = sample_cosine_weighted_hemisphere(pdf);
    vec3 trace_localDir = transform_to_world(normal, trace_tangentDir);

    ray.origin = rt_pos + 0.1 * block_normal;
    ray.direction = trace_localDir;

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

        #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
            vec3 hitTracePos = hitLocalPos + rt_camera_position
                + 0.08 * hitLocalNormal;

            // sample random block light
            int binStart = load_light_offset(hitTracePos);
            int binCount = light_registry_array[binStart];

            if (binCount > 0) {
                int i = (frameCounter) % binCount + (binStart+1);
                Light light = load_light(light_registry_array[i]);

                vec3 lightOffset = light.position - hitTracePos;
                float lightDist = length(lightOffset);
                vec3 lightDir = lightOffset / lightDist;

                vec3 lightColor = vec3(1.0);//6.0 * RGBToLinear(light.color);

                float NoLm = max(dot(hitLocalNormal, lightDir), 0.0);
                float distance_squared = lengthSq(lightOffset) * light.falloff;
                float att = 1.0 / dot(vec2(1.0, distance_squared), light.attenuation);

                ray.origin = hitTracePos;
                ray.direction = lightDir;

                breakOnEmpty=true;
                trace_ray(ray, true);
                breakOnEmpty=false;

                if (ray.result_hit) {
                    lightColor *= result_tint_color;

                    if (lengthSq(hitTracePos - ray.result_position) < _pow2(lightDist) && floor(light.position) != floor(ray.result_position)) {
                        att = 0.0;
                    }
                }

                sample_color += att * NoLm * lightColor;
            }
        #elif defined(LIGHTING_COLORED)
            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
            sample_color += SampleFloodFill(samplePos) * 3.0;
        #endif

        indirect_color += sample_color * hitAlbedo;
    }

    return indirect_color * tint;
}
