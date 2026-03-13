#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform sampler2D radiosity_position;

in VertexData {
    vec3 localPos;
    vec3 localNormal;
} vIn;


uniform int frameCounter;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;

#include "/photonics/photonics.glsl"


/* RENDERTARGETS: 0 */
//layout(location = 0) out vec4 outColor;

void main() {
    vec3 rayOrigin = vIn.localPos + rt_camera_position;
    vec3 localNormal = normalize(vIn.localNormal);

//    rayOrigin -= 0.001 * localNormal;
    vec3 localViewDir = -shadowModelViewInverse[2].xyz;
    rayOrigin += 0.01 * localViewDir;

    RayJob ray = RayJob(
        rayOrigin, localViewDir,
        vec3(0), vec3(0), vec3(0), false);

    ray_constraint = ivec3(ray.origin);
    trace_ray(ray);

    if (!ray.result_hit) discard;

    vec3 hitLocalPos = ray.result_position - rt_camera_position;
    vec3 hitViewPos = mul3(shadowModelView, hitLocalPos);
    vec3 hitScreenPos = project(shadowProjection, hitViewPos);

    gl_FragDepth = hitScreenPos.z * 0.5 + 0.5;
}
