const float sunPathRotation = -20; // [-60 -50 -40 -30 -20 -15 -10 -5 0 5 10 15 20 30 40 50 60]

/*
const int shadowcolor0Format = RGBA8;
const int colortex0Format = RGB8;
const int colortex1Format = RGB32UI;
const int colortex2Format = RG32UI;
const int colortex3Format = RGB16F;
const int colortex4Format = RGB8;
const int colortex5Format = R32F;
*/

const bool generateShadowMipmap = false;
const bool generateShadowColorMipmap = false;

const vec4 shadowcolor0ClearColor = vec4(1.0, 1.0, 1.0, 0.0);
const bool shadowcolor0Clear = true;

const bool shadowtex0Mipmap = false;
const bool shadowtex1Mipmap = false;

const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex0MipmapEnabled = false;
const bool colortex0Clear = false;

const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex1MipmapEnabled = false;
const bool colortex1Clear = true;

const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex2MipmapEnabled = false;
const bool colortex2Clear = true;

const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex3MipmapEnabled = false;
const bool colortex3Clear = false;

const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex4MipmapEnabled = false;
const bool colortex4Clear = false;

const vec4 colortex5ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex5MipmapEnabled = false;
const bool colortex5Clear = false;


// World Options
#define ENABLE_WAVING
#define OLD_LIGHTING
#define FOLIAGE_UP


// Shadow Options
#define SHADOW_TYPE 2 // [0 2 3]
#define SHADOW_COLORS 2 // [0 1 2]
//#define SHADOW_COLOR_BLEND
#define SHADOW_BRIGHTNESS 15 // [0 1 2 3 4 6 8 10 15 20 25 30 35 40 45 50]
#define SHADOW_BIAS_SCALE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]
#define SHADOW_DISTORT_FACTOR 0.20 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define SHADOW_FILTER 1 // [0 1 2]
#define SHADOW_PCF_SIZE 60 // [2 4 6 8 10 15 20 25 30 35 40 45 50 60 70 80 90 100 120 140 160 180 200 250 300 350 400 450 500 600 700 800]
#define SHADOW_PCF_SAMPLES 4 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_PCSS_SAMPLES 4 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_ENABLE_HWCOMP
//#define SHADOW_BLUR

#define SHADOW_PENUMBRA_SCALE 0.06
#define SHADOW_DISTORTED_NORMAL_BIAS 0.02
#define SHADOW_CASCADED_NORMAL_BIAS 0.006
#define SHADOW_CSM_FITRANGE
#define SHADOW_CSM_OVERLAP


// Dynamic Lighting
#define DYN_LIGHT_MODE 1 // [0 1 2 3]
#define DYN_LIGHT_COLORS 0 // [0 1]
#define DYN_LIGHT_BRIGHTNESS 200 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define DYN_LIGHT_DIRECTIONAL
#define DYN_LIGHT_FLICKER
#define DYN_LIGHT_LAVA 1 // [0 1 2]
#define DYN_LIGHT_REDSTONE 1 // [0 1 2]
#define LIGHT_BIN_MAX_COUNT 64 // [16 32 48 64 96 128 160 192 224 256 512]
#define LIGHT_BIN_SIZE 8 // [4 8 16]
#define LIGHT_SIZE_XZ 16 // [4 8 16 32 64]
#define LIGHT_SIZE_Y 8 // [4 8 16 32]
#define LIGHT_COLOR_NEIGHBORS
//#define LIGHT_DEBUG_MASK
#define DYN_LIGHT_FRUSTUM_TEST
#define DYN_LIGHT_TRACE_METHOD 0 // [0 1]
#define DYN_LIGHT_RAY_QUALITY 2 // [1 2 4 8]
#define DYN_LIGHT_TINT 100 // [0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define DYN_LIGHT_PENUMBRA 0 // [0 1 2 3 4 5 6 8 10 15 20 25 30 35 40 50]
#define DYN_LIGHT_TEMPORAL 0 // [0 2 5]
#define DYN_LIGHT_RES 1 // [0 1 2]
#define DYN_LIGHT_FALLBACK
#define DYN_LIGHT_BLUR

#define LIGHT_MAX_COUNT 4200000000u
#define LIGHT_BIN_SIZE3 (LIGHT_BIN_SIZE*LIGHT_BIN_SIZE*LIGHT_BIN_SIZE)
#define DYN_LIGHT_MASK_STRIDE 8

