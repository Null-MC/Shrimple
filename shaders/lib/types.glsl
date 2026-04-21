#define ENABLE_TYPES

#ifdef ENABLE_TYPES
    #extension GL_NV_gpu_shader5 : enable
    #extension GL_AMD_gpu_shader_half_float : enable

    #define TYPES_ENABLED
#endif

#if defined(TYPES_ENABLED) && (defined(MC_GL_NV_gpu_shader5) || defined(MC_GL_AMD_gpu_shader_half_float))
    #define FLOAT16 float16_t
    #define FLOAT16_3 f16vec3
    #define FLOAT16_4 f16vec4

    FLOAT16_3 RGBToLinear(const in FLOAT16_3 color) {
        return pow(color, FLOAT16_3(2.2));
    }

    FLOAT16 saturate(const in FLOAT16 x) {return clamp(x, FLOAT16(0.0), FLOAT16(1.0));}
#else
    #define FLOAT16 float
    #define FLOAT16_3 vec3
    #define FLOAT16_4 vec4
#endif
