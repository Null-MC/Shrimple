#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

#if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
    uniform sampler3D texFloodFill;
#endif

uniform vec3 shadowLightPosition;
uniform float cloudHeight;
uniform float cloudTime;

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    #include "/lib/vanilla-light.glsl"
#endif

#if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif


vec3 sample_cosine_weighted_hemisphere() {
    vec2 u = vec2(rand_next_float(), rand_next_float());
    float r = sqrt(u.x);
    float theta = 6.28318530718 * u.y;

    return vec3(r * cos(theta), r * sin(theta), sqrt(max(0.0, 1.0 - u.x)));
}

vec3 transform_to_world(const in vec3 normal, const in vec3 local_dir) {
    vec3 up = abs(normal.z) < 0.999
        ? vec3(0.0, 0.0, 1.0)
        : vec3(1.0, 0.0, 0.0);

    vec3 tangent = normalize(cross(up, normal));
    vec3 bitangent = cross(normal, tangent);

    return mat3(tangent, bitangent, normal) * local_dir;
}

vec3 ph_sample_indirect_impl() {
    vec3 trace_tangentDir = sample_cosine_weighted_hemisphere();
    vec3 trace_localDir = transform_to_world(normal, trace_tangentDir);
    lightEmittance = vec3(0.0);

    ray.origin = rt_pos + 0.1 * block_normal;
    ray.direction = trace_localDir;

    RAY_ITERATION_COUNT = 100;
    breakOnEmpty = true;
    trace_ray(ray, true);
    breakOnEmpty = false;

    vec3 indirect_color;
    vec3 tint = result_tint_color;

    if (!ray.result_hit && !ray_iteration_bound_reached) {
        #ifdef PHOTONICS_GI_ENABLED
            // hit sky
            ivec2 uv = ivec2(gl_FragCoord.xy);
            vec3 worldPos = rt_pos + world_offset;
            indirect_color = get_sky_color(uv, worldPos, ray.direction);
        #endif
    }
    else {
        vec3 hitAlbedo = ray.result_color;
        vec3 hitLocalPos = ray.result_position - rt_camera_position;
        vec3 hitLocalNormal = ray.result_normal;
        vec3 hitEmission = 8.0 * lightEmittance;

//        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
//            hitAlbedo /= PI;
//        #endif

        vec3 sample_color = vec3(0.0);

        #ifdef PHOTONICS_GI_ENABLED
            vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

            #ifdef SHADOWS_ENABLED
                // trace sun
                ray.origin = ray.result_position + 0.1 * ray.result_normal;
                ray.direction = localSkyLightDir;

                RAY_ITERATION_COUNT = 100;
                breakOnEmpty = true;
                trace_ray(ray, true);
                breakOnEmpty = false;

                if (!ray.result_hit && !ray_iteration_bound_reached) {
                    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                        vec3 skyLightColor = GetSkyLightColor(hitLocalPos, sunLocalDir.y, abs(sunLocalDir.y));
                    #else
                        vec3 skyLightColor = RGBToLinear(texture(texLightmap, LightMapTex(vec2(0.0, 1.0))).rgb);
                    #endif
                    sample_color += skyLightColor * result_tint_color;

                    #ifdef SHADOW_CLOUDS
                        float cloudShadow = SampleCloudShadow(hitLocalPos, localSkyLightDir);
                        sample_color *= cloudShadow * 0.5 + 0.5;
                    #endif
                }
            #else
                #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
                    float hitSkyLevel = saturate(get_result_sky_light(hitLocalNormal) / 15.0);
//                    hitSkyLevel = _pow3(hitSkyLevel);
                    vec3 lmcolor = texture(texLightmap, LightMapTex(vec2(0.0, hitSkyLevel))).rgb;

                    float oldLighting = GetOldLighting(hitLocalNormal);
                    sample_color += oldLighting * RGBToLinear(lmcolor);
                #endif
            #endif

            // other lighting

            #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
                #if PHOTONICS_GI_BLOCK_SAMPLES > 0
                    vec3 hitTracePos = hitLocalPos + rt_camera_position
                        + 0.08 * hitLocalNormal;

                    // sample random block light
                    int binStart = load_light_offset(hitTracePos);
                    int binCount = light_registry_array[binStart];

                    if (binCount > 0) {
                        int sample_count = min(binCount, PHOTONICS_GI_BLOCK_SAMPLES);
                        float sample_scale = float(binCount) / float(sample_count);

                        for (int i = 0; i < PHOTONICS_GI_BLOCK_SAMPLES; i++) {
                            if (i > binCount) break;

                            int k = ((frameCounter + i*8) % binCount) + (binStart+1);
                            Light light = load_light(light_registry_array[k]);

                            vec3 lightOffset = light.position - hitTracePos;

                            // TODO: can't use this because it includes specular now
    //                        vec3 shit = modify_attenuation(light, lightOffset, hitTracePos, hitTracePos, hitLocalNormal, hitLocalNormal) * sample_scale;

                            float distSq = dot(lightOffset, lightOffset);
                            float invDist = inversesqrt(distSq);
                            vec3 lightDir = lightOffset * invDist;
                            float lightDist = distSq * invDist;

                            float NoLm = max(dot(hitLocalNormal, lightDir), 0.0);
                            if (NoLm < EPSILON) continue;

                            vec3 lightColor = light.color * sample_scale;

                            #ifdef PHOTONICS_SHRIMPLE_COLORS
                                const float lightRadius = 0.5;
                                float att = GetLightAttenuation(lightDist, light.block_radius, lightRadius);
                            #else
                                float distance_squared = dot(lightOffset, lightOffset) * light.falloff;
                                float att = 1.0 / dot(vec2(1.0, distance_squared), light.attenuation);
                            #endif

                            if (att < EPSILON) continue;

                            ray.origin = hitTracePos;
                            ray.direction = lightDir;

                            RAY_ITERATION_COUNT = 20;
                            breakOnEmpty=true;
                            trace_ray(ray, true);
                            breakOnEmpty=false;

                            if (ray.result_hit) {
                                lightColor *= result_tint_color;

                                if (lengthSq(hitTracePos - ray.result_position) < distSq * 0.98 && floor(light.position) != floor(ray.result_position)) {
                                    att = 0.0;
                                }
                            }

                            sample_color += att * NoLm * lightColor;
                            // TODO: apply NoV?
                        }
                    }
                #endif
            #elif defined(LIGHTING_COLORED)
                vec3 voxelPos = GetVoxelPosition(hitLocalPos);
                vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
                sample_color += SampleFloodFill(samplePos);
            #endif
        #endif

        sample_color += hitEmission;

        indirect_color += hitAlbedo * sample_color;
    }

    return trace_tangentDir.z * indirect_color * tint;
}