#if (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT) >= 16777216
    #define DYN_LIGHT_IMG_SIZE 8192
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT) >= 4194304
    #define DYN_LIGHT_IMG_SIZE 4096
#else
    #define DYN_LIGHT_IMG_SIZE 2048
#endif


// Post-Processing
//#define TONEMAP_ENABLED
#define TONEMAP_CONTRAST 0.00 // [-0.02 -0.01 0.00 0.01 0.02 0.03 0.04]
#define FXAA_ENABLED
#define AF_SAMPLES 1


// Debug Options
#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7]
//#define DYN_LIGHT_DEBUG_COUNTS


// INTERNAL SETTINGS
#define SHADOW_CSM_FIT_FARSCALE 1.1
#define SHADOW_CSM_FITSCALE 0.1
#define CSM_PLAYER_ID 0

#define PI 3.1415926538
#define TAU 6.2831853076
#define EPSILON 1e-6
#define GAMMA 2.2


const vec3 HandLightOffsetL = vec3(-0.16, -0.24, -0.08);
const vec3 HandLightOffsetR = vec3( 0.16, -0.24, -0.08);

const float WorldBrightnessF = WORLD_BRIGHTNESS * 0.01;
const float DynamicLightTintF = DYN_LIGHT_TINT * 0.01;
const float DynamicLightPenumbra = DYN_LIGHT_PENUMBRA * 0.01;
const float DynamicLightBrightness = DYN_LIGHT_BRIGHTNESS * 0.01;
const float ShadowBrightnessF = SHADOW_BRIGHTNESS * 0.01;
const float ShadowPCFSize = SHADOW_PCF_SIZE * 0.001;

const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    const float ShadowNormalBias = SHADOW_CASCADED_NORMAL_BIAS;
#else
    const float ShadowNormalBias = SHADOW_DISTORTED_NORMAL_BIAS;
#endif

const float shadowDistanceRenderMul = 1.0;

const float shadowDistance = 150; // [50 100 150 200 300 400 800]
const int shadowMapResolution = 2048; // [128 256 512 1024 2048 4096 8192]

#ifdef MC_SHADOW_QUALITY
    const float shadowMapSize = shadowMapResolution * MC_SHADOW_QUALITY;
#else
    const float shadowMapSize = shadowMapResolution;
#endif

const float shadowPixelSize = 1.0 / shadowMapSize;

#ifdef SHADOW_ENABLE_HWCOMP
    const bool shadowHardwareFiltering = true;
    //const bool shadowHardwareFiltering0 = true;
    //const bool shadowHardwareFiltering1 = true;
    const bool shadowtex0Nearest = false;
    const bool shadowtex1Nearest = false;
    const bool shadowcolor0Nearest = false;
#endif

#if MC_VERSION < 11700
    const float alphaTestRef = 0.1;
#endif

#ifdef OLD_LIGHTING
#endif
#ifdef FOLIAGE_UP
#endif
#ifdef SHADOW_BLUR
#endif
#ifdef SHADOW_COLOR_BLEND
#endif
#ifdef DYN_LIGHT_LAVA_ENABLED
#endif
#ifdef DYN_LIGHT_REDSTONE_ENABLED
#endif
#ifdef DYN_LIGHT_DEBUG_COUNTS
#endif
#ifdef IRIS_FEATURE_CLEARFIX
#endif


#define rcp(x) (1.0 / (x))

#define pow2(x) (x*x)

float saturate(const in float x) {return clamp(x, 0.0, 1.0);}
vec2 saturate(const in vec2 x) {return clamp(x, vec2(0.0), vec2(1.0));}
vec3 saturate(const in vec3 x) {return clamp(x, vec3(0.0), vec3(1.0));}

float minOf(const in vec2 vec) {return min(vec[0], vec[1]);}
float minOf(const in vec3 vec) {return min(min(vec[0], vec[1]), vec[2]);}
float minOf(const in vec4 vec) {return min(min(vec[0], vec[1]), min(vec[2], vec[3]));}

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}
float maxOf(const in vec3 vec) {return max(max(vec[0], vec[1]), vec[2]);}

vec3 RGBToLinear(const in vec3 color) {
	return pow(color, vec3(GAMMA));
}

vec3 LinearToRGB(const in vec3 color) {
	return pow(color, vec3(1.0 / GAMMA));
}

float luminance(const in vec3 color) {
   return dot(color, luma_factor);
}

vec3 unproject(const in vec4 pos) {
    return pos.xyz / pos.w;
}

float expStep(const in float x) {
    return 1.0 - exp(-x*x);
}
