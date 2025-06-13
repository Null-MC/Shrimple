#define RENDER_PHY_LIQUID
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out float gl_FragDepth;

uniform sampler2D Sampler0;
uniform sampler2D physics_depth;

uniform vec4 physics_waterBounds;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int isEyeInWater;
uniform int frameCounter;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;


#include "/lib/sampling/ign.glsl"

#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/fog/fog_common.glsl"

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


#if (defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED
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


#ifdef WATER_TEXTURED
    float physics_remap(float value, float oldMin, float oldMax, float newMin, float newMax) {
        return newMin + (value - oldMin) / (oldMax - oldMin) * (newMax - newMin);
    }

    vec2 physics_waterCoords(vec3 localPos, vec3 normal) {
        vec3 worldPos = localPos + cameraPosition;
        vec3 n = abs(normalize(normal));

        if (n.x > n.y && n.x > n.z) {
            return vec2(
                physics_remap(fract(worldPos.y), 0.0, 1.0,
                    physics_waterBounds.x, physics_waterBounds.y),
                physics_remap(fract(worldPos.z), 0.0, 1.0,
                    physics_waterBounds.z, physics_waterBounds.w));
        } else if (n.y > n.z) {
            return vec2(
                physics_remap(fract(worldPos.x), 0.0, 1.0,
                    physics_waterBounds.x, physics_waterBounds.y),
                physics_remap(fract(worldPos.z), 0.0, 1.0,
                    physics_waterBounds.z, physics_waterBounds.w));
        }

        return vec2(
            physics_remap(fract(worldPos.x), 0.0, 1.0,
                physics_waterBounds.x, physics_waterBounds.y),
            physics_remap(fract(worldPos.y), 0.0, 1.0,
                physics_waterBounds.z, physics_waterBounds.w));
    }
#endif


void main() {
    vec2 uv = gl_FragCoord.xy / textureSize(physics_depth, 0);
    float physics_fragZ = textureLod(physics_depth, uv, 0).r;
    gl_FragDepth = physics_fragZ;

    vec3 ndcPos = vec3(uv, physics_fragZ) * 2.0 - 1.0;
    vec3 viewPos = unproject(gbufferProjectionInverse, ndcPos);

    vec3 dX = dFdx(viewPos);
    vec3 dY = dFdy(viewPos);

    vec3 viewNormal = vec3(0.0, 0.0, 1.0);
    if (_lengthSq(dX) > 0.0 && _lengthSq(dY) > 0.0) {
        dX = normalize(dX);
        dY = normalize(dY);
        viewNormal = normalize(cross(dX, dY));

        //viewNormal.z = pow(viewNormal.z, 0.2);// * sign(viewNormal.z);
        //viewNormal.z = pow(saturate(viewNormal.z*2.0 - 1.0), 0.25);
        viewNormal = normalize(viewNormal);
    }

    vec3 localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    if (physics_fragZ == 1.0) {discard; return;}

    #if (defined MATERIAL_REFRACT_ENABLED || defined DEFER_TRANSLUCENT) && defined DEFERRED_BUFFER_ENABLED
        const float roughness = 0.04;
        const float metal_f0 = 0.02;
        const float sss = 0.0;
        const float porosity = 0.0;
        const float occlusion = 1.0;
        const float emission = 0.0;
        const float parallaxShadow = 1.0;
        const vec2 lmFinal = vec2(0.0, 1.0);
        const bool isWater = true;

        vec4 color = vec4(vec3(1.0), Water_OpacityF);

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        outDeferredColor = color + dither;
        outDeferredTexNormal = localNormal * 0.5 + 0.5;

        const vec3 geoNormal = vec3(0.0, 0.0, -1.0);

        outDeferredData.r = packUnorm4x8(vec4(geoNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(isWater ? 1.0 : 0.0, parallaxShadow, 0.0, 0.0) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        const vec4 WaterTint = vec4(0.24705884, 0.46274513, 0.8941177, 1.0);

        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        #ifdef WATER_TEXTURED
            vec2 geo_uv = physics_waterCoords(localPos, viewNormal);
            vec4 color = textureLod(Sampler0, geo_uv, 0) * WaterTint;
        #else
            vec4 color = WaterTint;
        #endif

        color.rgb = RGBToLinear(color.rgb);
        color.a = 1.0;

        // TODO: some kind of basic lighting

        #ifdef SKY_BORDER_FOG_ENABLED
            //vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
            vec3 localViewDir = normalize(localPos);

            ApplyFog(color, localPos, localViewDir);
        #endif

        outFinal = color;
    #endif

    #ifdef EFFECT_TAA_ENABLED
        const float waterMask = 1.0;
        outVelocity = vec4(vec3(0.0), waterMask);
    #endif
}
