#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    flat vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

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

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform float rainStrength;
    uniform float skyRainStrength;
    uniform vec3 sunPosition;
    uniform vec3 skyColor;
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

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/lightmap.glsl"

#include "/lib/world/common.glsl"

#ifdef SKY_BORDER_FOG_ENABLED
    #include "/lib/fog/fog_common.glsl"
    
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
    #endif
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
    #endif

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        #include "/lib/fog/fog_custom.glsl"
        
        #ifdef WORLD_WATER_ENABLED
            #include "/lib/fog/fog_water_custom.glsl"
        #endif
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif

    #include "/lib/fog/fog_render.glsl"
#endif


#if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
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

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        const vec3 normal = vec3(0.0);
        const float occlusion = 0.0;
        const float roughness = 1.0;
        const float metal_f0 = 0.0;
        const float emission = 0.0;
        const float porosity = 0.0;
        const float sss = 0.0;

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        
        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(0.0);
        outDeferredTexNormal = normal;

        outDeferredData.r = packUnorm4x8(vec4(normal, sss));
        outDeferredData.g = packUnorm4x8(vec4(vIn.lmcoord + dither, occlusion, emission));
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0));
    #else
        color.rgb = RGBToLinear(color.rgb);

        vec2 lmFinal = LightMapTex(vIn.lmcoord);
		color.rgb *= texture(lightmap, lmFinal).rgb;

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
