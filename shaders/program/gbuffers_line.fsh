#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
flat in vec4 glcolor;
in vec3 vLocalPos;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

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

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#include "/lib/post/saturation.glsl"
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
        //vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        //fogColorFinal = LinearToRGB(fogColorFinal);

        outDeferredColor = color;
        outDeferredShadow = vec4(1.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(normal, 0.0));
        deferredData.g = packUnorm4x8(vec4(lmcoord + dither, 1.0, 1.0));
        deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(normal, 1.0));
        outDeferredData = deferredData;
    #else
        color.rgb = RGBToLinear(color.rgb);

		color.rgb *= texture(lightmap, lmcoord).rgb;// * shadowColor;

        vec3 localViewDir = normalize(vLocalPos);
        ApplyFog(color, vLocalPos, localViewDir);

        //ApplyPostProcessing(color.rgb);
		outFinal = color;
	#endif
}
