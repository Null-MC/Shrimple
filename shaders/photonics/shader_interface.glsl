#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0


uniform usampler2D TEX_GEO_NORMAL;
uniform usampler2D TEX_TEX_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;

uniform vec2 viewSize;
//uniform vec3 sun_dir;
//uniform vec3 sunPosition;
uniform vec3 sunLocalDir;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/octohedral.glsl"


vec3 sun_direction = sunLocalDir;

// TODO: wtf is this?
vec3 indirect_light_color = vec3(1.0);// mix(texelFetch(colortex4, ivec2(191, 1), 0).rgb, vec3(1f), 0.5);

vec3 load_world_position() {
//    ivec2 uv = ivec2(gl_FragCoord.xy);
//    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    vec2 texcoord = gl_FragCoord.xy / viewSize;
    float depth = texture(TEX_DEPTH, texcoord).r;
    vec3 screenPos = vec3(texcoord, depth);
    vec3 ndcPos = screenPos * 2.0 - 1.0;

//    #ifdef TAA_ENABLED
//        ndcPos.xy += taa_offset * 2.0;
//    #endif

    // TODO: fix hand depth

    vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    return localPos + cameraPosition;
}

void load_fragment_variables(
    out vec3 albedo, // The albedo of the current fragment
    out vec3 world_pos, // The world pos of the current fragment, after accounting for world_normal
    out vec3 world_normal, // The world normal for the current fragment
    out vec3 world_normal_mapped // The normal from the normal map of the current fragment
) {
    ivec2 uv = ivec2(gl_FragCoord.xy);

    uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
    vec3 viewNormal = OctDecode(unpackUnorm2x16(reflectNormalData));
    world_normal_mapped = mat3(gbufferModelViewInverse) * viewNormal;

    uint geoNormalData = texelFetch(TEX_GEO_NORMAL, uv, 0).r;
    world_normal = OctDecode(unpackUnorm2x16(geoNormalData));
//    world_normal_mapped = world_normal;

    uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;
    vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
    albedo = RGBToLinear(reflectDataR.rgb);

    world_pos = load_world_position() - 0.01 * world_normal;
}

vec3 get_sky_color(ivec2 gBufferLoc, vec3 worldPos, vec3 newNormal) {
    return vec3(0.1); // TODO
}

bool is_in_world() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    return depth < 1.0;
}

vec2 get_taa_jitter() {
    return vec2(0.0);// taa_offset;
}
