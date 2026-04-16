#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 lmcoord;
    vec3 localPos;
} vIn;


#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFill;
#endif

#ifdef SHADOWS_ENABLED
    uniform SHADOW_SAMPLER TEX_SHADOW;

    #ifdef SHADOW_COLORED
        uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

uniform float far;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec3 cameraPosition;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform vec4 entityColor;
uniform float alphaTestRef;
uniform int frameCounter;
uniform int isEyeInWater;
uniform ivec2 atlasSize;
uniform vec2 viewSize;

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/ign.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/shadows.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(DEFERRED_REFLECT_ENABLED)
    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"
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

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif

#include "/photonics/photonics.glsl"


#include "_output.glsl"

void main() {
    // avoid view bobbing
    vec3 viewPos = mul3(gbufferModelView, vIn.localPos);
    vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);

    vec3 rayOrigin = vIn.localPos + rt_camera_position;
    rayOrigin += 0.01 * localViewDir;

    RayJob ray = RayJob(
        rayOrigin, localViewDir,
        vec3(0), vec3(0), vec3(0), false
    );

    ray_constraint = ivec3(ray.origin);
    trace_ray(ray);

    if (!ray.result_hit) discard;

    vec2 lmcoord = vIn.lmcoord;
    lmcoord.y = get_result_sky_light(ray.result_normal) / 15.0;

    vec3 hitLocalNormal = ray.result_normal;
    vec3 hitLocalPos = ray.result_position - rt_camera_position;
    vec3 hitViewPos = mul3(gbufferModelView, hitLocalPos);

    float hitViewDepth = -hitViewPos.z;
    gl_FragDepth = 0.5 * (-gbufferProjection[2].z*hitViewDepth + gbufferProjection[3].z) / hitViewDepth + 0.5;

    vec4 color = vec4(ray.result_color, 1.0);


    float viewDist = length(hitLocalPos);

    vec3 albedo = RGBToLinear(color.rgb);
    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    vec3 shadow = vec3(1.0);
    #ifdef SHADOWS_ENABLED
        vec3 shadowPos = hitLocalPos;
        shadowPos += 0.08 * hitLocalNormal;
        shadowPos = mul3(shadowModelView, shadowPos);
        shadowPos.z += 0.032 * viewDist;
        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        shadow = SampleShadowColor(shadowPos);

        float shadow_NoL = dot(hitLocalNormal, localSkyLightDir);
        shadow *= pow(saturate(shadow_NoL), 0.2);
    #endif

    #ifdef SHADOW_CLOUDS
        shadow *= SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    #ifdef LIGHTING_COLORED
        vec3 voxelPos = GetVoxelPosition(hitLocalPos);
        float lpvFade = GetVoxelFade(voxelPos);
    #endif

    #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
        lmcoord.x = 0.0;
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        #if defined(LIGHTING_COLORED) && !defined(PHOTONICS_BLOCK_LIGHT_ENABLED)
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
            vec3 lpvSample = SampleFloodFill(samplePos);
            blockLight = mix(blockLight, lpvSample, lpvFade);
        #endif

        vec3 skyLight = vec3(0.0);
        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = GetSkyLightColor(hitLocalPos, sunLocalDir.y, localSkyLightDir.y);
            float skyLight_NoLm = max(dot(localSkyLightDir, hitLocalNormal), 0.0);
            skyLight = skyLight_NoLm * shadow * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(hitLocalNormal);
            #endif
        #endif

//        skyLight *= lmcoord.y;

        color.rgb = albedo * (blockLight + skyLight + MinAmbientF);

//        #ifdef RENDER_TERRAIN
//            color.rgb *= _pow2(vIn.color.a);
//        #endif
    #else
        #if defined(PHOTONICS_GI_ENABLED) && !defined(RENDER_TRANSLUCENT)
            #ifdef SHADOWS_ENABLED
                lmcoord.y = maxOf(shadow);
            #else
                lmcoord.y = _pow3(lmcoord.y);
            #endif
        #endif

        #ifdef SHADOWS_ENABLED
            lmcoord.y = min(lmcoord.y, shadow * (1.0 - AmbientLightF) + AmbientLightF);
        #endif

        lmcoord.y *= GetOldLighting(hitLocalNormal);

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        vec3 lit = texture(lightmap, LightMapTex(lmcoord)).rgb;
        lit = RGBToLinear(lit);

        #if defined(LIGHTING_COLORED) && !defined(PHOTONICS_BLOCK_LIGHT_ENABLED)
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, hitLocalNormal);
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            lit += lpvFade * lpvSample;
        #endif

        color.rgb = albedo * lit;
    #endif

    #ifdef DEFERRED_REFLECT_ENABLED
        float smoothness = 1.0 - mat_roughness_lab(specularData.r);
        float f0 = mat_f0_lab(specularData.g);

        float NoV = dot(hitLocalNormal, -localViewDir);
        color.rgb *= 1.0 - F_schlick(NoV, f0, 1.0) * _pow2(smoothness);
    #endif


    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);


    outFinal = color;
    outAlbedo = vec4(LinearToRGB(albedo * color.a), 0.0);

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_ENABLED
        vec3 viewNormal = mat3(gbufferModelView) * hitLocalNormal;
        outNormals = vec4(OctEncode(hitLocalNormal), OctEncode(viewNormal));

        outSpecularMeta = uvec2(0u);
    #endif
}
