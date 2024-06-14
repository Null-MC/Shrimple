#define RENDER_OCEAN
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;

    vec3 physics_localPosition;
    float physics_localWaviness;

    vec3 viewPos_T;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        vec3 lightPos_T;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D depthtex1;
    uniform sampler2D BUFFER_FINAL;
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#ifdef WORLD_SKY_ENABLED
    #ifdef WORLD_WETNESS_ENABLED
        uniform sampler3D TEX_RIPPLES;
    #endif

    #if defined SHADOW_CLOUD_ENABLED || (MATERIAL_REFLECTIONS != REFLECT_NONE && defined MATERIAL_REFLECT_CLOUDS)
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            uniform sampler3D TEX_CLOUDS;
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS_VANILLA;
        #endif
    #endif
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D texDepthNear;
#endif

#ifdef RENDER_SHADOWS_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #ifdef SHADOW_COLORED
        uniform sampler2D shadowcolor0;
    #endif
    
    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
#endif

// uniform ivec2 atlasSize;

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec2 viewSize;
uniform float viewWidth;
uniform vec3 upPosition;
uniform int isEyeInWater;
uniform vec3 skyColor;
uniform float near;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindnessSmooth;
uniform ivec2 eyeBrightnessSmooth;

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform float aspectRatio;
    uniform vec2 pixelSize;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    uniform float wetness;

    uniform float skyRainStrength;
    uniform float skyWetnessSmooth;

    #ifdef IS_IRIS
        uniform float lightningStrength;
        uniform float cloudHeight;
        uniform float cloudTime;
    #endif
#endif

uniform vec3 WaterAbsorbColor;
uniform vec3 WaterScatterColor;
uniform float waterDensitySmooth;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/tbn.glsl"

#include "/lib/lighting/scatter_transmit.glsl"
#include "/lib/lighting/hg.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/clouds/cloud_common.glsl"
    #include "/lib/world/lightning.glsl"
    
    // #ifdef WORLD_WETNESS_ENABLED
    //     #include "/lib/world/wetness.glsl"
    //     #include "/lib/world/wetness_ripples.glsl"
    // #endif
#endif

#include "/lib/world/water.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#include "/lib/fog/fog_render.glsl"

#ifdef WORLD_SKY_ENABLED
    #if defined SHADOW_CLOUD_ENABLED || (MATERIAL_REFLECTIONS != REFLECT_NONE && defined MATERIAL_REFLECT_CLOUDS)
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            #include "/lib/clouds/cloud_custom.glsl"
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            #include "/lib/clouds/cloud_vanilla.glsl"
        #endif
    #endif
#endif

#ifdef RENDER_SHADOWS_ENABLED
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/render.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/render.glsl"
    #endif
    
    #include "/lib/shadows/render.glsl"
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/fresnel.glsl"

#if !((defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED)
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #ifdef IS_LPV_ENABLED
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif

    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
    #include "/lib/lighting/voxel/items.glsl"
    #include "/lib/lighting/sampling.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"

#include "/lib/physics_mod/ocean.glsl"

#if !((defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED)
    #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
        
        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #include "/lib/lighting/reflections.glsl"
    #endif

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/lighting/sky_lighting.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/traced.glsl"
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif

    #include "/lib/lighting/basic_hand.glsl"

    #ifdef VL_BUFFER_ENABLED
        #include "/lib/lighting/hg.glsl"
        #include "/lib/fog/fog_volume.glsl"
    #endif
#endif


#if (defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED
    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,2,3,9,7 */
        layout(location = 4) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,2,3,9 */
    #endif

    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    layout(location = 3) out vec4 outDeferredTexNormal;
#else
    layout(location = 0) out vec4 outFinal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 0,7 */
        layout(location = 1) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

