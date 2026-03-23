/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const vec4 colortex1ClearColor = vec4(0.0,0.0,0.0,0.0);
const int colortex2Format = RGBA8;
const vec4 colortex2ClearColor = vec4(1.0,1.0,1.0,0.0);
const int colortex3Format = RG32UI;
const int colortex4Format = RGBA16;
const int colortex5Format = R16;
const int colortex6Format = RGB16F;
const vec4 colortex6ClearColor = vec4(0.0,0.0,0.0,0.0);

const int colortex8Format = R8UI;
const vec4 colortex8ClearColor = vec4(0.0,0.0,0.0,0.0);

const int shadowcolor0Format = RGBA8;
*/


const float sunPathRotation = 20; // [-60 -55 -50 -45 -40 -35 -30 -25 -20 -15 -10 -5 0 1 2 5 10 15 20 25 30 35 40 45 50 55 60]

//#define WIND_ENABLED

#define OVERWORLD_SKY 0 // [0 1]
#define OVERWORLD_NIGHT_BRIGHTNESS 12.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10 12 14 16 18 20 22 24 26 28 30]

#define NETHER_BRIGHTNESS 12 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10 12 14 16 18 20 22 24 26 28 30]

#define BLOCK_OUTLINE_TYPE 2 // [0 1 2]
#define BLOCK_OUTLINE_WIDTH 2 // [1 2 3 4 5 6]
#define BLOCK_OUTLINE_COLOR_R 196 // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 122 124 126 128 130 132 134 136 138 140 142 144 146 148 150 152 154 156 158 160 162 164 166 168 170 172 174 176 178 180 182 184 186 188 190 192 194 196 198 200 202 204 206 208 210 212 214 216 218 220 222 224 226 228 230 232 234 236 238 240 242 244 246 248 250 252 254]
#define BLOCK_OUTLINE_COLOR_G 160 // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 122 124 126 128 130 132 134 136 138 140 142 144 146 148 150 152 154 156 158 160 162 164 166 168 170 172 174 176 178 180 182 184 186 188 190 192 194 196 198 200 202 204 206 208 210 212 214 216 218 220 222 224 226 228 230 232 234 236 238 240 242 244 246 248 250 252 254]
#define BLOCK_OUTLINE_COLOR_B 22  // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 122 124 126 128 130 132 134 136 138 140 142 144 146 148 150 152 154 156 158 160 162 164 166 168 170 172 174 176 178 180 182 184 186 188 190 192 194 196 198 200 202 204 206 208 210 212 214 216 218 220 222 224 226 228 230 232 234 236 238 240 242 244 246 248 250 252 254]
#define BLOCK_OUTLINE_EMISSION 20 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99]

//#define WATER_WAVE_ENABLED
#define WATER_TEXTURE_ENABLED
//#define WATER_ABSORPTION
#define WATER_COLOR_OVERRIDE

#define MATERIAL_FORMAT 0 // [0 1 2]
//#define REFLECT_ENABLED
//#define REFRACT_ENABLED

#define MATERIAL_PARALLAX_ENABLED
#define MATERIAL_PARALLAX_TYPE 1 // [0 1 2]
#define MATERIAL_PARALLAX_SAMPLES 32 // [8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96]
#define MATERIAL_PARALLAX_DEPTH 25 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define MATERIAL_PARALLAX_MAX_DIST 48.0
//#define MATERIAL_PARALLAX_ENTITIES

#define MATERIAL_EMISSION_SCALE 40 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99]
#define MATERIAL_EMISSION_POWER 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]

#define LIGHTING_MODE 0 // [0 1]
#define LIGHTING_MIN 0.400 // [0.000 0.002 0.004 0.006 0.008 0.010 0.012 0.014 0.016 0.018 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.060 0.070 0.080 0.090 0.100 0.150 0.200 0.250 0.300 0.350 0.400 0.450 0.500 0.550 0.600 0.650 0.700 0.800 0.900 1.000 1.200 1.400 1.600 1.800 2.000 2.200 2.400 2.600 2.800 3.000]
#define LIGHTING_HAND
//#define LIGHTING_SPECULAR
//#define LIGHTING_COLORED
#define LIGHTING_COLORED_CANDLES
#define LIGHTING_VOXEL_SIZE 128 // [64 128 256]
#define LPV_FRUSTUM_OFFSET 0

