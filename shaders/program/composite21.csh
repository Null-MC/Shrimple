#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_REFLECT texReflect

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_trans
    #define MAT_PROJ_LAST matProjLast
    #define MAT_PROJ_INV matProjInv
    #define MAT_PROJ matProj
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_LAST gbufferPreviousProjection
    #define MAT_PROJ_INV gbufferProjectionInverse
    #define MAT_PROJ gbufferProjection
#endif

#ifndef PHOTONICS_REFLECT_ENABLED
    const bool colortex0MipmapEnabled = true;
#endif


layout (local_size_x = 16, local_size_y = 16) in;

const vec2 workGroupsRender = vec2(RENDER_SCALE_F, RENDER_SCALE_F);


#ifdef LIGHTING_REFLECT_ROUGHNESS
    layout(rgba16f) uniform writeonly image2D imgReflect;
#else
    layout(rgba16f) uniform writeonly image2D IMG_FINAL;
#endif

uniform sampler2D TEX_DEPTH;
//uniform usampler2D TEX_META;
uniform sampler2D TEX_FINAL;
uniform sampler2D texReflectHistory;

uniform sampler2D colortex10;

uniform sampler2D TEX_GB_COLOR;
uniform sampler2D TEX_GB_NORMALS;
uniform usampler2D TEX_GB_SPECULAR;

#ifdef PHOTONICS_REFLECT_ENABLED
    uniform sampler2D texLightmap;

    #ifdef LIGHTING_COLORED
        uniform sampler3D texFloodFill;
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        uniform sampler2D texSkyTransmit;
        uniform sampler3D texSkyIrradiance;
    #endif

    #ifdef SHADOW_CLOUDS
        uniform sampler2D texCloudShadow;
    #endif

    #ifdef SHADOWS_ENABLED
        uniform SHADOW_SAMPLER TEX_SHADOW;

        #ifdef SHADOW_COLORED
            uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
            uniform sampler2D shadowcolor0;
        #endif
    #endif
#endif

uniform float near;
uniform float far;
uniform float farPlane;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform int isEyeInWater;
uniform vec3 sunLocalDir;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform int frameCounter;
uniform vec2 viewSize;
uniform vec2 viewSizeScaled;
uniform vec2 taa_offset = vec2(0.0);

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/buffers/scene.glsl"

#include "/lib/ign.glsl"
#include "/lib/oklab.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/fog.glsl"
#include "/lib/water-absorb.glsl"
#include "/lib/fresnel.glsl"

#include "/lib/material/pbr.glsl"

#include "/lib/hash-noise.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material/lazanyi.glsl"
#endif

#ifdef LOD_ENABLED
    #include "/lib/lod-projection.glsl"
#endif

#ifdef PHOTONICS_REFLECT_ENABLED
    #include "/photonics/tracing.glsl"
    #include "/photonics/trace_ray.glsl"

    #include "/lib/shadows.glsl"

    #ifdef SHADOWS_ENABLED
        #include "/lib/shadow-sample.glsl"
    #endif

    #ifdef SHADOW_CLOUDS
        #include "/lib/cloud-shadows.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        #ifdef WORLD_OVERWORLD
            #include "/lib/sky-transmit.glsl"
            #include "/lib/sky-irradiance.glsl"
        #endif

        #include "/lib/enhanced-lighting.glsl"
    #else
        #include "/lib/vanilla-light.glsl"
    #endif

    #ifdef LIGHTING_COLORED
        #include "/lib/voxel.glsl"
        #include "/lib/floodfill-render.glsl"
    #endif
#endif


vec3 projectToScreenBounds(const in vec3 screenPos, const in vec3 screenDir) {
    vec3 stepDir = sign(screenDir);
    vec3 nextDist = stepDir * 0.5 + 0.5;
    nextDist = (nextDist - fract(screenPos)) / screenDir;

    float closestDist = max(minOf(nextDist) - 0.00001, 0.0);
    return screenDir * closestDist + screenPos;
}

