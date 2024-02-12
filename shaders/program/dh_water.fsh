#define RENDER_WATER_DH
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat uint materialId;

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        vec3 physics_localPosition;
        float physics_localWaviness;
    #endif

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
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

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (LIGHTING_MODE > LIGHTING_MODE_BASIC || LPV_SHADOW_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#ifdef WORLD_SKY_ENABLED
    // #ifdef WORLD_WETNESS_ENABLED
    //     uniform sampler3D TEX_RIPPLES;
    // #endif

    #if defined SHADOW_CLOUD_ENABLED || (MATERIAL_REFLECTIONS != REFLECT_NONE && defined MATERIAL_REFLECT_CLOUDS)
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            uniform sampler3D TEX_CLOUDS;
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS_VANILLA;
        #endif
    #endif
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
    uniform sampler2D shadowcolor0;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D texDepthNear;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;
    
    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D depthtex0;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec2 viewSize;
uniform float viewWidth;
uniform vec3 upPosition;
uniform int isEyeInWater;
uniform vec3 skyColor;
uniform float near;
uniform float far;
uniform float farPlane;

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

    uniform float cloudHeight;
    
    #if SKY_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
        uniform float cloudTime;
    #endif

    #ifdef IS_IRIS
        uniform float lightningStrength;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

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

// #ifdef VL_BUFFER_ENABLED
//     uniform mat4 shadowModelView;
// #endif

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
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
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

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
    #include "/lib/clouds/cloud_vars.glsl"
    #include "/lib/world/lightning.glsl"
    
    // #ifdef WORLD_WETNESS_ENABLED
    //     // #include "/lib/material/porosity.glsl"
    //     #include "/lib/world/wetness.glsl"
    // #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

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

#ifdef WORLD_SHADOW_ENABLED
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

    #if defined IS_TRACING_ENABLED
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        // #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        //     #include "/lib/lighting/voxel/light_mask.glsl"
        // #endif
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
// #include "/lib/material/specular.glsl"

#ifdef WORLD_WATER_ENABLED
    #ifdef PHYSICS_OCEAN
        #include "/lib/physics_mod/ocean.glsl"
    #elif WATER_WAVE_SIZE > 0
        #include "/lib/world/water_waves.glsl"
    #endif
#endif

#if !((defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED)
    #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (LIGHTING_MODE > LIGHTING_MODE_BASIC || LPV_SHADOW_SAMPLES > 0)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        // #if defined MATERIAL_REFLECT_CLOUDS && defined WORLD_SKY_ENABLED && defined IS_IRIS
        //     #include "/lib/shadows/clouds.glsl"
        // #endif
    
        #include "/lib/lighting/reflections.glsl"
    #endif

    #include "/lib/lighting/sky_lighting.glsl"

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/basic.glsl"
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif

    #include "/lib/lighting/basic_hand.glsl"

    #ifdef VL_BUFFER_ENABLED
        #include "/lib/fog/fog_volume.glsl"
    #endif
#endif


#if (defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    layout(location = 3) out vec4 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,2,3,9,7 */
        layout(location = 4) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,2,3,9 */
    #endif
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
    float viewDist = length(vIn.localPos);
    bool isWater = (vIn.materialId == DH_BLOCK_WATER);

    // mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));
    vec3 worldPos = vIn.localPos + cameraPosition;
    //vec3 texNormal = vec3(0.0, 0.0, 1.0);
    // vec2 atlasCoord = vIn.texcoord;
    // vec2 localCoord = vIn.localCoord;
    // bool skipParallax = false;
    // vec2 waterUvOffset = vec2(0.0);
    vec2 lmFinal = vIn.lmcoord;

    vec3 localNormal = normalize(vIn.localNormal);
    //vec3 localNormal = normalize(cross(dFdx(vIn.localPos), dFdy(vIn.localPos)));
    if (!gl_FrontFacing) localNormal = -localNormal;
    vec3 texNormal = localNormal;

    #ifdef WORLD_WATER_ENABLED
        float oceanFoam = 0.0;

        if (isWater && abs(localNormal.y) > 0.5) {
            #ifdef PHYSICS_OCEAN
                float waviness = max(vIn.physics_localWaviness, 0.02);
                WavePixelData wave = physics_wavePixel(vIn.physics_localPosition.xz, waviness, physics_iterationsNormal, physics_gameTime);
                // waterUvOffset = wave.worldPos - vIn.physics_localPosition.xz;
                texNormal = wave.normal;
                oceanFoam = wave.foam;
            #elif WATER_WAVE_SIZE > 0
                float waveDistF = 32.0 / (32.0 + viewDist);

                // vec2 waterUvOffset;
                // texNormal = water_waveNormal(worldPos.xz, vIn.lmcoord.y, viewDist, waterUvOffset).xzy;
                float time = GetAnimationFactor();
                vec3 waveOffset = GetWaveHeight(cameraPosition + vIn.localPos, vIn.lmcoord.y, time, WATER_WAVE_DETAIL);
                vec3 wavePos = vIn.localPos;// + waveOffset;// * waveDistF;
                wavePos.y += waveOffset.y * waveDistF;

                vec3 dX = dFdx(wavePos.xzy);
                vec3 dY = dFdy(wavePos.xzy);
                texNormal = normalize(cross(dY, dX)).xzy;
            #endif
        }
    #endif

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
    float depthL = linearizeDepthFast(depth, near, farPlane);
    float depthDhL = linearizeDepthFast(gl_FragCoord.z, dhNearPlane, dhFarPlane);
    if (depthL < depthDhL && depth < 1.0) {discard; return;}

    // if (isWater && !gl_FrontFacing)
    //     texNormal = -texNormal;

    //float viewDistXZ = length(vIn.localPos.xz);
    if (viewDist < dh_clipDistF * far) {
        discard;
        return;
    }

    #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
        if (isWater) {//&& (isEyeInWater != 1 || !gl_FrontFacing))
            SetWaterDepth(viewDist);
            // discard;
            // return;
        }
    #endif

    float porosity = 0.0;
    // #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    //     float surface_roughness, surface_metal_f0;
    //     // GetMaterialSpecular(vIn.blockId, vIn.texcoord, dFdXY, surface_roughness, surface_metal_f0);
    //     surface_roughness = 0.95;
    //     surface_metal_f0 = 0.04;

    //     // porosity = GetMaterialPorosity(vIn.texcoord, dFdXY, surface_roughness, surface_metal_f0);
    //     porosity = 0.75;
    //     float skyWetness = GetSkyWetness(worldPos, localNormal, lmFinal);//, vBlockId);
    //     float puddleF = GetWetnessPuddleF(skyWetness, porosity);

    //     #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
    //         vec4 rippleNormalStrength = vec4(0.0);
    //         if (isWater) puddleF = 1.0;

    //         // TODO: this also needs to check vertex offset!
    //         if ((localNormal.y >= 1.0 - EPSILON) || (localNormal.y <= -1.0 + EPSILON)) {
    //             rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);
    //             // localCoord += rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
    //             // atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
    //         }
    //     #endif
    // #endif

    vec4 color = vIn.color;

    #ifdef WORLD_WATER_ENABLED
        if (isWater) {
            #if WATER_SURFACE_TYPE == WATER_COLORED
                // color.rgb = vIn.color.rgb;
                color.a = 1.0;
            #endif

            color.a *= WorldWaterOpacityF;
            color.a = max(color.a, 0.02);

            color = mix(color, vec4(1.0), oceanFoam);
        }
    #endif

    vec3 localViewDir = normalize(vIn.localPos);
    vec3 albedo = RGBToLinear(color.rgb);
    float occlusion = 1.0;

    float roughness = 0.1;
    float metal_f0 = 0.04;
    const float sss = 0.0;
    const float emission = 0.0;

    #ifdef WORLD_WATER_ENABLED
        if (isWater) {
            float distF = 16.0 / (viewDist + 16.0);
            float waterRough = 0.0;//mix(0.3 * lmcoord.y, 0.06, distF);

            metal_f0  = mix(0.02, 0.04, oceanFoam);
            roughness = mix(waterRough, 0.50, oceanFoam);
        }
    #endif

    // if (!isWater) roughness = 0.1;
    
    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

    // #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    //     if (!isWater)
    //         ApplySkyWetness(albedo, roughness, porosity, skyWetness, puddleF);
    // #endif

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
            if (isWater) {
                //vec3 f0 = GetMaterialF0(albedo, metal_f0);
                float skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
                float skyF = F_schlickRough(skyNoVm, 0.02, roughL);
                //color.a = min(color.a + skyF, 1.0);
                color.a = clamp(color.a, skyF * MaterialReflectionStrength, 1.0);

                //color.rgb = vec3(0.0);
                color.rgb *= 1.0 - skyF;
            }
        #endif

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, isWater ? 1.0 : 0.0);
        outDeferredTexNormal = vec4(texNormal * 0.5 + 0.5, 1.0);

        outDeferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        #if LIGHTING_MODE > LIGHTING_MODE_BASIC
            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);

            blockDiffuse += emission * MaterialEmissionF;
            
            GetFinalBlockLighting(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, sss);

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            vec3 skyDiffuse = vec3(0.0);
            vec3 skySpecular = vec3(0.0);

            #ifdef WORLD_SKY_ENABLED
                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, vIn.localPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, occlusion, sss, false);
            #endif

            vec3 diffuseFinal = blockDiffuse + skyDiffuse;
            vec3 specularFinal = blockSpecular + skySpecular;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                #if MATERIAL_SPECULAR == SPECULAR_LABPBR
                    if (IsMetal(metal_f0))
                        diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                #else
                    diffuseFinal *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
                #endif

                specularFinal *= GetMetalTint(albedo, metal_f0);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
            color.a = min(color.a + luminance(specularFinal), 1.0);
        #else
            vec3 diffuse, specular = vec3(0.0);
            GetVanillaLighting(diffuse, lmFinal);

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuse, specular, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, tir);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuse, specular, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
            color.a = min(color.a + luminance(specular), 1.0);
        #endif

        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            if (isWater) {
                float skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
                float skyF = F_schlickRough(skyNoVm, 0.02, roughL);
                color.a = max(color.a, skyF);
            }
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
        outVelocity = vec4(vec3(0.0), isWater ? 1.0 : 0.0);
    #endif
}
