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

uniform int renderStage;
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
    uniform float weatherStrength;
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
    layout(location = 1) out uvec4 outDeferredData;
    layout(location = 2) out vec3 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,3,9,7 */
        layout(location = 3) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,3,9 */
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
	vec4 color = vIn.color;
    float emission = 0.0;

    if (renderStage == MC_RENDER_STAGE_OUTLINE) {
        #if BLOCK_OUTLINE_TYPE == BLOCK_OUTLINE_CONSTRUCTION
            const float interval = 20.0;
            vec3 worldPos = vIn.localPos + cameraPosition;
            float offset = sumOf(worldPos) * interval;
            color.rgb = step(1.0, mod(offset, 2.0)) * vec3(1.0, 1.0, 0.0);
        #else
            color.rgb = vec3(BLOCK_OUTLINE_COLOR_R, BLOCK_OUTLINE_COLOR_G, BLOCK_OUTLINE_COLOR_B) / 255.0;
        #endif

        color.a = 1.0;
        emission = BLOCK_OUTLINE_EMISSION / 100.0;
    }
    else {
        color *= texture(gtexture, vIn.texcoord);
    }

    if (color.a < alphaTestRef) {discard; return;}

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        const vec3 normal = vec3(0.0);
        const float occlusion = 0.0;
        const float roughness = 1.0;
        const float metal_f0 = 0.0;
        const float porosity = 0.0;
        const float sss = 0.0;
        const float isWater = 0.0;
        const float parallaxShadow = 1.0;

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        
        outDeferredColor = color + dither;
        outDeferredTexNormal = normal;

        outDeferredData.r = packUnorm4x8(vec4(normal, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(vIn.lmcoord, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(isWater, parallaxShadow, 0.0, 0.0) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        color.rgb = RGBToLinear(color.rgb);

        vec4 final = color;

        vec2 lmFinal = LightMapTex(vIn.lmcoord);
		final.rgb *= texture(lightmap, lmFinal).rgb;

        final.rgb += color * emission * MaterialEmissionF;

        #ifdef SKY_BORDER_FOG_ENABLED
            vec3 localViewDir = normalize(vIn.localPos);
            ApplyFog(final, vIn.localPos, localViewDir);
        #endif

		outFinal = final;
	#endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(0.0);
    #endif
}
