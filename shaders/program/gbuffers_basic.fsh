#define RENDER_BASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    // #ifdef RENDER_SHADOWS_ENABLED
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         vec3 shadowPos[4];
    //         flat int shadowTile;
    //     #else
    //         vec3 shadowPos;
    //     #endif
    // #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

// #if defined WORLD_SKY_ENABLED && defined SHADOW_CLOUD_ENABLED
//     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
//         uniform sampler3D TEX_CLOUDS;
//     #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
//         uniform sampler2D TEX_CLOUDS_VANILLA;
//     #endif
// #endif

// #if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE)
//     uniform sampler2D shadowcolor0;
// #endif

// #ifdef RENDER_SHADOWS_ENABLED
//     uniform sampler2D shadowtex0;
//     uniform sampler2D shadowtex1;

//     #ifdef SHADOW_ENABLE_HWCOMP
//         #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
//             uniform sampler2DShadow shadowtex1HW;
//         #else
//             uniform sampler2DShadow shadow;
//         #endif
//     #endif
// #endif

uniform int worldTime;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform ivec2 eyeBrightnessSmooth;
uniform int frameCounter;

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;

    #ifdef SHADOW_ENABLED
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef WORLD_SKY_ENABLED
    uniform float rainStrength;
    uniform float skyRainStrength;
    uniform vec3 sunPosition;
    uniform vec3 skyColor;

    #if SKY_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"

#include "/lib/fog/fog_common.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
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

// #ifdef WORLD_SKY_ENABLED
//     #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
//         #include "/lib/lighting/scatter_transmit.glsl"
//         #include "/lib/clouds/cloud_vars.glsl"
//         #include "/lib/clouds/cloud_custom.glsl"
//     #endif
// #endif

// #ifdef RENDER_SHADOWS_ENABLED
//     #include "/lib/buffers/shadow.glsl"

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         #include "/lib/shadows/cascaded/common.glsl"
//         #include "/lib/shadows/cascaded/render.glsl"
//     #else
//         #include "/lib/shadows/distorted/common.glsl"
//         #include "/lib/shadows/distorted/render.glsl"
//     #endif

//     #include "/lib/shadows/render.glsl"
// #endif


#if !defined RENDER_TRANSLUCENT && ((defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED) || (defined RENDER_SHADOWS_ENABLED && SHADOW_BLUR_SIZE > 0))
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    layout(location = 3) out vec3 outDeferredTexNormal;

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
	vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;
	
	const vec3 normal = vec3(0.0);
	const float sss = 0.0;

    vec3 shadowColor = vec3(1.0);
    // #ifdef RENDER_SHADOWS_ENABLED
    //     #ifndef IRIS_FEATURE_SSBO
    //        vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    //     #endif

    //     float skyGeoNoL = 1.0;//dot(localNormal, localSkyLightDirection);

    //     if (skyGeoNoL < EPSILON && sss < EPSILON) {
    //         shadowColor = vec3(0.0);
    //     }
    //     else {
    //         float viewDist = length(vIn.localPos);
    //         float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

    //         #ifdef SHADOW_COLORED
    //             shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
    //         #else
    //             float shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
    //             shadowColor = vec3(shadowF);

    //             // lmFinal.y = max(lmFinal.y, shadowF);
    //         #endif
    //     }
    // #endif

    #if !defined RENDER_TRANSLUCENT && ((defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED) || (defined RENDER_SHADOWS_ENABLED && SHADOW_BLUR_SIZE > 0))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        const float roughness = 1.0;
        const float metal_f0 = 0.04;
        const float porosity = 0.0;

        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif
        //vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        //fogColorFinal = LinearToRGB(fogColorFinal);

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);
        outDeferredTexNormal = normal;

        outDeferredData.r = packUnorm4x8(vec4(normal, 0.0));
        outDeferredData.g = packUnorm4x8(vec4(vIn.lmcoord + dither, 1.0, 0.0));
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        color.rgb = RGBToLinear(color.rgb);

        vec2 lmFinal = LightMapTex(vIn.lmcoord);
		color.rgb *= texture(lightmap, lmFinal).rgb * shadowColor;

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 localViewDir = normalize(vIn.localPos);
            ApplyFog(color, vIn.localPos, localViewDir);
        #endif

		outFinal = color;
	#endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(0.0);
    #endif
}
