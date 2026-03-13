#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform sampler2D radiosity_position;

#ifndef PHOTONICS_REFLECT_ENABLED
    const bool colortex0MipmapEnabled = true;
#endif

#define MATERIAL_REFLECT_STEPS 32
#define MATERIAL_REFLECT_REFINE_STEPS 8

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_TEX_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;

#ifdef PHOTONICS_REFLECT_ENABLED
    uniform sampler2D texLightmap;

    #ifdef LIGHTING_COLORED
        uniform sampler3D texFloodFillA;
        uniform sampler3D texFloodFillB;
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
uniform vec3 shadowLightPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int frameCounter;
uniform vec2 taa_offset = vec2(0.0);

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/ign.glsl"
#include "/lib/hsv.glsl"
#include "/lib/oklab.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/fog.glsl"
#include "/lib/water.glsl"
#include "/lib/fresnel.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material/pbr.glsl"
    #include "/lib/material/lazanyi.glsl"
#endif

#ifdef PHOTONICS_REFLECT_ENABLED
    #include "/photonics/photonics.glsl"

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
    vec3 dest_clipPos = project(gbufferProjection, dest_viewPos);
    // float4 dest_clipPos = mul(ap.camera.projection, float4(dest_viewPos, 1.0));
    // dest_clipPos.xyz = clamp(dest_clipPos.xyz, float3(-1.0, -1.0, 0.00001), 1.0) / dest_clipPos.w;
    vec3 dest_screenPos = dest_clipPos.xyz * 0.5 + 0.5;

    vec3 screenDir = normalize(dest_screenPos - screenPos);

    return projectToScreenBounds(screenPos, screenDir);
}

