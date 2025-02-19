#define RENDER_SETUP_SCENE
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/utility/matrix.glsl"
    #include "/lib/post/saturation.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        matColorPost = GetPostMatrix();

        #ifdef WORLD_SKY_ENABLED
            lightningPosition = vec4(0.0);
        #endif

        #if defined WORLD_SHADOW_ENABLED && (defined SHADOW_ENABLED || defined SHADOW_CLOUD_ENABLED) && SHADOW_FILTER != 0
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
                float theta = i * GoldenAngle + PHI;
                
                float sine = sin(theta);
                float cosine = cos(theta);
                
                pcfDiskOffset[i] = vec2(cosine, sine) * r;
            }

            for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
                float r = sqrt((i + 0.5) / SHADOW_PCSS_SAMPLES);
                float theta = i * GoldenAngle + PHI;
                
                float sine = sin(theta);
                float cosine = cos(theta);
                
                pcssDiskOffset[i] = vec2(cosine, sine) * r;
            }
        #endif
    #endif
}
