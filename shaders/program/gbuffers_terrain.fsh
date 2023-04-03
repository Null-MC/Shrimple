#define RENDER_TERRAIN
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vPos;
in vec3 vNormal;
in float geoNoL;
in float vLit;
in vec3 vBlockLight;
in vec3 vLocalPos;
in vec3 vLocalNormal;
flat in int vBlockId;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    in vec3 vLocalTangent;
    in float vTangentW;
#endif

#if MATERIAL_PARALLAX != PARALLAX_NONE
    in vec2 vLocalCoord;
    in vec3 tanViewPos;
    flat in mat2 atlasBounds;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        in vec3 tanLightPos;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D noisetex;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR
    uniform sampler2D specular;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if !defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform sampler2D lightmap;
#endif

#ifdef WORLD_SHADOW_ENABLED
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

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 upPosition;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
#endif

#if MATERIAL_PARALLAX != PARALLAX_NONE
    uniform ivec2 atlasSize;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#if !defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform int frameCounter;
    uniform float frameTimeCounter;
    uniform vec3 cameraPosition;

    uniform float blindness;

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
        uniform int heldItemId;
        uniform int heldItemId2;
        uniform int heldBlockLightValue;
        uniform int heldBlockLightValue2;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

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

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_items.glsl"
#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#if !(defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR)
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/dynamic.glsl"
    #endif

    #include "/lib/lighting/basic.glsl"
    #include "/lib/post/tonemap.glsl"
#endif


#if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR)
    /* RENDERTARGETS: 1,2,3,14 */
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    #ifdef MATERIAL_SPECULAR
        layout(location = 3) out vec4 outDeferredRough;
    #endif
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
    vec2 atlasCoord = texcoord;
    
    #if MATERIAL_PARALLAX != PARALLAX_NONE
        mat2 dFdXY = mat2(dFdx(atlasCoord), dFdy(atlasCoord));

        //bool isMissingNormal = all(lessThan(normalMap.xy, EPSILON2));
        //bool isMissingTangent = any(isnan(vLocalTangent));

        bool skipParallax = false;
        #ifdef RENDER_ENTITIES
            if (entityId == ENTITY_ITEM_FRAME || entityId == ENTITY_PHYSICSMOD_SNOW) skipParallax = true;
        #else
            if (vBlockId == BLOCK_LAVA) skipParallax = true;
        #endif

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);
        float viewDist = length(vPos);

        if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
            atlasCoord = GetParallaxCoord(dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }

        vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);
    #else
        vec4 color = texture(gtexture, texcoord);
    #endif

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    color.rgb *= glcolor.rgb;
    color.a = 1.0;

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    float sss = GetMaterialSSS(vBlockId, atlasCoord);
    float emission = GetMaterialEmission(vBlockId, atlasCoord);
    float roughness = 1.0;
    
    vec2 lmFinal = lmcoord;

    #ifdef MATERIAL_SPECULAR
        //roughness = textureGrad(specular, atlasCoord, dFdXY[0], dFdXY[1]).r;
        roughness = texture(specular, atlasCoord).r;
    #endif

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

        float skyGeoNoL = dot(localNormal, localLightDir);

        if (skyGeoNoL < EPSILON && sss < EPSILON) {
            shadowColor = vec3(0.0);
        }
        else {
            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                shadowColor = GetFinalShadowColor(sss);
            #else
                float shadowF = GetFinalShadowFactor(sss);
                shadowColor = vec3(shadowF);

                // lmFinal.y = saturate((lmFinal.y - (0.5/16.0)) / (15.0/16.0));
                // lmFinal.y = max(lmFinal.y, shadowF);
                // lmFinal.y = saturate(lmFinal.y * (15.0/16.0) + (0.5/16.0));
            #endif
        }
    #endif

    vec3 texNormal = localNormal;
    float parallaxShadow = 1.0;
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        //texNormal = vec3(0.0, 0.0, 1.0);
        bool isValidNormal = GetMaterialNormal(texcoord, texNormal);

        #if MATERIAL_PARALLAX != PARALLAX_NONE
            if (!skipParallax) {
                #if MATERIAL_PARALLAX == PARALLAX_SHARP
                    float dO = max(texDepth - traceCoordDepth.z, 0.0);

                    if (dO >= 0.5 / 255.0) {
                        texNormal = GetParallaxSlopeNormal(atlasCoord, dFdXY, traceCoordDepth.z, tanViewDir);
                        isValidNormal = true;
                    }
                #endif

                #if defined WORLD_SKY_ENABLED && MATERIAL_PARALLAX_SHADOW_SAMPLES > 0
                    if (traceCoordDepth.z + EPSILON < 1.0) {
                        vec3 tanLightDir = normalize(tanLightPos);
                        shadowColor *= GetParallaxShadow(traceCoordDepth, dFdXY, tanLightDir);
                    }
                #endif
            }
        #endif

        if (isValidNormal) {
            vec3 localTangent = normalize(vLocalTangent);
            mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);
            texNormal = matLocalTBN * texNormal;
        }
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if MATERIAL_NORMALS != NORMALMAP_NONE
            float skyNoL = dot(texNormal, localLightDir);
        #else
            float skyNoL = dot(localNormal, localLightDir);
        #endif

        #if MATERIAL_SSS != SSS_NONE
            skyNoL = mix(max(skyNoL, 0.0), abs(skyNoL), sss);
        #else
            skyNoL = max(skyNoL, 0.0);
        #endif

        shadowColor *= 1.2 * pow(skyNoL, 0.8);
    #endif

    #if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR)
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = GetVanillaFogFactor(vLocalPos);

        vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        fogColorFinal = LinearToRGB(fogColorFinal);

        outDeferredColor = color;
        outDeferredShadow = vec4(shadowColor, 1.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss));
        deferredData.g = packUnorm4x8(vec4(lmFinal + dither, glcolor.a + dither, emission));
        deferredData.b = packUnorm4x8(vec4(fogColorFinal, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(texNormal * 0.5 + 0.5, 1.0));
        outDeferredData = deferredData;

        #ifdef MATERIAL_SPECULAR
            outDeferredRough = vec4(vec3(roughness), 1.0);
        #endif
    #else
        vec3 blockLight = vBlockLight;
        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);
            GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, lmFinal.x, roughL, emission, sss);
            blockLight += blockDiffuse;
        #endif

        color.rgb = RGBToLinear(color.rgb);
        color.rgb = GetFinalLighting(color.rgb, blockLight, shadowColor, lmFinal, glcolor.a);

        ApplyFog(color, vLocalPos);

        ApplyPostProcessing(color.rgb);
        outFinal = color;
    #endif
}