vec3 projectScreenTrace(const in vec3 viewPos, const in vec3 screenPos, const in vec3 viewDir) {
    float viewDist = length(viewPos);

    vec3 dest_viewPos = 0.1 * viewDist * viewDir + viewPos;

    #ifdef LOD_ENABLED
        mat4 matProj = GetLodProjection(gbufferProjection, near);
    #endif

    vec3 dest_clipPos = project(MAT_PROJ, dest_viewPos);
    vec3 dest_screenPos = ndcToScreen(dest_clipPos);

    // float4 dest_clipPos = mul(ap.camera.projection, float4(dest_viewPos, 1.0));
    // dest_clipPos.xyz = clamp(dest_clipPos.xyz, float3(-1.0, -1.0, 0.00001), 1.0) / dest_clipPos.w;
//    vec3 dest_screenPos = dest_clipPos.xyz * 0.5 + 0.5;

    vec3 screenDir = normalize(dest_screenPos - screenPos);

    return projectToScreenBounds(screenPos, screenDir);
}

vec3 sample_cosine_weighted_hemisphere() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    //vec2 u = vec2(rand_next_float(), rand_next_float());
    vec2 u = hash23(vec3(uv, frameCounter));
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

vec2 reproject(const in vec3 screenPos, const in float reflectDist) {
    #ifdef LOD_ENABLED
        mat4 matProjInv = GetLodProjectionInverse(gbufferProjectionInverse, near);
    #endif

    vec3 ndcPos = screenToNdc(screenPos);
    vec3 viewPos = project(MAT_PROJ_INV, ndcPos);
//    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    vec3 localPos = mat3(gbufferModelViewInverse) * viewPos;

    vec3 prev_localPos = localPos + cameraPosition - previousCameraPosition;

    prev_localPos += reflectDist * normalize(localPos);

//    #ifdef VELOCITY_ENABLED
//        vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / viewSize;
//        prev_localPos -= texture(TEX_VELOCITY, texcoord).xyz;
//    #endif

//    vec3 prev_viewPos = mul3(gbufferPreviousModelView, prev_localPos);
    vec3 prev_viewPos = mat3(gbufferPreviousModelView) * prev_localPos;
    vec3 prev_ndcPos = project(MAT_PROJ_LAST, prev_viewPos);
    return prev_ndcPos.xy * 0.5 + 0.5;
}

//#ifdef PHOTONICS_REFLECT_ENABLED
//    #define PH_USE_CUSTOM_ALPHA
//    #define PH_ALPHA_FUNC(color) apply_tint_impl(color)
//
//    vec3 apply_tint_impl(const in vec4 color) {
//        return color.rgb * (1.0 - color.a);
//    }
//#endif

#ifdef PHOTONICS_REFLECT_ENABLED
    //
#endif


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

//    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    #ifdef LOD_ENABLED
        bool isSky = depth <= 0.0;
    #else
        bool isSky = depth >= 1.0;
    #endif

    vec2 texcoord = (uv + 0.5) / viewSizeScaled;
    vec3 screenPos = vec3(texcoord, depth);
    vec3 ndcPos = screenToNdc(screenPos);

    #if defined(TAA_ENABLED) && defined(PHOTONICS_REFLECT_ENABLED)
        ndcPos.xy -= taa_offset * 2.0;
    #endif