//#define SHADOWS_ENABLED
#define SHADOW_RESOLUTION 1024 // [128 256 512 768 1024 1536 2048 3072 4096 6144 8192]
#define SHADOW_PCF_SAMPLES 3 // [1 2 3 4 5 6 7 8 9]
const float shadowDistance = 100; // [25 50 75 100 125 150 200 250 300 350 400 450 500 600 700 800 900 1000 1200 1400 1600 1800 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000]
#define SHADOW_AMBIENT 100 // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100]
#define SHADOW_COLORED
//#define SHADOW_CLOUDS

//#define BLOOM_ENABLED
#define BLOOM_STRENGTH 3.2 // [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0 4.2 4.4 4.6 4.8 5.0 5.2 5.4 5.6 5.8 6.0 8 10 12 14 16 18 20]
#define BLOOM_LEVELS 6 // [1 2 3 4 5 6 7 8]

#define SSAO_ENABLED
#define SSAO_SAMPLES 4 // [2 4 6 8 10 12]

#define SSR_ENABLED

//#define TONEMAP_ENABLED

#define TAA_ENABLED
#define TAA_SHARPNESS 50 //[0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define TAA_SHARPEN_HISTORY

//#define PHOTONICS_RESTIR_ENABLED
#define PHOTONICS_REFLECT_ENABLED
#define PHOTONICS_REFLECT_STEPS 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define PHOTONICS_HAND_LIGHT_ENABLED
#define PHOTONICS_BLOCK_LIGHT_ENABLED
#define PHOTONICS_BLOCK_TINT_ENABLED
#define PHOTONICS_GI_ENABLED
#define PHOTONICS_GI_BLOCK_SAMPLES 4 // [1 2 3 4 5 6 7 8]
#define PHOTONICS_SHRIMPLE_COLORS

//#define DEBUG
#define DEBUG_VIEW 0 // [0 1 2 3 4]
//#define DEBUG_WHITEWORLD


const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;

#ifdef LIGHTING_COLORED
    const float voxelDistance = 64.0;
#endif

const float AmbientLightF = SHADOW_AMBIENT * 0.01;

#if MATERIAL_FORMAT == FORMAT_DEFAULT && defined(MC_TEXTURE_FORMAT_LAB_PBR)
    #undef MATERIAL_FORMAT
    #define MATERIAL_FORMAT FORMAT_LABPBR
#endif

#if MATERIAL_FORMAT != 0
    #define MATERIAL_PBR_ENABLED
#else
    #undef MATERIAL_PARALLAX_ENABLED
#endif

#ifdef SHADOWS_ENABLED
    const int shadowMapResolution = SHADOW_RESOLUTION;
#else
    const int shadowMapResolution = 2;
#endif

#ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
    #define SHADOW_SAMPLER sampler2DShadow

    #ifdef SHADOW_COLORED
        #define TEX_SHADOW shadowtex1HW
        #define TEX_SHADOW_COLOR shadowtex0HW
    #else
        #define TEX_SHADOW shadowtex0HW
    #endif
#else
    #define SHADOW_SAMPLER sampler2D

    #ifdef SHADOW_COLORED
        #define TEX_SHADOW shadowtex1
        #define TEX_SHADOW_COLOR shadowtex0
    #else
        #define TEX_SHADOW shadowtex0
    #endif
#endif

#ifndef PHOTONICS
    #undef PHOTONICS_REFLECT_ENABLED
    #undef PHOTONICS_HAND_LIGHT_ENABLED
    #undef PHOTONICS_BLOCK_LIGHT_ENABLED
    #undef PHOTONICS_GI_ENABLED
#endif

#ifndef LIGHTING_HAND
    #undef PHOTONICS_HAND_LIGHT_ENABLED
#endif

#if defined(PHOTONICS_HAND_LIGHT_ENABLED) || defined(PHOTONICS_BLOCK_LIGHT_ENABLED) || defined(PHOTONICS_GI_ENABLED)
    #define PHOTONICS_LIGHT_ENABLED
#endif

#ifdef MATERIAL_PARALLAX_ENTITIES
#endif

#ifdef PHOTONICS_RESTIR_ENABLED
#endif

#ifdef PHOTONICS_BLOCK_TINT_ENABLED
#endif

#ifdef PHOTONICS_HAND_LIGHT_ENABLED
#endif

#ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
#endif

#ifdef PHOTONICS_GI_ENABLED
#endif

