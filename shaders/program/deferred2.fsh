#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

in vec2 texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_TEX_NORMAL;
uniform usampler2D TEX_GEO_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;

uniform sampler2D TEX_GI_COLOR;
uniform sampler2D TEX_GI_POSITION;

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler2D texSkyIrradiance;
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;
#endif

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float rainStrength;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 shadowLightPosition;
uniform vec3 sunLocalDir;
uniform int isEyeInWater;
uniform int frameCounter;
uniform vec2 viewSize;
uniform vec2 taa_offset = vec2(0.0);
uniform vec2 taa_offset_prev = vec2(0.0);

uniform int vxRenderDistance;

#include "/photonics/photonics.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"

#ifdef LIGHTING_COLORED
    #include "/lib/hsv.glsl"
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


vec2 hash22(const in vec2 seed) {
    const vec4 U = vec4(0.1031, 0.1030, 0.0973, 0.1099);

    vec3 p3 = fract(seed.xyx * U.xyz);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 sample_cosine_weighted_hemisphere(const in vec2 rand, out float pdf) {
    float r = sqrt(rand.x);
    float phi = 2.0 * PI * rand.y;

    vec3 dir;
    dir.x = r * cos(phi);
    dir.y = r * sin(phi);
    dir.z = sqrt(max(1.0 - rand.x, 0.0));

    pdf = dir.z / PI;

    return dir;
}

vec3 transform_to_world(const in vec3 normal, const in vec3 local_dir) {
    float sign = step(0.0, normal.z) * 2.0 - 1.0;

    float a = -1.0 / (sign + normal.z);
    float b = normal.x * normal.y * a;
    vec3 tangent = vec3(1.0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x);
    vec3 bitangent = vec3(b, sign + normal.y * normal.y * a, -normal.y);
    mat3 tbn = mat3(tangent, bitangent, normal);

    return tbn * local_dir;
}

vec3 sample_indirect_lighting(const in vec3 localPos, const in vec3 localNormal) {
    vec3 rtOrigin = localPos + rt_camera_position;

    float pdf;
    vec2 seed = hash22(gl_FragCoord.xy + vec2(23.0, 47.0)*frameCounter);
    vec3 trace_tangentDir = sample_cosine_weighted_hemisphere(seed, pdf);
    vec3 trace_localDir = transform_to_world(localNormal, trace_tangentDir);

    RayJob ray;
    ray.origin = rtOrigin;
    ray.direction = trace_localDir;

    RAY_ITERATION_COUNT = 20;
    breakOnEmpty = true;

    trace_ray(ray, true);

    breakOnEmpty = false;
    RAY_ITERATION_COUNT = 100;

    vec3 lighting;
    if (!ray.result_hit && !ray_iteration_bound_reached) {
        lighting = GetSkyFogColor(RGBToLinear(skyColor), RGBToLinear(fogColor), trace_localDir);
    }
    else {
        lighting = vec3(0.0);
        vec3 hitAlbedo = RGBToLinear(ray.result_color);
        vec3 hitLocalPos = ray.result_position - rt_camera_position;
        vec3 hitLocalNormal = ray.result_normal;

        float NoVm = max(dot(hitLocalNormal, trace_localDir), 0.0);

        #ifdef LIGHTING_COLORED
            vec3 voxelPos = GetVoxelPosition(hitLocalPos);
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localNormal);
            lighting += NoVm * SampleFloodFill(samplePos) * 3.0;
        #endif

        #ifndef WORLD_NETHER
            // TODO: add indirect sky lighting
            float hitSkyLevel = saturate(get_result_sky_light(hitLocalNormal) / 15.0);
//            vec3 hitSkyColorFinal = GetSkyFogColor(RGBToLinear(skyColor), RGBToLinear(fogColor), hitLocalNormal);
            vec3 hitSkyIrradiance = 0.5 * SampleSkyIrradiance(hitLocalNormal);
            lighting += _pow2(hitSkyLevel) * NoVm * hitSkyIrradiance;
        #endif

        vec3 localSkyLightDir = normalize(mul3(gbufferModelViewInverse, shadowLightPosition));
        float sky_NoL = dot(hitLocalNormal, localSkyLightDir);

        if (sky_NoL > 0.0) {
            ray.origin = ray.result_position + 0.1 * hitLocalNormal;
            ray.direction = localSkyLightDir;

            RAY_ITERATION_COUNT = 20;
            breakOnEmpty = true;

            trace_ray(ray, true);

            breakOnEmpty = false;
            RAY_ITERATION_COUNT = 100;

            if (!ray.result_hit && !ray_iteration_bound_reached) {
                #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
                    vec3 skylightColor = GetSkyLightColor(hitLocalPos, sunLocalDir.y, localSkyLightDir.y);
                #else
                    const vec3 skylightColor = RGBToLinear(vec3(0.89, 0.863, 0.722));
                #endif

                #ifdef SHADOW_CLOUDS
                    float cloudShadow = SampleCloudShadow(hitLocalPos, localSkyLightDir);
                    sky_NoL *= cloudShadow * 0.5 + 0.5;
                #endif

                lighting += sky_NoL * hitAlbedo * skylightColor;
            }
        }
    }

    return lighting;// * trace_tangentDir.z / pdf;
}


/* RENDERTARGETS: 6,7 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec3 outPosition;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    vec3 screenPos = vec3(texcoord, depth);

    #ifdef TAA_ENABLED
        screenPos.xy -= taa_offset;
    #endif

    vec3 ndcPos = screenPos * 2.0 - 1.0;

    // TODO: fix hand depth

    vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 color = vec3(0.0);

    if (depth < 1.0) {
        uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
        vec3 viewTexNormal = OctDecode(unpackUnorm2x16(reflectNormalData));
        vec3 localTexNormal = mat3(gbufferModelViewInverse) * viewTexNormal;

        color = sample_indirect_lighting(localPos, localTexNormal);
    }


    // reproject
    vec3 prev_localPos = localPos + (cameraPosition - previousCameraPosition);

    vec3 prev_viewPos = mul3(gbufferPreviousModelView, prev_localPos);
    vec3 prev_clipPos = project(gbufferPreviousProjection, prev_viewPos);
    vec2 prev_screenPos = prev_clipPos.xy * 0.5 + 0.5;

    #ifdef TAA_ENABLED
        prev_screenPos.xy += taa_offset_prev;
    #endif

    vec4 prev_color = textureLod(TEX_GI_COLOR, prev_screenPos, 0);
    vec3 prev_pos = textureLod(TEX_GI_POSITION, prev_screenPos, 0).xyz;

    // reset accumulation if reprojected offscreen
    if (saturate(prev_screenPos) != prev_screenPos) prev_color.a = 0.0;

    // adjust history weight on position match
    float viewDist = length(viewPos);
    float dist = distance(localPos, prev_pos);
//    prev_color.a *= step(dist, max(0.02*viewDist, 0.2));
    //prev_color.a /= 1.0 + dist;
    prev_color.a *= exp(-2.0 * dist);

    prev_color.a = clamp(prev_color.a + 1.0, 1.0, 64.0);
    prev_color.rgb = mix(prev_color.rgb, color, 1.0 / prev_color.a);


    outColor = prev_color;
    outPosition = localPos;
}