//    if (meta != 0u) {
//        ndcPos.z /= MC_HAND_DEPTH;
//    }

    #ifdef LOD_ENABLED
        mat4 matProjInv = GetLodProjectionInverse(gbufferProjectionInverse, near);
    #endif

    vec3 viewPos = project(MAT_PROJ_INV, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 reflectColor = vec3(0.0);
    float reflectDist = 0.0;
    float roughness = 0.0;
    float roughL = 0.0;

    if (!isSky) {
//        uvec2 albedoSpecularData = texelFetch(TEX_ALBEDO_SPECULAR, uv, 0).rg;
//        vec4 albedoData = unpackUnorm4x8(albedoSpecularData.r);
//        vec4 specularData = unpackUnorm4x8(albedoSpecularData.g);
        vec4 color = texelFetch(TEX_GB_COLOR, uv, 0);
        vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);
        uvec2 specularMetaData = texelFetch(TEX_GB_SPECULAR, uv, 0).rg;

        float viewDist = length(viewPos);
        vec3 viewDir = viewPos / viewDist;

//        float totalDist = viewDist;

        vec3 albedo = RGBToLinear(color.rgb);
        vec4 specularData = unpackUnorm4x8(specularMetaData.r);
        vec4 meta = unpackUnorm4x8(specularMetaData.g);

        #ifdef MATERIAL_PBR_ENABLED
            roughness = mat_roughness(specularData.r);
        #else
            roughness = mat_roughness_lab(specularData.r);
        #endif

        roughL = _pow2(roughness);
        float smoothness = 1.0 - roughness;

        if (smoothness > (16.5/255.0)) {
            //            vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);
            vec3 localGeoNormal = OctDecode(normalData.xy);
            vec3 viewTexNormal = OctDecode(normalData.zw);

            // TODO: FOR TESTING ONLY!
//            viewTexNormal = mat3(gbufferModelView) * localGeoNormal;

            float lmcoord_y = meta.y;

            #ifdef LIGHTING_REFLECT_ROUGHNESS
                vec3 randomNormal = sample_cosine_weighted_hemisphere();
                randomNormal = transform_to_world(viewTexNormal, randomNormal);
                vec3 reflectViewNormal = normalize(mix(viewTexNormal, randomNormal, roughL));
            #else
                vec3 reflectViewNormal = viewTexNormal;
            #endif

            vec3 reflectViewDir = normalize(reflect(viewDir, reflectViewNormal));
            vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;

            vec3 transmittance = vec3(1.0);
            bool is_hit = false;

            #ifdef PHOTONICS_REFLECT_ENABLED
                vec3 rtPos = localPos + rt_camera_position;

                RayIterator ray;
                ray.iterations = PHOTONICS_REFLECT_STEPS;
                ray_iter_set_position(ray, rtPos);
                ray_iter_set_direction(ray, reflectLocalDir);
                ray_iter_offset_position(ray, 0.004 * localGeoNormal);

                vec3 radiance = vec3(0.0);
//                vec3 transmittance = vec3(1.0);

                for (int bounce = 0; bounce < PHOTONICS_REFLECT_BOUNCES; bounce++) {
                    RayResult hit = ray_iter_next(ray);
                    is_hit = ray_result_is_hit(hit);
                    if (!is_hit || !ray_iter_is_in_bounds(ray)) break;

                    vec3 hit_position = ray_result_position(hit);

//                    if (lengthSq(hit_position - rtPos) > 0.002) {
                    VoxelData voxel_data = ray_result_voxel_data(hit);
                    vec3 hit_albedo = voxel_data_albedo(voxel_data).rgb;
                    hit_albedo = RGBToLinear(hit_albedo);

                    vec3 hitLocalPos = hit_position - rt_camera_position;
                    vec3 hitLocalNormal = ray_result_normal(hit);
                    float hitViewDist = length(hitLocalPos);

                    vec3 hit_reflectLocalDir = normalize(reflect(reflectLocalDir, hitLocalNormal));

                    reflectDist += distance(localPos, hitLocalPos);

                    float hit_sky = ray_result_skylight(hit) / 15.0;
                    vec2 hit_lmcoord = vec2(0.0, hit_sky);

                    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

                    vec3 shadow = vec3(1.0);
                    #ifdef SHADOWS_ENABLED
                        vec3 shadowPos = hitLocalPos;
                        shadowPos += 0.08 * hitLocalNormal;
                        shadowPos = mul3(shadowModelView, shadowPos);

//                        shadowPos.z += 0.032 * hitViewDist;
                        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

                        distort(shadowPos.xy);
                        shadowPos = shadowPos * 0.5 + 0.5;

                        shadow = SampleShadowColor(shadowPos, uv);

                        float shadow_NoL = dot(hitLocalNormal, localSkyLightDir);
                        shadow *= pow(saturate(shadow_NoL), 0.2);

                        #ifdef PHOTONICS_SHADOW_ENABLED
                            RayIterator shadow_ray;
                            shadow_ray.iterations = 100; // TODO: add setting?
                            ray_iter_set_position(shadow_ray, hit_position);
                            ray_iter_offset_position(shadow_ray, 0.004 * localGeoNormal);
                            ray_iter_set_direction(shadow_ray, localSkyLightDir);

                            RayResult shadow_hit;
                            vec3 shadow_tint = vec3(1.0);
                            bool is_hit = trace_ray(shadow_ray, shadow_hit, shadow_tint);

//                            #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                                if (is_hit) shadow = vec3(0.0);
                                else shadow *= shadow_tint;
//                            #else
//                                if (ray.result_hit) shadowF = 0.0;
//                            #endif
                        #endif
                    #endif

                    #ifdef SHADOW_CLOUDS
                        shadow *= SampleCloudShadow(hitLocalPos, localSkyLightDir);
                    #endif

                    vec3 hit_color;

                    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                        hit_lmcoord = _pow3(hit_lmcoord);

                        // block lightmap coord not supported
                        vec3 blockLight = vec3(0.0);

                        #ifdef LIGHTING_COLORED
                            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
                            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
                            vec3 lpvSample = SampleFloodFill(samplePos);
                            blockLight = lpvSample;
                        #endif

                        vec3 skyLight = vec3(0.0);
                        #ifdef WORLD_OVERWORLD
                            vec3 skyLightColor = GetSkyLightColor(hitLocalPos, localSkyLightDir.y);
                            float skyLight_NoLm = max(dot(localSkyLightDir, hitLocalNormal), 0.0);

                            skyLight = skyLight_NoLm * shadow * skyLightColor;

                            #ifndef SHADOWS_ENABLED
                                skyLight *= hit_lmcoord.y;
                            #endif

                            skyLight += hit_lmcoord.y * AmbientLightF * SampleSkyIrradiance(hitLocalNormal);
                        #endif

                        hit_color = 1.0/PI * (blockLight + skyLight);
                    #else
                        #ifdef SHADOWS_ENABLED
                            hit_lmcoord.y = min(hit_lmcoord.y, maxOf(shadow) * (1.0 - AmbientLightF) + AmbientLightF);
                        #endif

                        hit_lmcoord.y *= GetOldLighting(hitLocalNormal);

                        vec3 lit = texture(texLightmap, LightMapTex(hit_lmcoord)).rgb;
                        lit = RGBToLinear(lit);

                        #ifdef LIGHTING_COLORED
                            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
                            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
                            vec3 lpvSample = SampleFloodFill(samplePos); // lmcoord mask won't work here
                            lit += lpvSample;
                        #endif

                        hit_color = lit;
                    #endif

                    // probably wrong
                    float hit_NoV = dot(hitLocalNormal, -reflectLocalDir);

                    #ifdef MATERIAL_PBR_ENABLED
                        vec4 hit_specularData = voxel_data_specular(voxel_data);

                        LazanyiF hit_lF = mat_f0_lazanyi(hit_albedo, hit_specularData.g);
                        vec3 hit_F = F_lazanyi(hit_NoV, hit_lF.f0, hit_lF.f82);

                        float hit_roughness = mat_roughness(hit_specularData.r);
                        float hit_metalness = mat_metalness(hit_specularData.g);
                        float hit_roughL = _pow2(hit_roughness);
                        float hit_smoothL = 1.0 - hit_roughL;

                        // apply metal diffuse darkening
                        hit_color *= 1.0 - hit_metalness * hit_smoothL;

                        // rough-scatter hack
                        hit_color *= 1.0 - hit_F * hit_smoothL;

                        // apply emission
                        float emission = mat_emission(hit_specularData);
                        TransformEmission(emission);
                        hit_color += emission;
                    #else
                        float hit_F = F_schlick(hit_NoV, 0.04, 1.0);
                    #endif

                    hit_color *= hit_albedo;

                    #if defined(LIGHTING_SPECULAR) && defined(MATERIAL_PBR_ENABLED)
                        // TODO: reflect in view space to avoid view-bob
                        float hit_smoothness = 1.0 - hit_roughness;
//                        vec3 hit_reflectLocalDir = normalize(reflect(reflectLocalDir, hitLocalNormal));
                        vec3 hit_reflectColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), hit_reflectLocalDir);
                        hit_reflectColor *= _pow2(hit_lmcoord.y);

//                        if (skyLight_NoLm > 0.0 && dot(hitLocalNormal, localSkyLightDir) > 0.0) {
//                            vec3 skySpecularLightDir = GetAreaLightDir(hitLocalNormal, hit_reflectLocalDir, localSkyLightDir, 100.0, 8.0);
//                            skySpecularLightDir = normalize(skySpecularLightDir + 0.1*localSkyLightDir);

                            hit_reflectColor += SampleLightSpecular(hit_albedo, hitLocalNormal, localSkyLightDir, -reflectLocalDir, skyLight_NoLm, hit_roughL, hit_specularData.g) * skyLight;
//                        }

                        // apply metal tint
                        hit_reflectColor *= mix(vec3(1.0), hit_albedo, hit_metalness);

                        hit_color += hit_smoothness * hit_reflectColor * hit_F;
                    #endif

                    // TODO: refactor for 0.4
//                    reflectColor *= result_tint_color;

                    // TODO: probably wrong
                    float hit_NoLm = max(dot(hitLocalNormal, hit_reflectLocalDir), 0.0);

//                    float hit_NoV = dot(hitLocalNormal, -reflectLocalDir);
//
//                    #ifdef MATERIAL_PBR_ENABLED
//                        LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
//                        vec3 hit_F = F_lazanyi(hit_NoV, lF.f0, lF.f82);
//                    #else
//                        float hit_f0 = mat_f0_lab(specularData.g);
//                        float hit_F = F_schlick(hit_NoV, hit_f0, 1.0);
//                    #endif

                    radiance += hit_color * transmittance;
                    transmittance *= hit_NoLm * hit_F;

                    reflectLocalDir = hit_reflectLocalDir;
                    ray_iter_set_direction(ray, reflectLocalDir);
//                    }
                }

                reflectColor = radiance;

