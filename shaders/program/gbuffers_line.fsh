#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
flat in vec4 glcolor;
in vec3 vLocalPos;

// #ifdef WORLD_SHADOW_ENABLED
//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         in vec3 shadowPos[4];
//         flat in int shadowTile;
//     #elif SHADOW_TYPE != SHADOW_TYPE_NONE
//         in vec3 shadowPos;
//     #endif
// #endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;

// #if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
//     uniform sampler2D shadowcolor0;
// #endif

// #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
//     uniform sampler2D shadowtex0;
//     uniform sampler2D shadowtex1;

//     #ifdef SHADOW_ENABLE_HWCOMP
//         #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
//             uniform sampler2DShadow shadowtex0HW;
//         #else
//             uniform sampler2DShadow shadow;
//         #endif
//     #endif
// #else
//     uniform int worldTime;
// #endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

// #ifdef WORLD_SHADOW_ENABLED
//     uniform vec3 shadowLightPosition;

//     #if SHADOW_TYPE != SHADOW_TYPE_NONE
//         uniform mat4 shadowProjection;
//     #endif
// #endif

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/buffers/shadow.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

// #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
//     #include "/lib/buffers/shadow.glsl"

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         #include "/lib/shadows/cascaded.glsl"
//         #include "/lib/shadows/cascaded_render.glsl"
//     #else
//         #include "/lib/shadows/basic.glsl"
//         #include "/lib/shadows/basic_render.glsl"
//     #endif

//     #include "/lib/shadows/common_render.glsl"
// #endif

#include "/lib/post/tonemap.glsl"


#if !defined RENDER_TRANSLUCENT && ((defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR))
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

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;
	
	const vec3 normal = vec3(0.0);
	const float sss = 0.0;

    // vec3 shadowColor = vec3(1.0);
    // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //     vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    //     float skyGeoNoL = 1.0;//dot(localNormal, localLightDir);

    //     if (skyGeoNoL < EPSILON && sss < EPSILON) {
    //         shadowColor = vec3(0.0);
    //     }
    //     else {
    //         #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
    //             shadowColor = GetFinalShadowColor(sss);
    //         #else
    //             float shadowF = GetFinalShadowFactor(sss);
    //             shadowColor = vec3(shadowF);

    //             // lmFinal.y = saturate((lmFinal.y - (0.5/16.0)) / (15.0/16.0));
    //             // lmFinal.y = max(lmFinal.y, shadowF);
    //             // lmFinal.y = saturate(lmFinal.y * (15.0/16.0) + (0.5/16.0));
    //         #endif
    //     }
    // #endif

    #if !defined RENDER_TRANSLUCENT && ((defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = GetVanillaFogFactor(vLocalPos);
        vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        fogColorFinal = LinearToRGB(fogColorFinal);

        outDeferredColor = color;
        outDeferredShadow = vec4(1.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(normal, 0.0));
        deferredData.g = packUnorm4x8(vec4(lmcoord, 1.0, 1.0));
        deferredData.b = packUnorm4x8(vec4(fogColorFinal, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(normal, 1.0));
        outDeferredData = deferredData;
    #else
        color.rgb = RGBToLinear(color.rgb);

		color.rgb *= texture(lightmap, lmcoord).rgb;// * shadowColor;

        ApplyFog(color, vLocalPos);

        ApplyPostProcessing(color.rgb);
		outFinal = color;
	#endif
}
