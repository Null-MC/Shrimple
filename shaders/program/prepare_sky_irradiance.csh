#define RENDER_PREPARE_SKY_IRRADIANCE
#define RENDER_PREPARE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(2, 2, 1);

layout(rgba16f) uniform image2D imgSkyIrradiance;

uniform sampler2D texSky;

uniform int frameCounter;

#include "/lib/sampling/erp.glsl"
#include "/lib/sampling/noise.glsl"


vec3 CalculateIrradiance(const in vec3 normal) {
    const float sampleDelta = 0.4;

    vec3 up    = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, normal));
    up         = normalize(cross(normal, right));

    const float phi_step_inv = rcp(TAU / sampleDelta);
    const float theta_step_inv = rcp(0.5*PI / sampleDelta);

    float phi_dither = hash13(vec3(gl_GlobalInvocationID.xy, frameCounter)) * phi_step_inv;
    float theta_dither = hash13(vec3(gl_GlobalInvocationID.xy, frameCounter+3)) * theta_step_inv;

    float nrSamples = 0.0;
    vec3 irradiance = vec3(0.0);

    for (float phi = 0.0; phi < TAU; phi += sampleDelta) {
        float cos_phi = cos(phi+phi_dither);
        float sin_phi = sin(phi+phi_dither);

        for (float theta = 0.0; theta < 0.5*PI; theta += sampleDelta) {
            // spherical to cartesian (in tangent space)
            float cos_theta = cos(theta+theta_dither);
            float sin_theta = sin(theta+theta_dither);

            vec3 tangentSample = vec3(
                sin_theta * cos_phi,
                sin_theta * sin_phi,
                cos_theta);

            // tangent space to world
            vec3 sampleVec =
                tangentSample.x * right +
                tangentSample.y * up +
                tangentSample.z * normal;

            sampleVec = normalize(sampleVec);
            vec2 uv = DirectionToUV(sampleVec);
            vec3 skyColor = textureLod(texSky, uv, 0).rgb;

            irradiance += skyColor * (cos_theta * sin_theta);
            nrSamples++;
        }
    }

    return PI * irradiance / nrSamples;
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / 16.0;

    vec3 normal = DirectionFromUV(texcoord);
    vec3 irradiance = CalculateIrradiance(normal);

    vec3 irradiance_last = imageLoad(imgSkyIrradiance, uv).rgb;

    irradiance = mix(irradiance_last, irradiance, 0.05);

    imageStore(imgSkyIrradiance, uv, vec4(irradiance, 1.0));
}
