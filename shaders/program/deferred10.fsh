#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

in vec2 texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_ALBEDO_SPECULAR;

//#ifdef LIGHTING_REFLECT_ENABLED
//    uniform usampler2D TEX_TEX_NORMAL;
//#endif

#ifdef PHOTONICS_GI_ENABLED
    uniform sampler2D texPhotonicsIndirect;
#endif

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform int frameCounter;

#ifdef LIGHTING_REFLECT_ENABLED
    #include "/lib/material/pbr.glsl"
#endif

#include "/photonics/photonics.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    vec3 lighting = vec3(0.0);

    if (depth < 1.0) {
        uvec2 reflectData = texelFetch(TEX_ALBEDO_SPECULAR, uv, 0).rg;

//        #ifdef LIGHTING_REFLECT_ENABLED
//            uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
//        #endif

        #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
            lighting += sample_photonics_direct(texcoord);
        #endif

        #ifdef PHOTONICS_HAND_LIGHT_ENABLED
            lighting += sample_photonics_handheld(texcoord);
        #endif

        #ifdef PHOTONICS_GI_ENABLED
            lighting += texture(texPhotonicsIndirect, texcoord).rgb;
        #endif

        vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
        vec3 albedo = RGBToLinear(reflectDataR.rgb);

        #ifdef LIGHTING_REFLECT_ENABLED
            vec4 specularData = unpackUnorm4x8(reflectData.g);

            #ifdef MATERIAL_PBR_ENABLED
                float smoothness = 1.0 - mat_roughness(specularData.r);
                float metalness = mat_metalness(specularData.g);

                lighting *= 1.0 - metalness * sqrt(smoothness);
            #else
                float smoothness = 1.0 - mat_roughness_lab(specularData.r);
            #endif

            lighting *= 1.0 - _pow2(smoothness);
        #endif

        lighting *= albedo;
    }

    outFinal = src + lighting;
}
