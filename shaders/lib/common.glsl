const float sunPathRotation = -20; // [-60 -50 -40 -30 -20 -15 -10 -5 0 5 10 15 20 30 40 50 60]

/*
const int shadowcolor0Format = RGBA8;
const int colortex0Format  = RGB16F;
const int colortex1Format  = RGBA8;
const int colortex2Format  = RGB8;
const int colortex3Format  = RGBA32UI;
const int colortex4Format  = RGB16F;
const int colortex5Format  = RGB8;
const int colortex6Format  = R32F;
const int colortex7Format  = RGBA16F;
const int colortex8Format  = RGB8;
const int colortex9Format  = R32F;
const int colortex10Format = RGBA16F;
const int colortex11Format  = RGBA16F;
const int colortex12Format  = RGB16F;
const int colortex14Format  = RG8;
const int colortex15Format  = RGBA16F;
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

const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex3MipmapEnabled = false;
const bool colortex3Clear = true;

const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex4MipmapEnabled = false;
const bool colortex4Clear = false;

const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex5MipmapEnabled = false;
const bool colortex5Clear = false;

const vec4 colortex6ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex6MipmapEnabled = false;
const bool colortex6Clear = false;

const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex7MipmapEnabled = false;
const bool colortex7Clear = false;

const vec4 colortex8ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex8MipmapEnabled = false;
const bool colortex8Clear = false;

const vec4 colortex9ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex9MipmapEnabled = false;
const bool colortex9Clear = false;

const vec4 colortex10ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex10MipmapEnabled = false;
const bool colortex10Clear = true;

const vec4 colortex11ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex11MipmapEnabled = false;
const bool colortex11Clear = false;

const vec4 colortex12ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex12MipmapEnabled = false;
const bool colortex12Clear = false;

const vec4 colortex14ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex14MipmapEnabled = false;
const bool colortex14Clear = true;

const vec4 colortex15ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex15MipmapEnabled = false;
const bool colortex15Clear = true;


// World Options
#define WORLD_WETNESS_ENABLED
#define WORLD_WAVING_ENABLED
#define WORLD_AMBIENT_MODE 1 // [0 1 2]
#define WORLD_AO_ENABLED
#define WORLD_SKY_REFLECTIONS 100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_WETNESS_PUDDLES 3 // [0 1 2 3]
#define WORLD_RAIN_OPACITY 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_SUN_BRIGHTNESS 200 // [10 20 30 40 50 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]
#define WORLD_MOON_BRIGHTNESS 100 // [10 20 30 40 50 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]
#define WORLD_LIGHT_MIN 1 // [0 1 2 4 6 8 10 12 14 16 20 24 28 32]
#define WORLD_FOG_MODE 2 // [0 1 2]
#define WORLD_FOG_SKY_START 20 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_FOG_SKY_DENSITY 140 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define WORLD_FOG_SCALE 100 // [20 40 60 80 100 120 140 160 180 200 250 300 250 400 500 600]


// Water Options
#define WORLD_WATER_TEXTURE 0 // [0 1]
#define WORLD_WATER_OPACITY 100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_WATER_WAVES 1 // [0 1 2]
#define WORLD_WATER_PIXEL 0 // [0 8 16 32 64 128]
#define WATER_WAVE_MIN 0.1


// Material Options
#define MATERIAL_NORMALS 0 // [0 1 2 3]
#define MATERIAL_NORMAL_SCALE 4 // [1 2 4 8 16]
#define MATERIAL_NORMAL_STRENGTH 100 // [50 100 150 200 250 300 350 400 500 600 700 800]
#define MATERIAL_NORMAL_ROUND 40 // [0 10 20 30 40 50 60 70 80 90 100]
#define MATERIAL_NORMAL_EDGE 0 // [0 1 2]
#define MATERIAL_EMISSION 0 // [0 1 2]
#define MATERIAL_EMISSION_BRIGHTNESS 400 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 350 400 450 500 550 600 650 700 750 800 950 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000]
#define MATERIAL_SSS 1 // [0 1 2]
#define MATERIAL_SSS_MAXDIST 6.0
#define MATERIAL_SPECULAR 1 // [0 1 2 3]
#define MATERIAL_PARALLAX 0 // [0 1 2 3]
#define MATERIAL_PARALLAX_SAMPLES 32 // [16 24 32 48 64 96 128]
#define MATERIAL_PARALLAX_SHADOW_SAMPLES 0 // [0 16 24 32 48 64 96 128]
#define MATERIAL_PARALLAX_DEPTH 25 // [5 10 15 20 25 30 40 50 60 70 80 90 100]
#define MATERIAL_PARALLAX_DISTANCE 30 // [10 20 30 40 50 60 70 80]
#define MATERIAL_PARALLAX_SHARP_THRESHOLD 1 // [1 2 3 4 6 8 12 16 20 24 28]
#define MATERIAL_POROSITY 1 // [0 1 2]
#define MATERIAL_OCCLUSION 1 // [0 1 2]
#define METAL_BRIGHTNESS 30 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define MATERIAL_PARTICLES


// Shadow Options
#define SHADOW_TYPE 2 // [0 2 3]
//#define SHADOW_COLORED
//#define SHADOW_COLOR_BLEND
#define SHADOW_BRIGHTNESS 20 // [0 1 2 3 4 6 8 10 12 14 16 18 20 22 24 28 32 36 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define SHADOW_BIAS_SCALE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.8 2.9 3.0 3.2 3.4 3.6 3.8 4.0]
#define SHADOW_DISTORT_FACTOR 0.20 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define SHADOW_FILTER 1 // [0 1 2]
#define SHADOW_PCF_SIZE_MIN 1 // [0 1 2 3 4 5 6 7 8 9 10 12 14 16 18 20]
#define SHADOW_PCF_SIZE_MAX 10 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 35 40 45 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define SHADOW_PCF_SAMPLES 4 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_PCSS_SAMPLES 4 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_ENABLE_HWCOMP
#define SHADOW_BLUR

#define SHADOW_PENUMBRA_MIN 0.03
#define SHADOW_PENUMBRA_SCALE 0.08
#define SHADOW_DISTORTED_NORMAL_BIAS 0.02
#define SHADOW_CASCADED_NORMAL_BIAS 0.02
//#define SHADOW_FRUSTUM_CULL
#define SHADOW_CSM_FITRANGE
#define SHADOW_CSM_OVERLAP

#define SHADOW_CLOUD_ENABLED
#define SHADOW_CLOUD_RADIUS 3.0 // [0.2 0.4 0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define SHADOW_CLOUD_BRIGHTNESS 40 // [0 10 20 30 40 50 60 70 80 90 100]


// Dynamic Lighting
#define DYN_LIGHT_MODE 0 // [0 2 3]
#define DYN_LIGHT_TYPE 0 // [0 1]
#define DYN_LIGHT_COLOR_MODE 0 // [0 1]
#define DYN_LIGHT_BRIGHTNESS 200 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 700 800 900]
#define DYN_LIGHT_DIRECTIONAL 100 // [0 10 20 30 40 50 60 70 80 90 100]
#define DYN_LIGHT_AMBIENT 35 // [0 2 4 6 8 10 12 14 16 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define DYN_LIGHT_FLICKER
#define DYN_LIGHT_TINT_MODE 1 // [0 1 2]
#define DYN_LIGHT_TINT 100 // [0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define DYN_LIGHT_PENUMBRA 20 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define DYN_LIGHT_RES 2 // [0 1 2]
#define LIGHT_BIN_MAX_COUNT 128 // [16 32 48 64 96 128 160 192 224 256 320 384 448 512]
#define LIGHT_BIN_SIZE 8 // [4 8 16]
#define LIGHT_SIZE_XZ 32 // [4 8 16 32 64]
#define LIGHT_SIZE_Y 16 // [4 8 16 32]
#define DYN_LIGHT_TRACE_METHOD 0 // [0 1]
#define DYN_LIGHT_RAY_QUALITY 2 // [1 2 4 8]
#define DYN_LIGHT_POPULATE_NEIGHBORS
#define DYN_LIGHT_FRUSTUM_TEST
#define DYN_LIGHT_PLAYER_SHADOW 2 // [0 1 2]
#define DYN_LIGHT_FALLBACK
//#define DYN_LIGHT_WEATHER
//#define DYN_LIGHT_BLOCK_ENTITIES
#define DYN_LIGHT_SAMPLE_MAX 16 // [0 2 4 8 12 16 24 32 48 64 96 128]
#define DYN_LIGHT_BLUR
#define DYN_LIGHT_RANGE 80 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 180 200 220 240 260 280 300]
#define DYN_LIGHT_TA 60 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]

// Dynamic LPV
#define LPV_SIZE 2 // [0 1 2 3]
#define LPV_RANGE 100 // [25 50 75 100 150 200 250 300 400 600 800 1200 1600]
#define LPV_SUN_SAMPLES 3 // [0 1 2 3 4 5 6 7 8 9 12 15 18 21 25]
#define LPV_SAMPLE_MODE 1 // [0 1 2]
#define LPV_LIGHTMAP_MIX 25 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define LPV_GLASS_TINT
#define LPV_BRIGHT_MOON 16.0
#define LPV_BRIGHT_SUN 512.0

//#define DYN_LIGHT_OCTREE
#define DYN_LIGHT_OCTREE_LEVELS 2u
#define DYN_LIGHT_OCTREE_SIZE 1u

// Dynamic Light Blocks
#define DYN_LIGHT_GLOW_BERRIES 2 // [0 1 2]
#define DYN_LIGHT_LAVA 2 // [0 1 2]
#define DYN_LIGHT_PORTAL 2 // [0 1 2]
#define DYN_LIGHT_REDSTONE 0 // [0 1 2]
#define DYN_LIGHT_SEA_PICKLE 2 // [0 1 2]


// Volumetric Lighting
//#define VOLUMETRIC_CELESTIAL
#define VOLUMETRIC_BLOCK_MODE 0 // [0 1 2 3]
#define VOLUMETRIC_BLOCK_RANGE 50 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define VOLUMETRIC_SAMPLES 12 // [8 12 16 24]
#define VOLUMETRIC_DENSITY 100 // [5 10 15 20 25 30 40 50 60 70 80 90 100 125 150 175 200 250 300 400 600 800 1000]
#define VOLUMETRIC_RES 0 // [0 1 2]
#define VOLUMETRIC_BRIGHT_SKY   0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_BRIGHT_BLOCK 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_BLUR
//#define VOLUMETRIC_BLOCK_RT
//#define VOLUMETRIC_HANDLIGHT
#define VOLUMETRIC_SKY_DAY_DENSITY 30 // [0 10 20 30 40 50 60 70 80 90 100]



// Post-Processing
#define TONEMAP_ENABLED
#define FXAA_ENABLED
#define POST_BRIGHTNESS 100 // [0 10 20 30 40 50 60 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define POST_SATURATION 100 // [0 10 20 30 40 50 60 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200]
#define POST_CONTRAST 100 // [80 85 90 92 94 96 98 100 102 104 106 108 110 115 120]
#define GAMMA_OUT 2.2 // [1.0 1.2 1.4 1.6 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.8 3.0 3.2 3.4 3.6]
#define POST_BLOOM_STRENGTH 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define POST_BLOOM_THRESHOLD 160 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300]
#define POST_WHITE_POINT 300 // [50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 700 800 900]


// Debug Options
#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14]
//#define DYN_LIGHT_DEBUG_COUNTS
//#define DYN_LIGHT_OREBLOCKS
#define DEFER_TRANSLUCENT
#define REFRACTION_STRENGTH 100 // [0 10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
//#define REFRACTION_SNELL_ENABLED
//#define SHADOW_FORCE_CULLING
#define AF_SAMPLES 1
#define LIGHT_LEAK_FIX


// INTERNAL SETTINGS
#define PHYSICS_OCEAN_SUPPORT
#define SHADOW_CSM_FIT_FARSCALE 1.1
#define SHADOW_CSM_FITSCALE 0.1
#define CSM_PLAYER_ID 0
#define ROUGH_MIN 0.06
#define WHITEWORLD_VALUE 0.9
//#define TRANSLUCENT_SSS_ENABLED
#define DIRECTIONAL_LIGHTMAP
#define RIPPLE_STRENGTH 0.03
#define BLOOM_TILE_MAX_COUNT 6

#define PI 3.1415926538
#define TAU 6.2831853076
#define IOR_AIR 1.00
#define IOR_WATER 1.33
#define EPSILON 1e-6
#define GAMMA 2.2

#define TEMP_FIRE_MIN 2200
#define TEMP_FIRE_MAX 2800
#define TEMP_SOUL_FIRE_MIN 1200
#define TEMP_SOUL_FIRE_MAX 1800
#define TEMP_CANDLE_MIN 2000
#define TEMP_CANDLE_MAX 2400

#define DYN_LIGHT_MASK_STRIDE 8
#define DYN_BLOCK_MASK_STRIDE 16
#define LIGHT_MAX_COUNT 2000000u
#define BLOCK_MASK_PARTS 6u

#define LIGHT_BIN_SIZE3 (LIGHT_BIN_SIZE*LIGHT_BIN_SIZE*LIGHT_BIN_SIZE)

#if (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * (4*LIGHT_BIN_MAX_COUNT+8)) < (1024*1024*32)
    #define DYN_LIGHT_SSBO_SIZE 32
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * (4*LIGHT_BIN_MAX_COUNT+8)) < (1024*1024*64)
    #define DYN_LIGHT_SSBO_SIZE 64
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * (4*LIGHT_BIN_MAX_COUNT+8)) < (1024*1024*128)
    #define DYN_LIGHT_SSBO_SIZE 128
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * (4*LIGHT_BIN_MAX_COUNT+8)) < (1024*1024*256)
    #define DYN_LIGHT_SSBO_SIZE 256
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * (4*LIGHT_BIN_MAX_COUNT+8)) < (1024*1024*512)
    #define DYN_LIGHT_SSBO_SIZE 512
#else
    #define DYN_LIGHT_SSBO_SIZE 1024
#endif

#if   (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT / 4 + 1) < (2048*2048)
    #define DYN_LIGHT_IMG_SIZE 2048
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT / 4 + 1) < (4096*4096)
    #define DYN_LIGHT_IMG_SIZE 4096
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT / 4 + 1) < (8192*8192)
    #define DYN_LIGHT_IMG_SIZE 8192
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_MAX_COUNT / 4 + 1) < (12288*12288)
    #define DYN_LIGHT_IMG_SIZE 12288
#else
    #define DYN_LIGHT_IMG_SIZE 16384
#endif

#if   (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_SIZE3) < (2048*2048)
    #define DYN_LIGHT_BLOCK_IMG_SIZE 2048u
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_SIZE3) < (4096*4096)
    #define DYN_LIGHT_BLOCK_IMG_SIZE 4096u
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_SIZE3) < (8192*8192)
    #define DYN_LIGHT_BLOCK_IMG_SIZE 8192u
#elif (LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y * LIGHT_BIN_SIZE3) < (12288*12288)
    #define DYN_LIGHT_BLOCK_IMG_SIZE 12288u
#else
    #define DYN_LIGHT_BLOCK_IMG_SIZE 16384u
#endif

#if   LPV_SIZE == 3
    #define LPV_BLOCK_SIZE 256
    #define LPV_PADDING 32
#elif LPV_SIZE == 2
    #define LPV_BLOCK_SIZE 128
    #define LPV_PADDING 16
#else
    #define LPV_BLOCK_SIZE 64
    #define LPV_PADDING 8
#endif

#ifndef MC_GL_VENDOR_INTEL
    #define DYN_LIGHT_GRID_MAX -1u
#else
    #define DYN_LIGHT_GRID_MAX uint(-1)
#endif

#if (VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != 0) || (VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO)
    #define VL_BUFFER_ENABLED
#endif

#if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR) || defined VL_BUFFER_ENABLED
    #define DEFERRED_BUFFER_ENABLED
#endif

#if defined SHADOW_CLOUD_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
    #define RENDER_CLOUD_SHADOWS_ENABLED
#endif


#ifdef WORLD_WETNESS_ENABLED
#endif
#ifdef WORLD_AO_ENABLED
#endif
#ifdef DIRECTIONAL_LIGHTMAP
#endif
#ifdef SHADOW_BLUR
#endif
#ifdef SHADOW_COLORED
#endif
#ifdef SHADOW_COLOR_BLEND
#endif
#ifdef DYN_LIGHT_LAVA_ENABLED
#endif
#ifdef DYN_LIGHT_REDSTONE_ENABLED
#endif
#ifdef DYN_LIGHT_SEA_PICKLE
#endif
#ifdef DYN_LIGHT_DEBUG_COUNTS
#endif
#ifdef DYN_LIGHT_WEATHER
#endif
#ifdef DYN_LIGHT_BLUR
#endif
#ifdef DYN_LIGHT_OREBLOCKS
#endif
#ifdef VOLUMETRIC_BLOCK_RT
#endif
#ifdef DEFER_TRANSLUCENT
#endif
#ifdef LIGHT_LEAK_FIX
#endif
#ifdef SHADOW_FORCE_CULLING
#endif


const vec3 HandLightOffsetL = vec3(-0.16, -0.24, -0.08);
const vec3 HandLightOffsetR = vec3( 0.16, -0.24, -0.08);

const float WorldMinLightF = WORLD_LIGHT_MIN * 0.01;
const float WorldSunBrightnessF = WORLD_SUN_BRIGHTNESS * 0.01;
const float WorldMoonBrightnessF = WORLD_MOON_BRIGHTNESS * 0.01;
const float WorldWaterOpacityF = WORLD_WATER_OPACITY * 0.01;
const float WorldRainOpacityF = WORLD_RAIN_OPACITY * 0.01;
const float WorldSkyReflectF = WORLD_SKY_REFLECTIONS * 0.01;
const float WorldFogSkyStartF = WORLD_FOG_SKY_START * 0.01;
const float WorldFogSkyDensityF = WORLD_FOG_SKY_DENSITY * 0.01;
const float WorldFogScaleF = WORLD_FOG_SCALE * 0.01;
const float MaterialNormalStrengthF = MATERIAL_NORMAL_STRENGTH * 0.01;
const float MaterialNormalRoundF = MATERIAL_NORMAL_ROUND * 0.01;
const float MaterialEmissionF = MATERIAL_EMISSION_BRIGHTNESS * 0.01;
const float MaterialMetalBrightnessF = METAL_BRIGHTNESS * 0.01;
const float ParallaxDepthF = MATERIAL_PARALLAX_DEPTH * 0.01;
const float ParallaxSharpThreshold = (MATERIAL_PARALLAX_SHARP_THRESHOLD+0.5) / 255.0;
const float VolumetricDensityF = VOLUMETRIC_DENSITY * 0.01;
const float VolumetricBlockRangeF = VOLUMETRIC_BLOCK_RANGE * 0.01;
const float VolumetricBrightnessSky = VOLUMETRIC_BRIGHT_SKY * 0.01;
const float VolumetricBrightnessBlock = VOLUMETRIC_BRIGHT_BLOCK * 0.01;
const float VolumetricSkyDayDensityF = VOLUMETRIC_SKY_DAY_DENSITY * 0.01;
const float DynamicLightAmbientF = DYN_LIGHT_AMBIENT * 0.01;
const float DynamicLightDirectionalF = DYN_LIGHT_DIRECTIONAL * 0.01;
const float DynamicLightTintF = DYN_LIGHT_TINT * 0.01;
const float DynamicLightPenumbraF = DYN_LIGHT_PENUMBRA * 0.01;
const float DynamicLightBrightness = DYN_LIGHT_BRIGHTNESS * 0.01;
const float DynamicLightTemporalStrength = DYN_LIGHT_TA * 0.01;
const float DynamicLightRangeF = DYN_LIGHT_RANGE * 0.01;
const float LpvLightmapMixF = LPV_LIGHTMAP_MIX * 0.01;
const float LpvRangeF = LPV_RANGE * 0.01;
const float ShadowBrightnessF = SHADOW_BRIGHTNESS * 0.01;
const float ShadowMinPcfSize = SHADOW_PCF_SIZE_MIN * 0.01;
const float ShadowMaxPcfSize = SHADOW_PCF_SIZE_MAX * 0.01;
const float ShadowCloudBrightnessF = SHADOW_CLOUD_BRIGHTNESS * 0.01;
const float RefractionStrengthF = REFRACTION_STRENGTH * 0.01;
const float PostBrightnessF = POST_BRIGHTNESS * 0.01;
const float PostSaturationF = POST_SATURATION * 0.01;
const float PostContrastF = POST_CONTRAST * 0.01;
const float PostBloomStrengthF = POST_BLOOM_STRENGTH * 0.01;
const float PostBloomThresholdF = POST_BLOOM_THRESHOLD * 0.01;
const float PostWhitePoint = POST_WHITE_POINT * 0.01;

const float invPI = 1.0 / PI;
const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);
const vec2 EPSILON2 = vec2(EPSILON);
const vec3 EPSILON3 = vec3(EPSILON);

const float wetnessHalflife = 16000.0;
const float drynessHalflife = 20.0;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    const float ShadowNormalBias = (SHADOW_CASCADED_NORMAL_BIAS * SHADOW_BIAS_SCALE);
#else
    const float ShadowNormalBias = (SHADOW_DISTORTED_NORMAL_BIAS * SHADOW_BIAS_SCALE);
#endif

const float shadowDistanceRenderMul = 1.0;

const float shadowDistance = 100; // [25 50 75 100 125 150 200 250 300 400 600 800]
const int shadowMapResolution = 1536; // [128 256 512 768 1024 1536 2048 3072 4096 6144 8192]
const float shadowIntervalSize = 2.0f;

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


#define rcp(x) (1.0 / (x))

#define _pow2(x) (x*x)
#define _pow3(x) (x*x*x)

#define modelPart(x, y, z) (vec3(x, y, z)/16.0)

uint pow3(const in uint x) {return x*x*x;}
float pow3(const in float x) {return x*x*x;}
vec2  pow3(const in vec2  x) {return x*x*x;}
float pow4(const in float x) {float x2 = _pow2(x); return _pow2(x2);}
float pow5(const in float x) {return x * pow4(x);}

float saturate(const in float x) {return clamp(x, 0.0, 1.0);}
vec2 saturate(const in vec2 x) {return clamp(x, vec2(0.0), vec2(1.0));}
vec3 saturate(const in vec3 x) {return clamp(x, vec3(0.0), vec3(1.0));}

float length2(const in vec2 vec) {return dot(vec, vec);}
float length2(const in vec3 vec) {return dot(vec, vec);}

float minOf(const in vec2 vec) {return min(vec[0], vec[1]);}
float minOf(const in vec3 vec) {return min(min(vec[0], vec[1]), vec[2]);}
float minOf(const in vec4 vec) {return min(min(vec[0], vec[1]), min(vec[2], vec[3]));}

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}
float maxOf(const in vec3 vec) {return max(max(vec[0], vec[1]), vec[2]);}

float RGBToLinear(const in float value) {
    return pow(value, GAMMA);
}

vec3 RGBToLinear(const in vec3 color) {
	return pow(color, vec3(GAMMA));
}

float LinearToRGB(const in float color) {
	return pow(color, rcp(GAMMA));
}

vec3 LinearToRGB(const in vec3 color, const in float gamma) {
    return pow(color, vec3(rcp(gamma)));
}

vec3 LinearToRGB(const in vec3 color) {
    return LinearToRGB(color, GAMMA);
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

uint half2float(const in uint h) {
    return ((h & uint(0x8000)) << 16u) | (((h & uint(0x7c00)) + uint(0x1c000)) << 13u) | ((h & uint(0x03ff)) << 13u);
}

uint float2half(const in uint f) {
    return ((f >> 16u) & uint(0x8000)) |
        ((((f & uint(0x7f800000)) - uint(0x38000000)) >> 13u) & uint(0x7c00)) |
        ((f >> 13u) & uint(0x03ff));
}

void fixNaNs(inout vec3 vec) {
    if (isnan(vec.x) || isinf(vec.x)) vec.x = EPSILON;
    if (isnan(vec.y) || isinf(vec.y)) vec.y = EPSILON;
    if (isnan(vec.z) || isinf(vec.z)) vec.z = EPSILON;
}
