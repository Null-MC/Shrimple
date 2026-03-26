#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

in vec2 texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_ALBEDO_SPECULAR;

//#ifdef REFLECT_ENABLED
//    uniform usampler2D TEX_TEX_NORMAL;
//#endif

#ifdef PHOTONICS_GI_ENABLED
    uniform sampler2D texPhotonicsIndirect;
#endif

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform int frameCounter;

#ifdef REFLECT_ENABLED
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
        vec4 albedoData = unpackUnorm4x8(reflectData.r);
        vec4 specularData = unpackUnorm4x8(reflectData.g);
        vec3 albedo = RGBToLinear(albedoData.rgb);

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            albedo /= PI;
        #endif

        #if defined(PHOTONICS_GI_ENABLED) && !defined(PHOTONICS_RESTIR_ENABLED)
            vec3 gi = texture(texPhotonicsIndirect, texcoord).rgb;

            // reduce GI [diffuse] for metals
            #ifdef MATERIAL_PBR_ENABLED
                float metalness = mat_metalness(specularData.g);
                float roughness = mat_roughness(specularData.r);
                float smoothL = 1.0 - _pow2(roughness);
                gi *= 1.0 - metalness * smoothL;
            #endif

//            gi *= 1.0 - F * _pow2(smoothness);
            lighting += gi;
        #endif

        #ifdef LIGHTING_SPECULAR
            lighting *= albedo;
        #endif

        #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
            lighting += sample_photonics_direct(texcoord);
        #endif

        #ifdef PHOTONICS_HAND_LIGHT_ENABLED
            lighting += sample_photonics_handheld(texcoord);
        #endif

        #ifndef LIGHTING_SPECULAR
            lighting *= albedo;
        #endif
    }

    outFinal = src + lighting;
}
