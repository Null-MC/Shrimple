#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
const ivec3 workGroups = ivec3(3, 1, 1);

layout(rgba16f) uniform writeonly image2D imgSkyIrradiance;

const ivec2 BufferSize = ivec2(24, 6);


uniform float far;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float rainStrength;
uniform vec3 sunLocalDir;
uniform int isEyeInWater;

uniform int vxRenderDistance;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


const vec3 faceDirs[6] = vec3[6](
    vec3(-1, 0, 0), vec3( 1, 0, 0),
    vec3( 0,-1, 0), vec3( 0, 1, 0),
    vec3( 0, 0,-1), vec3( 0, 0, 1));


vec3 transform_to_world(const in vec3 normal, const in vec3 local_dir) {
    vec3 bitangent = abs(normal.y) < 0.99
        ? vec3(0.0, 1.0, 0.0)
        : vec3(0.0, 0.0, 1.0);

    vec3 tangent = normalize(cross(bitangent, normal));
    bitangent = normalize(cross(tangent, bitangent));
    mat3 tbn = mat3(tangent, bitangent, normal);

    return tbn * local_dir;
}

vec3 GetSkyIrradiance(const in vec3 localSunDir, const in vec3 localViewDir) {
    const int SampleCountX = 16;
    const int SampleCountY = 8;

    const float phi_step = (2.0*PI) / SampleCountX;
    const float theta_step = (0.5*PI) / SampleCountY;

    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 fogColorL = RGBToLinear(fogColor);

    vec3 irradiance = vec3(0.0);

    for (int x = 0; x < SampleCountX; x++) {
        float phi = x * phi_step;

        float cos_phi = cos(phi);
        float sin_phi = sin(phi);

        for (int y = 0; y < SampleCountY; y++) {
            float theta = y * theta_step;

            float cos_theta = cos(theta);
            float sin_theta = sin(theta);

            vec3 tangentSample = vec3(
                sin_theta * cos_phi,
                sin_theta * sin_phi,
                cos_theta);

            vec3 sampleDir = transform_to_world(localViewDir, tangentSample);
            vec3 skyColorFinal = GetSkyFogColor(skyColorL, fogColorL, localSunDir, sampleDir);
            irradiance += skyColorFinal * (cos_theta * sin_theta);
        }
    }

    const float SampleCountInv = 1.0 / (SampleCountX * SampleCountY);
    return 2.0 * irradiance * SampleCountInv;
}


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, BufferSize))) return;

    float texcoord_x = (uv.x + 0.5) / float(BufferSize.x);
    float cosTheta = 2.0*texcoord_x - 1.0;
    float theta = safeacos(cosTheta);

    vec3 localSunDir = normalize(vec3(sin(theta), cosTheta, 0.0));
    vec3 localViewDir = faceDirs[uv.y];

    vec3 irradiance = GetSkyIrradiance(localSunDir, localViewDir);
    imageStore(imgSkyIrradiance, uv, vec4(irradiance, 1.0));
}
