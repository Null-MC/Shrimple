#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

#if ATMOS_VL_SAMPLES > 0
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform sampler2D shadowtex0;

        #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #endif

        #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
            uniform sampler2D shadowtex1;
            uniform sampler2D shadowcolor0;
        #endif
    #endif

    #if defined DYN_LIGHT_VL && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined IRIS_FEATURE_SSBO
        uniform sampler2D noisetex;
    #endif
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float viewHeight;
uniform float viewWidth;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float blindness;

#if ATMOS_VL_SAMPLES > 0
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 cameraPosition;
    uniform float near;
    uniform float far;

    #if defined WORLD_SHADOW_ENABLED && defined SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowModelView;
        uniform mat4 shadowProjection;
        uniform vec3 shadowLightPosition;
    #endif

    #if defined DYN_LIGHT_VL && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined IRIS_FEATURE_SSBO
        uniform int frameCounter;
        uniform float frameTimeCounter;
        
        uniform int heldItemId;
        uniform int heldItemId2;
        uniform int heldBlockLightValue;
        uniform int heldBlockLightValue2;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
#endif

#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#if ATMOS_VL_SAMPLES > 0
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/buffers/shadow.glsl"

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded.glsl"
            #include "/lib/shadows/cascaded_render.glsl"
        #else
            #include "/lib/shadows/basic.glsl"
            #include "/lib/shadows/basic_render.glsl"
        #endif
    #endif

    #if defined DYN_LIGHT_VL && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined IRIS_FEATURE_SSBO
        #include "/lib/blocks.glsl"
        #include "/lib/items.glsl"
        #include "/lib/sampling/noise.glsl"

        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/dynamic.glsl"
        #include "/lib/lighting/collisions.glsl"
        #include "/lib/lighting/tracing.glsl"
        #include "/lib/lighting/dynamic_blocks.glsl"
        #include "/lib/lighting/basic.glsl"
    #endif

    #include "/lib/world/volumetric_fog.glsl"
#endif

#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec3 clipPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0);
    vec3 viewPos = (gbufferProjectionInverse * vec4(clipPos, 1.0)).xyz;

    vec3 color;
    if (starData.a > 0.5) {
        color = starData.rgb;
    }
    else {
        color = GetFogColor(normalize(viewPos));
    }

    // #if ATMOS_VL_SAMPLES > 0
    //     vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);

    //     vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, near, far);
    //     color = color * vlScatterTransmit.a + vlScatterTransmit.rgb;
    // #endif

    color *= 1.0 - blindness;

    ApplyPostProcessing(color);

    color += InterleavedGradientNoise(gl_FragCoord.xy) / 255.0;

    outColor0 = vec4(color, 1.0);
}