#ifdef PHOTONICS_REFLECT_ENABLED
    #define PH_USE_CUSTOM_ALPHA
    #define PH_ALPHA_FUNC(color) apply_tint_impl(color)

    vec3 apply_tint_impl(const in vec4 color) {
        return color.rgb * (1.0 - color.a);
    }
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texture(depthtex0, texcoord).r;
    vec3 reflectColor = vec3(0.0);

    if (depth < 1.0) {
        uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;
        vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
        vec4 specularData = unpackUnorm4x8(reflectData.g);

        vec3 screenPos = vec3(texcoord, depth);
        vec3 ndcPos = screenPos * 2.0 - 1.0;

        #if defined(TAA_ENABLED) && defined(PHOTONICS_REFLECT_ENABLED)
            ndcPos.xy -= taa_offset * 2.0;
        #endif

        // TODO: fix hand depth

        vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
        float viewDist = length(viewPos);
        vec3 viewDir = viewPos / viewDist;

        float totalDist = viewDist;

        vec3 albedo = RGBToLinear(reflectDataR.rgb);

        #ifdef MATERIAL_PBR_ENABLED
            float roughness = mat_roughness(specularData.r);
        #else
            float roughness = mat_roughness_lab(specularData.r);
        #endif

        float smoothness = 1.0 - roughness;

        if (smoothness > (1.5/255.0)) {
            uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
            vec3 viewNormal = OctDecode(unpackUnorm2x16(reflectNormalData));

            float lmcoord_y = reflectDataR.w;

            vec3 reflectViewDir = normalize(reflect(viewDir, viewNormal));

            bool hit = false;
            #ifdef PHOTONICS_REFLECT_ENABLED
                vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
                vec3 rtPos = localPos + rt_camera_position;

                vec3 localNormal = mat3(gbufferModelViewInverse) * viewNormal;
                vec3 localReflectDir = mat3(gbufferModelViewInverse) * reflectViewDir;

                RayJob ray = RayJob(
                    rtPos + 0.004 * localNormal,
                    localReflectDir,
                    vec3(0), vec3(0), vec3(0), false
                );

                RAY_ITERATION_COUNT = PHOTONICS_REFLECT_STEPS;

                trace_ray(ray, true);

                if (ray.result_hit) {
                    hit = true;
                    vec3 albedo = RGBToLinear(ray.result_color);

                    vec3 hitLocalPos = ray.result_position - rt_camera_position;
                    vec3 hitLocalNormal = ray.result_normal;
                    float hitViewDist = length(hitLocalPos);

                    float traceDist = distance(localPos, hitLocalPos);
                    totalDist += traceDist;

                    float hit_sky = get_result_sky_light(hitLocalNormal) / 15.0;
                    vec2 lmcoord = vec2(0.0, hit_sky);

                    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

                    float shadow = 1.0;
                    #ifdef SHADOWS_ENABLED
                        vec3 shadowPos = hitLocalPos;
                        shadowPos += 0.08 * hitLocalNormal;
                        shadowPos = mul3(shadowModelView, shadowPos);

//                        shadowPos.z += 0.032 * hitViewDist;
                        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

                        distort(shadowPos.xy);
                        shadowPos = shadowPos * 0.5 + 0.5;

                        shadow = SampleShadows(shadowPos);

                        float shadow_NoL = dot(hitLocalNormal, localSkyLightDir);
                        shadow *= pow(saturate(shadow_NoL), 0.2);
                    #endif

                    #ifdef SHADOW_CLOUDS
                        shadow *= SampleCloudShadow(hitLocalPos, localSkyLightDir);
                    #endif

                    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                        lmcoord = _pow3(lmcoord);

                        // block lightmap coord not supported
                        vec3 blockLight = vec3(0.0);

                        #ifdef LIGHTING_COLORED
                            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
                            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
                            vec3 lpvSample = SampleFloodFill(samplePos) * 3.0;
                            blockLight = lpvSample;
                        #endif

                        vec3 skyLight = vec3(0.0);
                        #ifdef WORLD_OVERWORLD
                            vec3 skyLightColor = GetSkyLightColor(hitLocalPos, sunLocalDir.y, localSkyLightDir.y);
                            float skyLight_NoLm = max(dot(localSkyLightDir, hitLocalNormal), 0.0);

                            skyLight = skyLight_NoLm * shadow * skyLightColor;

                            #ifndef SHADOWS_ENABLED
                                skyLight *= lmcoord.y;
                            #endif

                            skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(hitLocalNormal);
                        #endif

                        reflectColor = albedo * (blockLight + skyLight);
                    #else
                        #ifdef SHADOWS_ENABLED
                            lmcoord.y = min(lmcoord.y, shadow * (1.0 - AmbientLightF) + AmbientLightF);
                        #endif

                        lmcoord.y *= GetOldLighting(hitLocalNormal);

                        lmcoord = LightMapTex(lmcoord);
                        vec3 lit = texture(texLightmap, lmcoord).rgb;
                        lit = RGBToLinear(lit);

                        #ifdef LIGHTING_COLORED
                            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
                            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
                            vec3 lpvSample = SampleFloodFill(samplePos); // lmcoord mask won't work here
                            lit += lpvSample;
                        #endif

                        reflectColor = albedo * lit;
                    #endif

                    // TODO: fog
//                    float borderFogF = GetBorderFogStrength(viewDist);
                    float envFogF = GetEnvFogStrength(hitViewDist);
                    float fogF = envFogF;//max(borderFogF, envFogF);

                    vec3 fogColorL = RGBToLinear(fogColor);
                    vec3 skyColorL = RGBToLinear(skyColor);
                    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localReflectDir);

                    reflectColor = mix(reflectColor, fogColorFinal, fogF);

                    reflectColor *= result_tint_color;
                }
            #else
                vec3 screenEnd = projectScreenTrace(viewPos, screenPos, reflectViewDir);
                vec3 traceClipEnd = screenEnd * 2.0 - 1.0;
                vec3 traceClipStart = ndcPos;

                vec3 traceClipPos;
                vec3 traceClipPos_prev = traceClipStart;
                vec2 traceScreenPos;

//                #ifdef TAA_ENABLED
//                    traceClipStart.xy -= taa_offset * 2.0;
//                    traceClipEnd.xy   -= taa_offset * 2.0;
//                #endif

                float dither = 0.0;//GetBayerValue(uv);
                for (uint i = 0; i < MATERIAL_REFLECT_STEPS; i++) {
                    float f = (i + dither) / float(MATERIAL_REFLECT_STEPS);
                    traceClipPos = mix(traceClipStart, traceClipEnd, saturate(f));
                    traceScreenPos = traceClipPos.xy * 0.5 + 0.5;
                    if (saturate(traceScreenPos) != traceScreenPos) break;

                    float sampleClipDepth = texture(depthtex0, traceScreenPos).r * 2.0 - 1.0;
                    float screenDepthL = linearizeDepth(sampleClipDepth, near, farPlane);
                    float traceDepthL = linearizeDepth(traceClipPos.z, near, farPlane);

                    if (screenDepthL < traceDepthL - 0.02) {
                        hit = true;
                        break;
                    }

                    traceClipPos_prev = traceClipPos;
                    // traceDepthL_prev = traceDepthL;
                }

                if (hit) {
                    traceClipStart = traceClipPos_prev;
                    traceClipEnd = traceClipPos;

                    for (uint i = 0; i <= MATERIAL_REFLECT_REFINE_STEPS; i++) {
                        float f = (i + dither) / float(MATERIAL_REFLECT_REFINE_STEPS);
                        traceClipPos = mix(traceClipStart, traceClipEnd, saturate(f));
                        vec2 testPos = traceClipPos.xy * 0.5 + 0.5;
                        if (saturate(testPos) != testPos) break;

                        float sampleClipDepth = texture(depthtex0, testPos).r * 2.0 - 1.0;
                        float screenDepthL = linearizeDepth(sampleClipDepth, near, farPlane);
                        float traceDepthL = linearizeDepth(traceClipPos.z, near, farPlane);

                        if (screenDepthL < traceDepthL) {
                            break;
                        }

                        traceScreenPos = testPos;
                    }
                }

                if (hit) {
                    // float roughL = _pow2(roughness);
                    float mip = roughness * 4.0;

                    reflectColor = textureLod(TEX_FINAL, traceScreenPos, mip).rgb;
                }
            #endif

            if (hit) {
                if (isEyeInWater == 1)
                    reflectColor *= GetWaterAbsorption(totalDist);
            }
            else {
                vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
                reflectColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), reflectLocalDir);
                reflectColor *= _pow3(lmcoord_y);
            }

            float NoV = dot(viewNormal, -viewDir);

            #ifdef MATERIAL_PBR_ENABLED
                LazanyiF F = mat_f0_lazanyi(albedo, specularData.g);
                reflectColor *= F_lazanyi(NoV, F.f0, F.f82);
            #else
                float f0 = mat_f0_lab(specularData.g);
                reflectColor *= F_schlick(NoV, f0, 1.0);
            #endif

            reflectColor *= _pow2(smoothness);
        }

        #ifdef MATERIAL_PBR_ENABLED
            float metalness = mat_metalness(specularData.g);
        #else
            float metalness = mat_metalness_lab(specularData.g);
        #endif

        // apply metal tint
        vec3 tint = mix(vec3(1.0), albedo, metalness);
        reflectColor *= tint;

        // apply fog for reflect source
        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = max(borderFogF, envFogF);

        reflectColor *= 1.0 - fogF;
    }

    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    outFinal = src + reflectColor;
}
