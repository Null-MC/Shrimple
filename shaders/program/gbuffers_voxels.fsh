#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;
} vIn;


uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform int frameCounter;

#include "/lib/octohedral.glsl"
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

    RAY_ITERATION_COUNT = 8;
//    ray_constraint = ivec3(ray.origin);
    trace_ray(ray);

    if (!ray.result_hit) discard;

    ivec3 origin = ivec3(floor(vIn.localPos + rt_camera_position - 0.01 * vIn.localNormal));
    vec3 hitOffset = ray.result_position - origin;
    if (clamp(hitOffset, -0.01, 1.01) != hitOffset) discard;

    vec2 lmcoord = vIn.lmcoord;
    lmcoord.y = get_result_sky_light(ray.result_normal) / 15.0;

    vec3 hitLocalNormal = ray.result_normal;
    vec3 hitLocalPos = ray.result_position - rt_camera_position;
    vec3 hitViewPos = mul3(gbufferModelView, hitLocalPos);

    if (lengthSq(hitLocalNormal) < EPSILON)
        hitLocalNormal = normalize(vIn.localNormal);

    float hitViewDepth = -hitViewPos.z + 0.001;
    gl_FragDepth = 0.5 * (-gbufferProjection[2].z*hitViewDepth + gbufferProjection[3].z) / hitViewDepth + 0.5;

    vec4 color = vec4(ray.result_color, 1.0);
    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

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
