#define RENDER_PREPARE_SKY_IRRADIANCE
#define RENDER_PREPARE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

layout(rgba16f) uniform writeonly image2D imgSkyIrradiance;

uniform sampler2D texSky;

#include "/lib/sampling/erp.glsl"


vec3 CalculateIrradiance(const in vec3 normal) {
    const float sampleDelta = 0.2;

    vec3 up    = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, normal));
    up         = normalize(cross(normal, right));

    float nrSamples = 0.0;
    vec3 irradiance = vec3(0.0);  
    for (float phi = 0.0; phi < TAU; phi += sampleDelta) {
        for (float theta = 0.0; theta < 0.5*PI; theta += sampleDelta) {
            // spherical to cartesian (in tangent space)
            vec3 tangentSample = vec3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));

            // tangent space to world
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal; 
            sampleVec = normalize(sampleVec);

            vec2 uv = DirectionToUV(sampleVec);
            vec3 skyColor = textureLod(texSky, uv, 0).rgb;

            irradiance += skyColor * cos(theta) * sin(theta);
            nrSamples++;
        }
    }

    return PI * (irradiance / nrSamples);
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / 8.0;

    vec3 normal = DirectionFromUV(texcoord);
    vec3 irradiance = CalculateIrradiance(normal);

    imageStore(imgSkyIrradiance, uv, vec4(irradiance, 1.0));
}