void main() {
    mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));
    bool isWater = true;
    float viewDist = length(vIn.localPos);

    vec3 worldPos = vIn.localPos + cameraPosition;
    vec3 texNormal = vec3(0.0, 0.0, 1.0);
    vec2 atlasCoord = vIn.texcoord;
    // vec2 localCoord = vIn.localCoord;
    vec2 waterUvOffset = vec2(0.0);
    vec2 lmFinal = vIn.lmcoord;

    #ifdef DISTANT_HORIZONS
        // TODO: discard if DH opaque nearer?
    #endif

    if (!gl_FrontFacing && isEyeInWater != 1) {
        discard;
        return;
    }

    vec3 localViewDir = normalize(vIn.localPos);

    vec3 localNormal = normalize(vIn.localNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    float oceanFoam = 0.0;

    //if (abs(vIn.localNormal.y) > 0.5) {
        float waviness = max(vIn.physics_localWaviness, 0.02);
        WavePixelData wave = physics_wavePixel(vIn.physics_localPosition.xz, waviness, physics_iterationsNormal, physics_gameTime);
        waterUvOffset = wave.worldPos - vIn.physics_localPosition.xz;
        texNormal = wave.normal.xzy;
        oceanFoam = wave.foam;

        // if (localNormal.y >= 1.0 - EPSILON) {
        //     localCoord += waterUvOffset;
        //     atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
        // }
    //}

    #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
        SetWaterDepth(viewDist);
    #endif

    vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0] * MIP_BIAS, dFdXY[1] * MIP_BIAS);

    #ifndef WATER_TEXTURED
        color = vec4(vec3(1.0), WorldWaterOpacityF);
    #endif
    
    color.a = max(color.a, 0.02);
    color.a = mix(color.a, 1.0, oceanFoam);

    vec3 albedo = RGBToLinear(color.rgb * vIn.color.rgb);
    albedo = mix(albedo, vec3(1.0), oceanFoam);

    float distF = 16.0 / (viewDist + 16.0);

    float metal_f0  = mix(0.02, 0.04, oceanFoam);
    float roughness = mix(WATER_ROUGH, 0.50, oceanFoam);
    float sss = oceanFoam;

    const float occlusion = 1.0;
    const float emission = 0.0;
    const float porosity = 0.0;
    
    vec3 shadowColor = vec3(1.0);
    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #endif

        float skyGeoNoL = dot(localNormal, localSkyLightDirection);

        if (skyGeoNoL < EPSILON && sss < EPSILON) {
            shadowColor = vec3(0.0);
        }
        else {
            #ifdef DISTANT_HORIZONS
                float shadowDistFar = min(shadowDistance, 0.5*dhFarPlane);
            #else
                float shadowDistFar = min(shadowDistance, far);
            #endif

            vec3 shadowViewPos = (shadowModelViewEx * vec4(vIn.localPos, 1.0)).xyz;
            float shadowViewDist = length(shadowViewPos.xy);
            float shadowFade = 1.0 - smoothstep(shadowDistFar - 20.0, shadowDistFar, shadowViewDist);

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #else
                shadowFade *= step(-1.0, vIn.shadowPos.z);
                shadowFade *= step(vIn.shadowPos.z, 1.0);
            #endif
            
            shadowFade = 1.0 - shadowFade;

            #ifdef SHADOW_COLORED
                shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
            #else
                shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
            #endif

            #ifndef LIGHT_LEAK_FIX
                float lightF = min(luminance(shadowColor), 1.0);
                lmFinal.y = clamp(lmFinal.y, lightF, 1.0);
            #endif
        }
    #endif

    // #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    //     #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
    //         // if (!isWater)
    //         //     ApplyWetnessPuddles(texNormal, vIn.localPos, skyWetness, porosity, puddleF);

    //         #if WORLD_WETNESS_PUDDLES != PUDDLES_BASIC
    //             if (skyRainStrength > EPSILON)
    //                 ApplyWetnessRipples(texNormal, rippleNormalStrength);
    //         #endif
    //     #endif
    // #endif

    //vec3 localTangent = normalize(vIn.localTangent.xyz);
    //mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent, vIn.localTangent.w);
    //texNormal = matLocalTBN * texNormal;

    //vec3 texViewNormal = mat3(gbufferModelView) * texNormal;
    
    if (!gl_FrontFacing) texNormal = -texNormal;

    float roughL = _pow2(roughness);

    #if (defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        color.rgb = LinearToRGB(albedo);

        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        // TODO: should this also apply to forward?
        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            //vec3 f0 = GetMaterialF0(albedo, metal_f0);
            float skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
            float skyF = F_schlickRough(skyNoVm, 0.02, roughL);
            //color.a = min(color.a + skyF, 1.0);
            color.a = clamp(color.a, skyF * MaterialReflectionStrength, 1.0);

            //color.rgb = vec3(0.0);
            color.rgb *= 1.0 - skyF;
        #endif

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 1.0);
        outDeferredTexNormal = vec4(texNormal * 0.5 + 0.5, 1.0);

        outDeferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        vec3 diffuseFinal = vec3(0.0), specularFinal = vec3(0.0);
        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, lmFinal, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

            #ifdef WORLD_SKY_ENABLED
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, occlusion, sss, tir);
            #else
                diffuseFinal += WorldAmbientF;
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            diffuseFinal += emission * MaterialEmissionF;

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            GetVanillaLighting(diffuseFinal, lmFinal);

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, tir);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
            color.a = min(color.a + luminance(specularFinal), 1.0);
        #endif

        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            float skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
            float skyF = F_schlickRough(skyNoVm, 0.02, roughL);
            color.a = max(color.a, skyF);
        #endif

        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vIn.localPos, localViewDir);
        #endif

        #ifdef VL_BUFFER_ENABLED
            #ifdef WORLD_WATER_ENABLED
                VolumetricPhaseFactors phaseF = (isEyeInWater == 1)
                    ? WaterPhaseF : GetVolumetricPhaseFactors();
            #else
                VolumetricPhaseFactors phaseF = GetVolumetricPhaseFactors();
            #endif

            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            float farMax = min(viewDist - 0.05, far);
            vec4 vlScatterTransmit = GetVolumetricLighting(phaseF, localViewDir, localSunDirection, near, farMax, isWater);
            color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        outFinal = color;
    #endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(vec3(0.0), 1.0);
    #endif
}
