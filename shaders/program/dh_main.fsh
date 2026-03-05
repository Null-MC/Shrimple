#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat int materialId;
} vIn;


#ifdef RENDER_TRANSLUCENT
    uniform sampler2D depthtex0;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
    uniform sampler2DShadow shadowtex1HW;
#else
    uniform sampler2D shadowtex1;
#endif

uniform float far;
uniform float nearPlane;
uniform float farPlane;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform int isEyeInWater;

uniform float dhNearPlane;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/hsv.glsl"
#include "/lib/fog.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/dh-noise.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
    #include "/lib/octohedral.glsl"
    #include "/lib/fresnel.glsl"
    #include "/lib/material.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadows.glsl"
#endif


#include "_output.glsl"

void main() {
    vec3 localNormal = normalize(vIn.localNormal);
    float viewDist = length(vIn.localPos);
    vec3 localViewDir = vIn.localPos / viewDist;

    #ifdef RENDER_TRANSLUCENT
        float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
        float depthL = linearizeDepth(depth * 2.0 - 1.0, nearPlane, farPlane);
        float depthDhL = linearizeDepth(gl_FragCoord.z * 2.0 - 1.0, dhNearPlane, dhFarPlane);
        if (depthL < depthDhL && depth < 1.0) {discard; return;}
//        vec3 viewPos = mul3(gbufferModelView, vIn.localPos);
//        if (depthL < -viewPos.z && depth < 1.0) {discard; return;}
    #endif

    if (viewDist < dh_clipDistF * far) {
        discard;
        return;
    }

    vec4 color = vIn.color;

    float smoothness = 0.0;
    float emission = 0.0;
    float f0 = 0.04;

    vec3 albedo = RGBToLinear(color.rgb);

    #ifndef RENDER_TRANSLUCENT
        vec3 worldPos = vIn.localPos + cameraPosition;
        applyNoise(albedo, 1.0, worldPos, viewDist);
    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if (defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)) //&& defined(RENDER_TRANSLUCENT)
        if (vIn.materialId == DH_BLOCK_WATER) {
            // TODO: add option to make clear?
            // albedo = vec3(0.0);
            smoothness = 0.98;
            f0 = 0.02;
        }

        if (vIn.materialId == DH_BLOCK_LAVA) emission = 0.76;
        if (vIn.materialId == DH_BLOCK_ILLUMINATED) emission = 0.92;
    #endif

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    float shadow = 1.0;
    #ifdef SHADOWS_ENABLED
        vec3 shadowPos = vIn.localPos;
        shadowPos += 0.08 * localNormal;
        shadowPos = mul3(shadowModelView, shadowPos);
        shadowPos.z += 0.032 * viewDist;
        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            shadow = texture(shadowtex1HW, shadowPos).r;
        #else
            float shadowDepth = texture(shadowtex1, shadowPos.xy).r;
            shadow = step(shadowPos.z, shadowDepth);
        #endif

        float shadow_NoL = dot(localNormal, localSkyLightDir);
        shadow *= pow(saturate(shadow_NoL), 0.2);
    #endif

    vec2 lmcoord = vIn.lmcoord;

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

//        vec3 localSunLightDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);

        float skyLight_NoLm = max(dot(localSkyLightDir, localNormal), 0.0);
        vec3 skyLight = lmcoord.y * ((skyLight_NoLm * shadow)*0.7 + 0.3) * skyLightColor;

        color.rgb = albedo * (blockLight + skyLight);
    #else
        lmcoord.y = min(lmcoord.y, shadow * 0.5 + 0.5);

        lmcoord.y *= GetOldLighting(localNormal);

        lmcoord = LightMapTex(lmcoord);
        vec3 lit = texture(lightmap, lmcoord).rgb;
        lit = RGBToLinear(lit);

        color.rgb = albedo * lit;
    #endif

    #ifdef LIGHTING_REFLECT_ENABLED
        float NoV = dot(localNormal, -localViewDir);
        color.rgb *= 1.0 - F_schlick(NoV, f0, 1.0) * _pow2(smoothness);
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        //float emission = mat_emission(specularData);
        TransformEmission(emission);
        color.rgb += albedo * emission;
    #endif

    #if !defined(SSAO_ENABLED) || defined(RENDER_TRANSLUCENT)
        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = max(borderFogF, envFogF);

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 fogColorFinal = GetSkyFogColor(skyColorL, fogColorL, localViewDir);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);
    #endif

    outFinal = color;

    #ifdef PHOTONICS_LIGHT_ENABLED
        outGeoNormal = packUnorm2x16(OctEncode(localNormal));
    #endif

    #if defined(LIGHTING_REFLECT_ENABLED) || defined(PHOTONICS_LIGHT_ENABLED)
        vec3 viewNormal = mat3(gbufferModelView) * localNormal;

        outTexNormal = packUnorm2x16(OctEncode(viewNormal));

        outReflectSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), lmcoord.y)),
            packUnorm4x8(vec4(smoothness, f0, 0.0, emission)));
    #endif
}
