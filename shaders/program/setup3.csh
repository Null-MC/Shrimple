#define RENDER_SETUP

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 4, 1);

layout(rgba16f) uniform writeonly image2D imgSkyTransmit;

const int sunTransmittanceSteps = 20;
const ivec2 BufferSize = ivec2(256, 64);


#include "/lib/sky-transmit.glsl"


float rayIntersectSphere(vec3 ro, vec3 rd, float rad) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - rad*rad;
    if (c > 0.0 && b > 0.0) return -1.0;

    float discr = b*b - c;
    if (discr < 0.0) return -1.0;

    // Special case: inside sphere, use far discriminant
    if (discr > b*b) return (-b + sqrt(discr));
    return -b - sqrt(discr);
}

vec3 getExtinction(const in float pos_y) {
    float altitudeKM = (pos_y-groundRadiusMM)*1000.0;
    float rayleighDensity = exp(-altitudeKM/8.0);
    float mieDensity = exp(-altitudeKM/1.2);

    vec3 rayleighScattering = rayleighScatteringBase * rayleighDensity;
    float rayleighAbsorption = rayleighAbsorptionBase * rayleighDensity;

    float mieScattering = mieScatteringBase * mieDensity;
    float mieAbsorption = mieAbsorptionBase * mieDensity;

    vec3 ozoneAbsorption = ozoneAbsorptionBase * max(0.0, 1.0 - abs(altitudeKM-25.0)/15.0);

    return rayleighScattering + rayleighAbsorption + mieScattering + mieAbsorption + ozoneAbsorption;
}

vec3 getTransmittance(const in float pos_y, const in vec3 lightDir) {
    vec3 pos = vec3(0.0, pos_y, 0.0);
    float atmoDist = rayIntersectSphere(pos, lightDir, atmosphereRadiusMM);
    float t = 0.0;

    vec3 transmittance = vec3(1.0);
    for (int i = 1; i <= sunTransmittanceSteps; i++) {
        float newT = float(i)/float(sunTransmittanceSteps) * atmoDist;
        float dt = newT - t;
        t = newT;

        float newPos_y = pos_y + t*lightDir.y;
        vec3 extinction = getExtinction(newPos_y);

        transmittance *= exp(-dt*extinction);
    }

    return transmittance;
}


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, BufferSize))) return;

    vec2 texcoord = vec2(uv) / vec2(BufferSize);
    texcoord.x = (texcoord.x+1.5)*0.3;

    float height = mix(groundRadiusMM, atmosphereRadiusMM, texcoord.y);

    float cosTheta = 2.0*texcoord.x - 1.0;

    float theta = safeacos(cosTheta);
    vec3 lightDir = normalize(vec3(0.0, cosTheta, -sin(theta)));
    vec3 transmittance = getTransmittance(height, lightDir);

    imageStore(imgSkyTransmit, uv, vec4(transmittance, 1.0));
}
