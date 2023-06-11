#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec3 vPos;
in vec3 vLocalPos;
in vec4 vColor;
in float geoNoL;
in vec3 vBlockLight;

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float near;
uniform float far;

uniform int fogShape;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

uniform float rainStrength;
uniform float blindness;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    // #ifdef SHADOW_COLORED
    //     uniform sampler2D shadowtex1;
    // #endif

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif
    
    uniform vec3 shadowLightPosition;

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

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
    uniform int isEyeInWater;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"

#include "/lib/material/specular.glsl"

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
        #include "/lib/shadows/cascaded_render.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
        #include "/lib/shadows/basic_render.glsl"
    #endif

    #include "/lib/shadows/common_render.glsl"
#endif

#if !(defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED)
    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/buffers/collissions.glsl"
            #include "/lib/lighting/voxel/collisions.glsl"
            #include "/lib/lighting/voxel/tinting.glsl"
            #include "/lib/lighting/voxel/tracing.glsl"
        #endif
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/items.glsl"
    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #if LPV_SIZE > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
    #endif

    #include "/lib/world/sky.glsl"
    #include "/lib/lighting/basic_hand.glsl"
    #include "/lib/lighting/basic.glsl"

    #ifdef VL_BUFFER_ENABLED
        #include "/lib/world/volumetric_fog.glsl"
    #endif
#endif


#if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    /* RENDERTARGETS: 1,2,3,14 */
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    #if MATERIAL_SPECULAR != SPECULAR_NONE
        layout(location = 3) out vec4 outDeferredRough;
    #endif
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

float linear_fog_fade(const in float vertexDistance, const in float fogStart, const in float fogEnd) {
    //if (vertexDistance <= fogStart) return 1.0;
    //else if (vertexDistance >= fogEnd) return 0.0;

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

void main() {
    vec4 final = texture(gtexture, texcoord) * vColor;

    if (final.a < 0.2) {
        discard;
        return;
    }

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor();
        #else
            shadowColor = vec3(GetFinalShadowFactor());
        #endif
    #endif

    const float roughness = 0.9;
    const vec3 normal = vec3(0.0);
    const float metal_f0 = 0.04;
    const float occlusion = 1.0;
    const float emission = 0.0;
    const float sss = 0.0;

    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        //float fogF = GetVanillaFogFactor(vLocalPos);

        vec3 fogPos = vLocalPos;
        if (fogShape == 1) fogPos.y = 0.0;

        float viewDist = length(fogPos);
        //float newWidth = (fogEnd - fogStart) * 4.0;
        float fogF = 1.0 - linear_fog_fade(viewDist, fogStart*0.3, fogEnd * 2.0);

        outDeferredColor = final;
        outDeferredShadow = vec4(shadowColor + dither, 1.0);

        const vec2 lmcoord = vec2((0.5/16.0), (15.5/16.0));

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(normal, sss + dither));
        deferredData.g = packUnorm4x8(vec4(lmcoord, occlusion, emission) + dither);
        deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(normal, 1.0));
        outDeferredData = deferredData;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outDeferredRough = vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0);
        #endif
    #else
        final.rgb = RGBToLinear(final.rgb);
        float roughL = max(_pow2(roughness), ROUGH_MIN);

        final.rgb *= mix(vec3(1.0), shadowColor, ShadowBrightnessF);

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
            // TODO: Is this right?
            const vec3 blockLightDefault = vec3(0.0);

            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                SampleDynamicLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, roughL, metal_f0, sss, blockLightDefault);
            #endif

            SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, roughL, metal_f0, sss);
            
            final.rgb += blockDiffuse * vColor.rgb + blockSpecular;
        #endif

        vec3 fogPos = vLocalPos;
        if (fogShape == 1) fogPos.y = 0.0;

        float viewDist = length(fogPos);
        float newWidth = (fogEnd - fogStart) * 4.0;
        float fade = linear_fog_fade(viewDist, fogStart, fogStart + newWidth);
        final.a *= fade;

        #ifdef VL_BUFFER_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            vec3 localViewDir = normalize(vLocalPos);
            vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(length(vPos), far));
            final.rgb = final.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif
        
        outFinal = final;
    #endif
}
