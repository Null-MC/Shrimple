#define RENDER_BEGIN_SKY_IRRADIANCE
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

layout(rgba16f) uniform writeonly image2D imgSkyIrradiance;

shared vec3 skyColorBuffer[64];

uniform float far;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform float skyRainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

#if MC_VERSION >= 11900
    uniform float darknessFactor;
    uniform float darknessLightFactor;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/erp.glsl"

#include "/lib/lighting/hg.glsl"
#if SKY_VOL_FOG_TYPE > 0
    #include "/lib/lighting/scatter_transmit.glsl"
#endif

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/sky.glsl"

#include "/lib/fog/fog_common.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif


#if SKY_VOL_FOG_TYPE > 0
    void ApplyVL(inout vec3 skyColor, const in vec3 localDir) {
        float VoL = dot(localSkyLightDirection, localDir);
        float phaseAir = GetSkyPhase(VoL);

        const int stepCount = 8;
        const float weatherF = 1.0;
        float stepDist = SkyFar / stepCount;
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;
        vec3 vlLight = 2800.0/stepCount * (phaseAir + AirAmbientF) * skyLightColor;

        vec3 scatterFinal = vec3(0.0);
        vec3 transmitFinal = vec3(1.0);
        for (int i = 0; i < stepCount; i++) {
            vec3 traceLocalPos = localDir * stepDist * i;
            float airDensity = GetSkyDensity(traceLocalPos.y + cameraPosition.y);

            vec3 lightIntegral = vlLight * AirScatterColor * airDensity;// * stepDist;
            vec3 stepTransmittance = exp(-stepDist * AirExtinctColor * airDensity);

            transmitFinal *= stepTransmittance;
            scatterFinal = lightIntegral * transmitFinal + scatterFinal;
        }

        skyColor = skyColor * transmitFinal + scatterFinal;
    }
#endif

vec3 SampleSkyColor(const in vec3 localDir) {
    #if SKY_TYPE == SKY_TYPE_CUSTOM
        vec3 skyColor = GetCustomSkyColor(localSunDirection.y, localDir.y);
    #else
        vec3 skyColor = GetVanillaFogColor(fogColor, localDir.y);
        skyColor = RGBToLinear(skyColor);
    #endif

    skyColor *= Sky_BrightnessF;

    #if SKY_VOL_FOG_TYPE > 0
        ApplyVL(skyColor, localDir);
    #endif

    return skyColor;
}

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

            // vec3 skyColor = SampleSkyColor(sampleVec);
            ivec2 uv = ivec2(DirectionToUV(sampleVec) * 8.0 + 0.5);
            vec3 skyColor = skyColorBuffer[uv.y*8 + uv.x];

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
    vec3 skyColor = SampleSkyColor(normal);

    skyColorBuffer[uv.y*8 + uv.x] = skyColor;
    memoryBarrierShared();

    vec3 irradiance = CalculateIrradiance(normal);

    // irradiance = vec3(texcoord, 0.0);
    // irradiance = vec3(dot(normal, localSkyLightDirection));
    // irradiance = skyColor;

    imageStore(imgSkyIrradiance, uv, vec4(irradiance, 1.0));
}