//                float envFogF = GetEnvFogStrength(hitViewDist);
//                float fogF = envFogF;//max(borderFogF, envFogF);
//
//                vec3 fogColorL = RGBToLinear(fogColor);
//                vec3 skyColorL = RGBToLinear(skyColor);
//                vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, reflectLocalDir);
//
//                reflectColor = mix(reflectColor, fogColorFinal, fogF);
            #else
                vec3 screenEnd = projectScreenTrace(viewPos, screenPos, reflectViewDir);
                vec3 traceClipEnd = screenToNdc(screenEnd);
                vec3 traceClipStart = ndcPos;

                vec3 traceClipPos;
                vec3 traceClipPos_prev = traceClipStart;
                vec2 traceScreenPos;

                for (uint i = 0; i < SSR_COARSE_STEPS; i++) {
                    float f = (i + 0.5) / float(SSR_COARSE_STEPS);
                    traceClipPos = mix(traceClipStart, traceClipEnd, saturate(f));
                    traceScreenPos = traceClipPos.xy * 0.5 + 0.5;
                    if (saturate(traceScreenPos) != traceScreenPos) break;

//                    uint meta = texelFetch(TEX_META, ivec2(traceScreenPos * viewSize), 0).r;
//                    if (meta != 0u) continue;

                    float sampleDepth = texture(TEX_DEPTH, traceScreenPos * RENDER_SCALE_F).r;

                    #ifdef LOD_ENABLED
                        float screenDepthL = near / sampleDepth;
                        float traceDepthL = near / traceClipPos.z;
                    #else
                        float screenDepthL = linearizeDepth(sampleDepth * 2.0 - 1.0, near, farPlane);
                        float traceDepthL = linearizeDepth(traceClipPos.z, near, farPlane);
                    #endif

                    if (screenDepthL < traceDepthL - 0.02) {
                        is_hit = true;
                        break;
                    }

                    traceClipPos_prev = traceClipPos;
                    // traceDepthL_prev = traceDepthL;
                }

                if (is_hit) {
                    traceClipStart = traceClipPos_prev;
                    traceClipEnd = traceClipPos;

                    for (uint i = 0; i <= SSR_REFINE_STEPS; i++) {
                        float f = (i + 0.5) / float(SSR_REFINE_STEPS);
                        traceClipPos = mix(traceClipStart, traceClipEnd, saturate(f));
                        vec2 testPos = traceClipPos.xy * 0.5 + 0.5;
//                        if (saturate(testPos) != testPos) break;

//                        uint meta = texelFetch(TEX_META, ivec2(traceScreenPos * viewSize), 0).r;
//                        if (meta != 0u) continue;

                        float sampleDepth = texture(TEX_DEPTH, testPos * RENDER_SCALE_F).r;

                        #ifdef LOD_ENABLED
                            float screenDepthL = near / sampleDepth;
                            float traceDepthL = near / traceClipPos.z;
                        #else
                            float screenDepthL = linearizeDepth(sampleDepth * 2.0 - 1.0, near, farPlane);
                            float traceDepthL = linearizeDepth(traceClipPos.z, near, farPlane);
                        #endif

                        if (screenDepthL < traceDepthL) {
                            break;
                        }

                        traceScreenPos = testPos;
                    }

                    // TODO: set reflectDist

                    float mip = roughness * 6.0;
                    reflectColor = textureLod(TEX_FINAL, traceScreenPos * RENDER_SCALE_F, mip).rgb;
                }
            #endif

