#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef NETHER
    #define WORLD_NETHER
#elif defined(END)
    #define WORLD_END
#else
    #define WORLD_OVERWORLD
#endif

#ifndef OVERWORLD
    #undef SHADOWS_ENABLED
    #undef SHADOW_CLOUDS
#endif

#define TEX_DEPTH depthtex0

uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_GB_COLOR;
uniform sampler2D TEX_GB_NORMALS;

#ifdef LIGHTING_SPECULAR
    uniform usampler2D TEX_GB_SPECULAR;
#endif

uniform float near;
uniform float far;
uniform vec2 viewSizeScaled;
uniform vec2 taa_offset = vec2(0.0);

// PH MISSING INTERNALS
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

#include "/lib/octohedral.glsl"


vec3 load_player_position() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    vec2 texcoord = gl_FragCoord.xy / viewSizeScaled;
    vec3 screenPos = vec3(texcoord, depth);
    vec3 ndcPos = screenPos * 2.0 - 1.0;

    #ifdef TAA_ENABLED
        // this must exist to prevent GI sampling from being in blocks
        ndcPos.xy -= 2.0 * taa_offset;
    #endif

    // TODO: fix hand depth

    vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    return localPos;
}

void load_fragment_data(out vec3 geometry_normal, out vec3 texture_normal) {
    ivec2 uv = ivec2(gl_FragCoord.xy);

    vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);
    geometry_normal = OctDecode(normalData.xy);
    texture_normal = OctDecode(normalData.zw);

    texture_normal = mat3(gbufferModelViewInverse) * texture_normal;
}

bool is_in_world() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    return depth < 1.0;
}

bool is_hand_at() {
    return false;
}

vec2 get_taa_jitter() {
    #ifdef TAA_ENABLED
        return 2.0*taa_offset;
    #else
        return vec2(0.0);
    #endif
}
