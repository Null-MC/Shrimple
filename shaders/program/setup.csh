//#define RENDER_SETUP_DISKS
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"
#endif

mat3 GetSaturationMatrix(const in float saturation) {
    const vec3 luminance = vec3(0.3086, 0.6094, 0.0820);
    
    float oneMinusSat = 1.0 - saturation;
    vec3 red = vec3(luminance.x * oneMinusSat) + vec3(saturation, 0.0, 0.0);
    vec3 green = vec3(luminance.y * oneMinusSat) + vec3(0.0, saturation, 0.0);
    vec3 blue = vec3(luminance.z * oneMinusSat) + vec3(0.0, 0.0, saturation);
    
    return mat3(red, green, blue);
}


void main() {
    matColorPost = GetSaturationMatrix(1.1);

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        const float goldenAngle = PI * (3.0 - sqrt(5.0));
        const float PHI = (1.0 + sqrt(5.0)) / 2.0;

        for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
            float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
            float theta = i * goldenAngle + PHI;
            
            float sine = sin(theta);
            float cosine = cos(theta);
            
            pcfDiskOffset[i] = vec2(cosine, sine) * r;
        }

        for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
            float r = sqrt((i + 0.5) / SHADOW_PCSS_SAMPLES);
            float theta = i * goldenAngle + PHI;
            
            float sine = sin(theta);
            float cosine = cos(theta);
            
            pcssDiskOffset[i] = vec2(cosine, sine) * r;
        }
    #endif

    //barrier();
}