//            vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;

            float totalDist = viewDist + reflectDist;

            if (isEyeInWater == 1) {
                reflectColor *= GetWaterAbsorption(totalDist);
            }

            if (!is_hit) {
                vec3 reflectSkyColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), reflectLocalDir);
                reflectSkyColor *= _pow3(lmcoord_y);

                reflectColor += reflectSkyColor * transmittance;
            }

//            vec3 reflectLocalNormal = mat3(gbufferModelViewInverse) * reflectViewNormal;
//
//            vec3 localViewDir = -normalize(localPos);
//            float NoLm = max(dot(reflectViewNormal, reflectViewDir), 0.0);
//            vec3 specular = SampleLightSpecular(albedo, reflectLocalNormal, reflectLocalDir, localViewDir, NoLm, roughL, specularData.g);
//            reflectColor *= saturate(specular);

            float NoV = dot(viewTexNormal, -viewDir);

            #ifdef MATERIAL_PBR_ENABLED
                LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
                vec3 F = F_lazanyi(NoV, lF.f0, lF.f82);
            #else
                float f0 = mat_f0_lab(specularData.g);
                float F = F_schlick(NoV, f0, 1.0);
            #endif

//            float roughL = _pow2(roughness);
//            float smoothL = 1.0 - roughL;
            reflectColor *= F;// * pow4(smoothness);

