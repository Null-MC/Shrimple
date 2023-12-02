#define RENDER_OPAQUE_SSAO
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
//uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

// #ifdef WORLD_SKY_ENABLED
//     uniform vec3 fogColor;
//     uniform vec3 skyColor;
//     uniform float fogStart;
//     uniform float fogEnd;
//     uniform int fogShape;
// #endif

// #ifdef WORLD_WATER_ENABLED
//     uniform int isEyeInWater;
// #endif

uniform vec2 viewSize;
uniform vec2 pixelSize;

// #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
//     uniform float alphaTestRef;
// #endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/effects/ssao.glsl"

// #if WORLD_FOG_MODE != FOG_MODE_NONE
//     #include "/lib/fog/fog_common.glsl"

//     #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
//         #include "/lib/fog/fog_custom.glsl"
//     #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
//         #include "/lib/fog/fog_vanilla.glsl"
//     #endif
// #endif


/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = textureLod(depthtex1, texcoord, 0).r;
    float occlusion = 0.0;

    if (depth < 1.0) {
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        vec3 texViewNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));

        occlusion = GetSpiralOcclusion(texcoord, viewPos, texViewNormal);

        // #if WORLD_FOG_MODE != FOG_MODE_NONE
        //     #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
        //         // TODO
        //     #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
        //         vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        //         occlusion *= 1.0 - GetVanillaFogFactor(localPos);
        //     #endif
        // #endif
    }

    outAO = vec4(vec3(occlusion), 1.0);
}
