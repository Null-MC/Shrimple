#define PH_MAX_GI_ITERATIONS 100

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

#if !defined(PHOTONICS_BLOCK_LIGHT_ENABLED) && defined(LIGHTING_COLORED)
    uniform sampler3D texFloodFill;
#endif

uniform float rainStrength;
uniform vec3 eyePosition;
uniform float cloudHeight;
uniform float cloudTime;

#include "/photonics/interface/lighting_interface.glsl"
#include "/photonics/tracing.glsl"
#include "/photonics/utility/random.glsl"

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #include "/lib/sky-irradiance.glsl"
#endif

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

#include "/photonics/modifiers/indirect_surface_sample_modifier.glsl"
#include "/photonics/trace_ray.glsl"


vec3 sample_cosine_weighted_hemisphere(inout uint rnd_state) {
    vec2 u = vec2(
        ph_rand_next_float(rnd_state),
        ph_rand_next_float(rnd_state));

    float r = sqrt(u.x);
    float theta = (2.0 * PI) * u.y;

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

void sample_indirect(inout vec3 indirect_color, vec3 sample_rt_pos, vec3 geo_normal, vec3 tex_normal, inout uint rnd_state,
    out vec3 first_hit, out vec3 first_normal) {

//    vec3 trace_tangentDir = sample_cosine_weighted_hemisphere(rnd_state);
//    vec3 trace_localDir = transform_to_world(tex_normal, trace_tangentDir);
    vec3 trace_localDir = ph_rand_direction(rnd_state, tex_normal);
//    lightEmittance = vec3(0.0); // TODO: dont think this is set anymore

    RayIterator ray;
    ray.iterations = PH_MAX_GI_ITERATIONS;
    ray_iter_set_position(ray, sample_rt_pos);
    ray_iter_set_direction(ray, trace_localDir);
    ray_iter_offset_position(ray, 0.1 * geo_normal);

    RayResult hit;
    vec3 tint = vec3(1.0);
    bool is_hit = trace_ray(ray, hit, tint);

    vec3 final_color = vec3(0.0);

    if (!is_hit) {
        #ifdef PHOTONICS_GI_ENABLED
            // hit sky
            vec3 playerPos = sample_rt_pos - rt_camera_position;
            final_color = get_sky_color(playerPos, trace_localDir) * 2.0;
        #endif

        first_hit = vec3(-1.0);
    }
    else {
        VoxelData voxel_data = ray_result_voxel_data(hit);
        vec3 hit_albedo = voxel_data_albedo(voxel_data).rgb;
        hit_albedo = RGBToLinear(hit_albedo);

        vec3 hit_position = ray_result_position(hit);
        vec3 hit_localPos = hit_position - rt_camera_position;
        vec3 hit_localNormal = ray_result_normal(hit);

        first_hit = hit_position;
        first_normal = hit_localNormal;

        // TODO
        vec3 hit_emission = vec3(0.0); //8.0 * lightEmittance;
        vec3 sample_color = vec3(0.0);

        #ifdef PHOTONICS_GI_ENABLED
            vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

            float hit_skyLightF = ray_result_skylight(hit) / 15.0;
            hit_skyLightF = saturate(hit_skyLightF);

            #ifdef SHADOWS_ENABLED
                // trace sun
                ray_iter_set_direction(ray, localSkyLightDir);
                ray_iter_offset_position(ray, 0.1 * hit_localNormal);

                RayResult hit2;
                vec3 tint2 = vec3(1.0);
                bool is_hit2 = trace_ray(ray, hit2, tint2);

                if (!is_hit2) {
                    vec3 skyLightColor = get_sun_color(hit_localPos, localSkyLightDir);
                    sample_color += skyLightColor * tint2 * max(dot(hit_localNormal, localSkyLightDir), 0.0);

                    #ifdef SHADOW_CLOUDS
                        float cloudShadow = SampleCloudShadow(hit_localPos, localSkyLightDir);
                        sample_color *= cloudShadow * 0.5 + 0.5;
                    #endif
                }
            #else
                #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
                    //                    hit_skyLightF = _pow3(hit_skyLightF);
                    vec3 lmcolor = texture(texLightmap, LightMapTex(vec2(0.0, pow5(hit_skyLightF)))).rgb;

                    float oldLighting = GetOldLighting(hit_localNormal);
                    sample_color += oldLighting * RGBToLinear(lmcolor);
                #endif
            #endif

//            #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
//                sample_color += _pow3(hit_skyLightF) * AmbientLightF * SampleSkyIrradiance(hit_localNormal);
//            #endif

            #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
                #if PHOTONICS_GI_BLOCK_SAMPLES > 0
                    vec3 hitTracePos = hit_position
                        + 0.08 * hit_localNormal;

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
                            //                        vec3 shit = modify_attenuation(light, lightOffset, hitTracePos, hitTracePos, hit_localNormal, hit_localNormal) * sample_scale;

                            float distSq = dot(lightOffset, lightOffset);
                            float invDist = inversesqrt(distSq);
                            vec3 lightDir = lightOffset * invDist;
                            float lightDist = distSq * invDist;

                            float NoLm = max(dot(hit_localNormal, lightDir), 0.0);
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
                vec3 voxelPos = GetVoxelPosition(hit_localPos);
                vec3 samplePos = GetFloodFillSamplePos(voxelPos, hit_localNormal);
                sample_color += SampleFloodFill(samplePos);
            #endif
        #endif

        sample_color += hit_emission;

        final_color = hit_albedo * sample_color;
    }

    indirect_color += final_color * tint;
}