//            reflectColor *= max(dot(reflectViewDir, viewTexNormal), 0.0);

//            reflectColor = vec3(3,0,0);

            #ifdef MATERIAL_PBR_ENABLED
                float metalness = mat_metalness(specularData.g);
            #else
                float metalness = mat_metalness_lab(specularData.g);
            #endif

            // apply metal tint
            reflectColor *= mix(vec3(1.0), albedo, metalness);

            // apply fog for reflect source
            float borderFogF = GetBorderFogStrength(viewDist);
            float envFogF = GetEnvFogStrength(totalDist);
            float fogF = max(borderFogF, envFogF);

            reflectColor *= 1.0 - fogF;
        }
    }

    #ifdef LIGHTING_REFLECT_ROUGHNESS
        float alpha = mix(0.5, 0.002, pow(roughness, 0.25));

        vec2 tex_last = reproject(screenPos, reflectDist);
        if (!all(equal(saturate(tex_last), tex_last))) alpha = 1.0;

        tex_last *= RENDER_SCALE_F;
        vec3 src = textureLod(texReflectHistory, tex_last, 0).rgb;
        reflectColor = mix(src, reflectColor, alpha);

        imageStore(imgReflect, uv, vec4(reflectColor, roughness));
    #else
        float smoothL = 1.0 - roughL;
        reflectColor *= pow4(smoothL);

        vec3 color_src = texelFetch(TEX_FINAL, uv, 0).rgb;
        vec3 color_final = color_src + reflectColor;

        imageStore(IMG_FINAL, uv, vec4(color_final, 1.0));
    #endif
}
