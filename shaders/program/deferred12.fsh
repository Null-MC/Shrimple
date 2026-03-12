#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

in vec2 texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_TEX_NORMAL;
//uniform usampler2D TEX_GEO_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;

//uniform sampler2D texBlockLight;

//uniform vec3 cameraPosition;
//uniform mat4 gbufferModelViewInverse;
//uniform mat4 gbufferProjectionInverse;
uniform int frameCounter;
//uniform int heldItemId;
//uniform int heldItemId2;
//uniform int heldBlockLightValue;
//uniform int heldBlockLightValue2;
//uniform bool firstPersonCamera;
//uniform vec3 relativeEyePosition;
uniform vec2 taa_offset = vec2(0.0);

#include "/photonics/photonics.glsl"

#include "/lib/octohedral.glsl"
//#include "/lib/hand-light.glsl"


//vec3 GetLocalPosition(const in float depth) {
//    vec3 screenPos = vec3(texcoord, depth);
//
//    #ifdef TAA_ENABLED
//        screenPos.xy -= taa_offset;
//    #endif
//
//    vec3 ndcPos = screenPos * 2.0 - 1.0;
//
//    // TODO: fix hand depth
//
//    vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
//    return mul3(gbufferModelViewInverse, viewPos);
//}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    vec3 lighting = vec3(0.0);

    if (depth < 1.0) {
        uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;
//        uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
//        uint geoNormalData = texelFetch(TEX_GEO_NORMAL, uv, 0).r;

//        vec3 localPos = GetLocalPosition(depth);


        lighting += sample_photonics_direct(texcoord);

        lighting += sample_photonics_handheld(texcoord);


        vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
        lighting *= RGBToLinear(reflectDataR.rgb);
    }

    outFinal = src + lighting;
}
