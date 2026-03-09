#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    flat uint color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vIn;


uniform sampler2D gtexture;

#ifdef MATERIAL_PBR_ENABLED
    uniform sampler2D normals;
    uniform sampler2D specular;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;
#endif

#ifdef SHADOWS_ENABLED
    #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #else
        uniform sampler2D shadowtex0;
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
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform float rainStrength;
uniform float alphaTestRef;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int frameCounter;
uniform int isEyeInWater;

uniform int textureFilteringMode;
uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/hsv.glsl"
#include "/lib/fog.glsl"
#include "/lib/ign.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/shadows.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
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


#include "_output.glsl"

void main() {
    vec2 texcoord = vIn.texcoord;
    float mip = textureQueryLod(gtexture, texcoord).y;
    float viewDist = length(vIn.localPos);

    vec4 color = textureLod(gtexture, texcoord, mip);

    if (color.a < alphaTestRef) discard;

    vec4 tint = unpackUnorm4x8(vIn.color);
    #if defined(RENDER_TERRAIN) && LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        color.rgb *= tint.rgb;
    #else
        color *= tint;
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 normalData = textureLod(normals, texcoord, mip);
    //    vec3 tex_normal = mat_normal(normalData.xyz);
        float tex_occlusion = mat_occlusion(normalData.w);

        vec4 specularData = textureLod(specular, texcoord, mip);
    #else
        const float tex_occlusion = 1.0;
    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    float shadow = 1.0;
    #ifdef SHADOWS_ENABLED
        vec3 shadowPos = mul3(shadowModelView, vIn.localPos);
        shadowPos.z += 0.016 * viewDist;
        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        shadow = SampleShadows(shadowPos);
    #endif

    #ifdef SHADOW_CLOUDS
        shadow *= SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    #ifdef LIGHTING_COLORED
        vec3 voxelPos = GetVoxelPosition(vIn.localPos);
        float lpvFade = GetVoxelFade(voxelPos);
    #endif

    vec2 lmcoord = vIn.lmcoord;
    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, vec3(0.0));
            vec3 lpvSample = SampleFloodFill(samplePos) * 3.0;
//            blockLight = mix(blockLight, lpvSample, lpvFade);
            blockLight += lpvSample * lpvFade;
        #endif

        vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);
        vec3 skyLight = shadow * skyLightColor;

        #ifndef SHADOWS_ENABLED
            skyLight *= lmcoord.y;
        #endif

        #ifndef PHOTONICS_GI_ENABLED
            skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(vec3(0,1,0));
        #endif

        color.rgb = albedo * (blockLight + skyLight);

        #ifdef RENDER_TERRAIN
            color.rgb *= _pow2(vIn.color.a);
        #endif
    #else
        lmcoord.y = min(lmcoord.y, shadow * (1.0 - AmbientLightF) + AmbientLightF);

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        lmcoord = LightMapTex(lmcoord);
        vec3 lit = texture(lightmap, lmcoord).rgb;
        lit = RGBToLinear(lit);

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, vec3(0.0));
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            lit += lpvFade * lpvSample;
        #endif

        color.rgb = albedo * lit;
    #endif

    // TODO: move to ambient lighting?
    color.rgb *= tex_occlusion;

    #ifdef MATERIAL_PBR_ENABLED
        float emission = mat_emission(specularData);
        TransformEmission(emission);

//        if (all(greaterThan(vIn.lmcoord, vec2(0.99)))) emission = 40.0;
//        if (vIn.lmcoord.x > 0.99 && vIn.lmcoord.y > 0.99) emission = 40.0;

        color.rgb += albedo * emission;
    #endif

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        #ifdef RENDER_TRANSLUCENT
            color.a *= vIn.chunkFade;
        #else
            fogF = max(fogF, 1.0 - vIn.chunkFade);
        #endif
    #endif

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogColor(skyColorL, fogColorL, localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    outFinal = color;

    #ifdef DEFERRED_NORMAL_ENABLED
        outGeoNormal = 0u;
        outTexNormal = 0u;
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outReflectSpecular = uvec2(0u);
    #endif
}
