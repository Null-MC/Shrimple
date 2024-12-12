#define RENDER_PREPARE_SKY
#define RENDER_PREPARE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(8, 4, 1);

layout(rgba16f) uniform writeonly image2D imgSky;

#ifdef VOLUMETRIC_NOISE_ENABLED
    uniform sampler3D TEX_CLOUDS;
#endif

uniform float far;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float cloudHeight;
uniform float weatherStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float sunAngle;
uniform int moonPhase;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;

#if MC_VERSION >= 11900
    uniform float darknessFactor;
    uniform float darknessLightFactor;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/erp.glsl"

#include "/lib/lighting/hg.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/atmosphere_trace.glsl"
#include "/lib/world/sky.glsl"

#include "/lib/fog/fog_common.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#if LIGHTING_VOLUMETRIC != VOL_TYPE_NONE
    #include "/lib/lighting/scatter_transmit.glsl"

    #if WORLD_CURVE_RADIUS > 0
        #include "/lib/world/curvature.glsl"
    #endif

    #include "/lib/sky/sky_trace.glsl"
#endif


vec3 SampleSkyColor(const in vec3 localDir) {
    #if SKY_TYPE == SKY_TYPE_CUSTOM
        vec3 skyColor = GetCustomSkyColor(localSunDirection, localDir);
    #else
        vec3 skyColor = GetVanillaFogColor(fogColor, localDir.y);
        skyColor = RGBToLinear(skyColor);
    #endif

    skyColor *= Sky_BrightnessF;

    // #if LIGHTING_VOLUMETRIC > 0
    //     float _far = far;
    //     #ifdef DISTANT_HORIZONS
    //         _far = 0.5*dhFarPlane;
    //     #endif
        
    //     vec3 scatterFinal = vec3(0.0);
    //     vec3 transmitFinal = vec3(1.0);
    //     TraceSky(scatterFinal, transmitFinal, cameraPosition, localDir, _far, SkyFar, 16);
    //     skyColor = skyColor * transmitFinal + scatterFinal;
    // #endif

    return skyColor;
}

void main() {
    uvec2 size = gl_WorkGroupSize.xy * gl_NumWorkGroups.xy;

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / size;

    vec3 normal = DirectionFromUV(texcoord);
    vec3 skyColor = SampleSkyColor(normal);

    imageStore(imgSky, uv, vec4(skyColor, 1.0));
}
