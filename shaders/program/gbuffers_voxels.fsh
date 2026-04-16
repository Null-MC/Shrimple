#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;
} vIn;


#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFill;
#endif

#ifdef SHADOWS_ENABLED
    uniform SHADOW_SAMPLER TEX_SHADOW;

    #ifdef SHADOW_COLORED
        uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

uniform float far;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec3 cameraPosition;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform vec4 entityColor;
uniform float alphaTestRef;
uniform int frameCounter;
uniform int isEyeInWater;
uniform ivec2 atlasSize;
uniform vec2 viewSize;

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/ign.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/shadows.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(DEFERRED_REFLECT_ENABLED)
    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif

#include "/photonics/photonics.glsl"


#include "_outputDefer.glsl"

void main() {
    // avoid view bobbing
    vec3 viewPos = mul3(gbufferModelView, vIn.localPos);
    vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);

    vec3 rayOrigin = vIn.localPos + rt_camera_position;
//    rayOrigin -= 0.001 * vIn.localNormal;
    rayOrigin += 0.001 * localViewDir;

    RayJob ray = RayJob(
        rayOrigin, localViewDir,
        vec3(0), vec3(0), vec3(0), false
    );

    ray_constraint = ivec3(ray.origin);
    trace_ray(ray);

    if (!ray.result_hit) discard;

    vec2 lmcoord = vIn.lmcoord;
    lmcoord.y = get_result_sky_light(ray.result_normal) / 15.0;

    vec3 hitLocalNormal = ray.result_normal;
    vec3 hitLocalPos = ray.result_position - rt_camera_position;
    vec3 hitViewPos = mul3(gbufferModelView, hitLocalPos);

    if (lengthSq(hitLocalNormal) < EPSILON)
        hitLocalNormal = normalize(vIn.localNormal);

    float hitViewDepth = -hitViewPos.z;
    gl_FragDepth = 0.5 * (-gbufferProjection[2].z*hitViewDepth + gbufferProjection[3].z) / hitViewDepth + 0.5;

    vec4 color = vec4(ray.result_color, 1.0);
    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    color.rgb = LinearToRGB(color.rgb);

    const float occlusion = 1.0;
    const uint matId = 0u;


    outAlbedo = color;

    vec3 hitViewNormal = mat3(gbufferModelView) * hitLocalNormal;
    outNormals = vec4(OctEncode(hitLocalNormal), OctEncode(hitViewNormal));

    outSpecularMeta = uvec2(
        packUnorm4x8(specularData),
        packUnorm4x8(vec4(lmcoord, occlusion, matId / 255.0))
    );

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif
}