#ifdef SSR_ENABLED
#endif

#ifdef BLOOM_ENABLED
#endif

#ifdef SSAO_ENABLED
#endif

#if defined(RENDER_ENTITY) && defined(MATERIAL_PARALLAX_ENABLED) && !defined(MATERIAL_PARALLAX_ENTITIES)
    #undef MATERIAL_PARALLAX_ENABLED
#endif

#if defined(SSR_ENABLED) || defined(PHOTONICS_REFLECT_ENABLED)
    // TODO: replace former with latter
    #define REFLECT_ENABLED
    #define DEFERRED_REFLECT_ENABLED
#endif

#if !defined(VOXY) && !defined(DISTANT_HORIZONS)
    #undef SSAO_ENABLED
#endif

#if defined(SSAO_ENABLED) || defined(SSR_ENABLED) || defined(PHOTONICS_LIGHT_ENABLED)
    #define DEFERRED_NORMAL_ENABLED
#endif

#if defined(SSR_ENABLED) || defined(PHOTONICS_LIGHT_ENABLED)
    #define DEFERRED_SPECULAR_ENABLED
#endif

#if defined(DEFERRED_NORMAL_ENABLED) || defined(DEFERRED_SPECULAR_ENABLED)
    #define DEFERRED_ENABLED
#endif

#if defined(TAA_ENABLED) && defined(WIND_ENABLED)
    #define VELOCITY_ENABLED
#endif


#ifdef PHOTONICS_GI_ENABLED
    const float ambientOcclusionLevel = 0.0;
#endif


#define _pow2(x) ((x)*(x))
#define _pow3(x) ((x)*(x)*(x))
#define _saturate(x) (clamp(x, 0.0, 1.0))

float pow4(const in float x) {
    float x2 = _pow2(x);
    return _pow2(x2);
}

float pow5(const in float value) {
    float sq = value*value;
    return sq*sq * value;
}

float pow6(const in float value) {
    float sq = value*value;
    return sq*sq*sq;
}

float safeacos(const in float x) {
    return acos(clamp(x, -1.0, 1.0));
}

float saturate(const in float x) {return _saturate(x);}
vec2 saturate(const in vec2 x) {return _saturate(x);}
vec3 saturate(const in vec3 x) {return _saturate(x);}
vec4 saturate(const in vec4 x) {return _saturate(x);}

float minOf(const in vec2 vec) {return min(vec[0], vec[1]);}
float minOf(const in vec3 vec) {return min(min(vec[0], vec[1]), vec[2]);}
float minOf(const in vec4 vec) {return min(min(vec[0], vec[1]), min(vec[2], vec[3]));}

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}
float maxOf(const in vec3 vec) {return max(max(vec[0], vec[1]), vec[2]);}

int sumOf(ivec2 vec) {return vec.x + vec.y;}
int sumOf(ivec3 vec) {return vec.x + vec.y + vec.z;}
float sumOf(vec2 vec) {return vec.x + vec.y;}
float sumOf(vec3 vec) {return vec.x + vec.y + vec.z;}

float lengthSq(const in vec2 v) {
    return dot(v, v);
}

float lengthSq(const in vec3 v) {
    return dot(v, v);
}

float unmix(const in float valueMin, const in float valueMax, const in float value) {
    return (value - valueMin) / (valueMax - valueMin);
}

float luminance(const in vec3 color) {
    return dot(color, luma_factor);
}

float RGBToLinear(const in float value) {
    return pow(value, 2.2);
}

vec3 RGBToLinear(const in vec3 color) {
    return pow(color, vec3(2.2));
}

vec3 RGBToLinear(const in vec3 color, const in float gamma) {
    return pow(color, vec3(gamma));
}

float LinearToRGB(const in float color) {
    return pow(color, (1.0 / 2.2));
}

vec3 LinearToRGB(const in vec3 color, const in float gamma) {
    return pow(color, vec3(1.0 / gamma));
}

vec3 LinearToRGB(const in vec3 color) {
    return LinearToRGB(color, 2.2);
}

vec3 mul3(const in mat4 matrix, const in vec3 vector) {
    return mat3(matrix) * vector + matrix[3].xyz;
}

vec3 project(const in vec4 pos) {
    return pos.xyz / pos.w;
}

vec3 project(const in mat4 matProj, const in vec3 pos) {
    return project(matProj * vec4(pos, 1.0));
}
