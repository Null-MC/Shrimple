#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

//#define PH_USE_CUSTOM_ALPHA
//#define PH_ALPHA_FUNC(color) apply_tint_impl(color)

//vec3 apply_tint_impl(vec4 color) {
//    vec3 shit = sqrt(color.xyz) * (1.0 - _pow2(color.a));
//    return _pow2(shit);
//}

uniform sampler2D TEX_GB_COLOR;
uniform sampler2D TEX_GB_NORMALS;

#ifdef LIGHTING_SPECULAR
    uniform usampler2D TEX_GB_SPECULAR;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D texLightmap;
#endif

uniform float near;
uniform float far;
uniform vec2 viewSize;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float skyDayF;
uniform vec3 skyColor;
uniform vec3 sunLocalDir;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform float weatherStrength;
uniform float weatherDensity;
uniform int isEyeInWater;
uniform vec2 taa_offset = vec2(0.0);

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/octohedral.glsl"

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/sampling/lightmap.glsl"
#endif

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


vec3 sun_direction = sunLocalDir;

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    vec3 indirect_light_color = GetSkyLightColor(vec3(0.0), sunLocalDir.y, abs(sunLocalDir.y));
#else
    vec3 indirect_light_color = RGBToLinear(texture(texLightmap, LightMapTex(vec2(0.0, 1.0))).rgb);
#endif

vec3 load_world_position() {
    vec2 texcoord = gl_FragCoord.xy / viewSize;
    texcoord /= PH_RENDER_SCALE;
//    texcoord += 0.5 / (viewSize * PH_RENDER_SCALE);

    float depth = texture(TEX_DEPTH, texcoord).r;
    vec3 screenPos = vec3(texcoord, depth);
    vec3 ndcPos = screenPos * 2.0 - 1.0;

    #ifdef TAA_ENABLED
        // this must exist to prevent GI sampling from being in blocks
        ndcPos.xy -= 2.0 * taa_offset;
    #endif

    // TODO: fix hand depth

    vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    return localPos + cameraPosition;
}

void load_fragment_variables(out vec3 albedo, out vec3 world_pos, out vec3 world_normal, out vec3 world_normal_mapped) {
    ivec2 uv = ivec2(gl_FragCoord.xy / PH_RENDER_SCALE); // TODO: fix texel offset

    vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);
    world_normal = OctDecode(normalData.xy);
    vec3 texViewNormal = OctDecode(normalData.zw);

    world_normal_mapped = mat3(gbufferModelViewInverse) * texViewNormal;

    albedo = texelFetch(TEX_GB_COLOR, uv, 0).rgb;
    albedo = RGBToLinear(albedo);

    world_normal = clamp(world_normal, vec3(-1.0), vec3(1.0));
    world_pos = load_world_position() - 0.01 * world_normal;
}

vec3 get_sky_color(ivec2 uv, vec3 worldPos, vec3 normal) {
    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    return GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, normal, weatherStrength, skyDayF);
}

bool is_in_world() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    return depth < 1.0;
}

vec2 get_taa_jitter() {
    #ifdef TAA_ENABLED
        return 2.0*taa_offset;
    #else
        return vec2(0.0);
    #endif
}
