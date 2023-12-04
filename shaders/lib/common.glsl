const float sunPathRotation = -20; // [-60 -55 -50 -45 -40 -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50 55 60]

/*
const int shadowcolor0Format = RGBA8;
const int colortex0Format  = RGB16F;
const int colortex1Format  = RGBA8;
const int colortex2Format  = RGBA8;
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
const int colortex13Format  = R32F;
const int colortex14Format  = RGB8;
const int colortex15Format  = RGBA16F;
*/

const bool generateShadowMipmap = false;
const bool generateShadowColorMipmap = false;

const vec4 shadowcolor0ClearColor = vec4(1.0, 1.0, 1.0, 0.0);
const bool shadowcolor0Clear = true;

const bool shadowtex0Mipmap = false;
const bool shadowtex1Mipmap = false;

const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex0Clear = false;

const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex1Clear = true;

const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex2Clear = true;

const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex3Clear = true;

const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex4Clear = false;

const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex5Clear = false;

const vec4 colortex6ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex6Clear = false;

const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex7Clear = false;

const vec4 colortex8ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex8Clear = false;

const vec4 colortex9ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex9Clear = false;

const vec4 colortex10ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex10Clear = true;

const vec4 colortex11ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex11Clear = false;

const vec4 colortex12ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex12Clear = false;

const vec4 colortex13ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex13Clear = true;

const vec4 colortex14ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex14Clear = true;

const vec4 colortex15ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex15Clear = true;


// Sky Options
#define SKY_TYPE 1 // [0 1]
#define SKY_CLOUD_TYPE 1 // [0 1 2]
#define SKY_BORDER_FOG_ENABLED
#define SKY_VOL_FOG_TYPE 1 // [0 1 2]
#define SKY_FOG_SHAPE 0 // [0 1 2]
#define SKY_WEATHER_OPACITY 60 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define SKY_SUN_BRIGHTNESS 300  // [10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]
#define SKY_MOON_BRIGHTNESS 20 // [1 2 4 6 8 10 12 14 16 18 20 25 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define SKY_BRIGHTNESS 300  // [10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]

#define WORLD_CLOUD_HEIGHT 96


// World Options
#define WORLD_WETNESS_ENABLED
#define WORLD_WAVING_ENABLED
//#define WORLD_AMBIENT_MODE 1 // [0 1 2]
#define WORLD_AO_ENABLED
//#define WORLD_SKY_REFLECTIONS 100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_WETNESS_PUDDLES 3 // [0 1 2 3]


// Water Options
#define WATER_SURFACE_TYPE 0 // [0 1]
#define WATER_OPACITY 75 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WATER_WAVE_SIZE 2 // [0 1 2 3]
#define WATER_SURFACE_PIXEL_RES 0 // [0 8 16 32 64 128]
#define WATER_VOL_FOG_TYPE 1 // [0 1 2]
#define WATER_FOG_DENSITY 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 500 600]
#define WATER_WAVE_MIN 0.1
#define WATER_REFLECTIONS
#define WATER_DISPLACEMENT
#define WATER_CAUSTICS

#define WATER_BLUR
#define WATER_BLUR_SCALE 12.0
#define WATER_BLUR_RADIUS 28 // [4 8 12 16 20 24 28 32]
#define WATER_DEPTH_LAYERS 1 // [1 2 3 4 5 6]


// Material Options
#define MATERIAL_NORMALS 1 // [0 1 2 3]
#define MATERIAL_NORMAL_SCALE 2 // [1 2 4 8 16]
#define MATERIAL_NORMAL_STRENGTH 100 // [50 100 150 200 250 300 350 400 500 600 700 800]
#define MATERIAL_NORMAL_ROUND 40 // [0 10 20 30 40 50 60 70 80 90 100]
#define MATERIAL_NORMAL_EDGE 0 // [0 1 2]
#define MATERIAL_EMISSION 0 // [0 1 2]
#define MATERIAL_EMISSION_BRIGHTNESS 400 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 350 400 450 500 550 600 650 700 750 800 950 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000]
#define MATERIAL_SSS 1 // [0 1 2]
#define MATERIAL_SSS_MAXDIST 0.8
#define MATERIAL_SSS_SCATTER 100 // [0 10 20 30 40 50 60 70 80 90 100]
#define MATERIAL_SSS_BOOST 200 // [100 120 140 160 180 200 220 240 260 280 300]
#define MATERIAL_SPECULAR 1 // [0 1 2 3]
#define MATERIAL_PARALLAX 0 // [0 1 2 3]
#define MATERIAL_PARALLAX_SAMPLES 32 // [16 24 32 48 64 96 128]
#define MATERIAL_PARALLAX_SHADOW_SAMPLES 0 // [0 16 24 32 48 64 96 128]
//#define MATERIAL_PARALLAX_SHADOW_SMOOTH
#define MATERIAL_PARALLAX_DEPTH 25 // [5 10 15 20 25 30 40 50 60 70 80 90 100]
#define MATERIAL_PARALLAX_DISTANCE 30 // [10 20 30 40 50 60 70 80]
#define MATERIAL_PARALLAX_SHARP_THRESHOLD 1 // [1 2 3 4 6 8 12 16 20 24 28]
//#define MATERIAL_PARALLAX_DEPTH_WRITE
#define MATERIAL_PARALLAX_ENTITIES
#define MATERIAL_POROSITY 1 // [0 1 2]
#define MATERIAL_POROSITY_DARKEN 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define MATERIAL_OCCLUSION 1 // [0 1 2]
#define METAL_BRIGHTNESS 25 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define MATERIAL_PARTICLES

#define MATERIAL_REFRACT_ENABLED
#define REFRACTION_STRENGTH 50 // [2 4 6 8 10 15 20 25 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define REFRACTION_BLUR
//#define REFRACTION_SNELL

#define MATERIAL_REFLECTIONS 2 // [0 1 2]
#define MATERIAL_REFLECT_STRENGTH 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define MATERIAL_REFLECT_CLOUDS
//#define MATERIAL_REFLECT_HIZ
//#define MATERIAL_REFLECT_GLASS
#define SSR_MAXSTEPS 64 // [16 24 32 40 48 64 80 96 112 128 160 192 224 256]
#define SSR_LOD_MAX 5 // [0 1 2 3 4 5]


// Shadow Options
#define SHADOW_TYPE 2 // [0 2 3]
//#define SHADOW_COLORED
//#define SHADOW_COLOR_BLEND
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
#define SHADOW_CLOUD_RADIUS 1.0 // [0.2 0.4 0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0 8.0]
#define SHADOW_CLOUD_BRIGHTNESS 30 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]


// Dynamic Lighting
#define DYN_LIGHT_MODE 0 // [0 1 2]
#define DYN_LIGHT_TYPE 0 // [0 1]
#define DYN_LIGHT_COLOR_MODE 0 // [0 1]
#define DYN_LIGHT_BRIGHTNESS 200 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 700 800 900]
#define DYN_LIGHT_AMBIENT 30 // [0 2 4 6 8 10 12 14 16 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_LIGHT_MIN 0.6 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define LIGHTING_TEMP 5600 // [3000 3200 3400 3600 3800 4000 4400 4800 5200 5600 6000 6400 6800 7200 7600 8000 8400 8800]
#define DYN_LIGHT_FLICKER
#define DYN_LIGHT_TINT_MODE 1 // [0 1 2]
#define DYN_LIGHT_TINT 100 // [0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define DYN_LIGHT_PENUMBRA 50 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define DYN_LIGHT_RES 1 // [2 1 0]
#define LIGHT_BIN_MAX_COUNT 128 // [16 32 48 64 96 128 160 192 224 256 320 384 448 512]
#define LIGHT_BIN_SIZE 8 // [4 8 16]
#define LIGHT_SIZE_XZ 32 // [4 8 16 32 64]
#define LIGHT_SIZE_Y 16 // [4 8 16 32]
#define DYN_LIGHT_RAY_QUALITY 2 // [1 2 4 8]
#define DYN_LIGHT_POPULATE_NEIGHBORS
//#define DYN_LIGHT_FRUSTUM_TEST
#define DYN_LIGHT_PLAYER_SHADOW 2 // [0 1 2]
#define DYN_LIGHT_FALLBACK
//#define DYN_LIGHT_WEATHER
//#define DYN_LIGHT_BLOCK_ENTITIES
#define DYN_LIGHT_SAMPLE_MAX 16 // [0 2 4 8 12 16 24 32 48 64 96 128]
#define DYN_LIGHT_BLUR
#define DYN_LIGHT_RANGE 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 180 200 220 240 260 280 300 350 400]
#define DYN_LIGHT_TA 85 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define LIGHT_HAND_SOFT_SHADOW

// Dynamic LPV
#define LPV_SIZE 0 // [0 1 2 3]
#define LPV_SAMPLE_MODE 2 // [0 1 2]
#define LPV_SUN_SAMPLES 0 // [0 1 2 3 4 5 6 7 8 9 12 15 18 21 25]
#define LPV_LIGHTMAP_MIX 20 // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 55 60 65 70 75 80 85 90 95 100]
#define LPV_BRIGHT_BLOCK 1 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
//#define LPV_RANGE 100 // [25 50 75 100 150 200 250 300 400 600 800 1200 1600]
#define LPV_BRIGHT_SUN 1.0
#define LPV_BRIGHT_MOON 0.02
#define LPV_FALLOFF 0.2 // [0.001]
#define LPV_SKYLIGHT_RANGE 256.0
#define LPV_GLASS_TINT
//#define LPV_GI
//#define LPV_VOXEL_TEST

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
#define VOLUMETRIC_SAMPLES 12 // [12 20 28 36]
#define VOLUMETRIC_DENSITY 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 175 200 250 300 400 600 800 1000]
#define VOLUMETRIC_RES 1 // [2 1 0]
#define VOLUMETRIC_BRIGHT_SKY   100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_BRIGHT_BLOCK 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_FILTER
//#define VOLUMETRIC_BLOCK_RT
//#define VOLUMETRIC_HANDLIGHT
#define VOLUMETRIC_SKY_DAY_DENSITY 30 // [0 10 20 30 40 50 60 70 80 90 100]


// Effects
#define EFFECT_BLOOM_ENABLED
#define EFFECT_BLOOM_STRENGTH 80 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
//#define EFFECT_BLOOM_THRESHOLD 1200 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300]
#define EFFECT_BLOOM_POWER 4 // [1 2 3 4 5 6 8 10 12 14 16 20 24]
#define EFFECT_BLOOM_HAND 20 // [0 10 20 30 40 50 60 70 80 90 100]
#define EFFECT_BLOOM_TILE_MAX 6

#define EFFECT_BLUR_TYPE 0 // [0 1 2]
#define EFFECT_BLUR_SAMPLE_COUNT 8 // [2 4 8 12 16 20 24 28 32]
#define EFFECT_BLUR_MAX_RADIUS 4 // [2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]
#define EFFECT_BLUR_FAR_POW 1.2
#define EFFECT_BLUR_DOF_FOCUS_SCALE 40 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define EFFECT_BLUR_BLINDNESS
#define EFFECT_BLUR_BLINDNESS_SCALE 6.0

#define EFFECT_SSAO_ENABLED
#define EFFECT_SSAO_SAMPLES 12 // [2 4 6 8 10 12 14 16 24 32]
#define EFFECT_SSAO_RADIUS 1.5 // [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define EFFECT_SSAO_STRENGTH 6 // [1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 24 28 32]
#define EFFECT_SSAO_MIN 0.0
#define EFFECT_SSAO_BIAS 0.04

#define EFFECT_AUTO_EXPOSE


// Post-Processing
#define POST_TONEMAP 4 // [0 1 2 3 4]
#define FXAA_ENABLED
#define POST_BRIGHTNESS 100 // [0 10 20 30 40 50 60 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define POST_SATURATION 100 // [0 10 20 30 40 50 60 70 75 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 125 130 140 150 160 170 180 190 200]
#define POST_CONTRAST 100 // [80 85 90 92 94 96 98 100 102 104 106 108 110 115 120]
#define GAMMA_OUT 2.2 // [1.0 1.2 1.4 1.6 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.8 3.0 3.2 3.4 3.6]
#define POST_WHITE_POINT 300 // [50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 700 800 900]
#define POST_EXPOSURE -0.6 // [-4.0 -3.0 -2.5 -2.0 -1.8 -1.6 -1.4 -1.2 -1.0 -0.8 -0.6 -0.4 -0.2 0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0 4.0]

// Debug Options
#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
//#define DYN_LIGHT_DEBUG_COUNTS
//#define DYN_LIGHT_OREBLOCKS
#define DEFER_TRANSLUCENT
//#define SHADOW_FORCE_CULLING
#define AF_SAMPLES 1
#define LIGHT_LEAK_FIX
//#define DH_COMPAT_ENABLED
//#define FORCE_DEFERRED
//#define ANIM_WORLD_TIME
//#define MAGNIFICENT_COLORS
//#define WATER_MULTIDEPTH_DEBUG
#define ALPHATESTREF_ENABLED


// INTERNAL SETTINGS
#define PHYSICS_OCEAN_SUPPORT
#define SHADOW_CSM_FIT_FARSCALE 1.1
#define SHADOW_CSM_FITSCALE 0.1
#define CSM_PLAYER_ID 0
#define ROUGH_MIN 0.06
#define REFLECTION_ROUGH_SCATTER 30
#define WHITEWORLD_VALUE 0.9
//#define TRANSLUCENT_SSS_ENABLED
#define DIRECTIONAL_LIGHTMAP
#define RIPPLE_STRENGTH 0.03
//#define HCM_LAZANYI

#define UINT32_MAX 4294967295u
#define PI 3.1415926538
#define TAU 6.2831853076
#define GOLDEN_ANGLE 2.39996323
#define IOR_AIR 1.00
#define IOR_WATER 1.33
#define EPSILON 1e-6
#define GAMMA 2.2

#define LIGHTING_TEMP_FIRE 2800
#define TEMP_FIRE_RANGE 1200 // [100 200 300 400 500 600]
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

#if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY || (defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE == CLOUDS_CUSTOM)
    #define VL_BUFFER_ENABLED
#endif

#if defined MATERIAL_REFRACT_ENABLED || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR) || defined VL_BUFFER_ENABLED || defined FORCE_DEFERRED
    #define DEFERRED_BUFFER_ENABLED
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #define RENDER_SHADOWS_ENABLED
#endif

#if defined SHADOW_CLOUD_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
    #define RENDER_CLOUD_SHADOWS_ENABLED
#endif


#ifdef ANIM_WORLD_TIME
#endif
#ifdef WORLD_WETNESS_ENABLED
#endif
#ifdef WORLD_AO_ENABLED
#endif
#ifdef WATER_CAUSTICS
#endif
#ifdef WATER_BLUR
#endif
#ifdef DIRECTIONAL_LIGHTMAP
#endif
#ifdef MATERIAL_PARALLAX_SHADOW_SMOOTH
#endif
#ifdef MATERIAL_PARALLAX_ENTITIES
#endif
#ifdef MATERIAL_REFLECT_CLOUDS
#endif
#ifdef REFRACTION_BLUR
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
#ifdef EFFECT_BLOOM_ENABLED
#endif
#ifdef EFFECT_SSAO_ENABLED
#endif
#ifdef DH_COMPAT_ENABLED
#endif
#ifdef WATER_MULTIDEPTH_DEBUG
#endif
#ifdef ALPHATESTREF_ENABLED
#endif


const vec3 HandLightOffsetL = vec3(-0.16, -0.24, -0.08);
const vec3 HandLightOffsetR = vec3( 0.16, -0.24, -0.08);

const float WorldMinLightF = WORLD_LIGHT_MIN * 0.01;
const float WorldSunBrightnessF = SKY_SUN_BRIGHTNESS * 0.01;
const float WorldMoonBrightnessF = SKY_MOON_BRIGHTNESS * 0.01;
const float WorldSkyBrightnessF = SKY_BRIGHTNESS * 0.01;
const float WorldWaterOpacityF = WATER_OPACITY * 0.01;
const float WorldRainOpacityF = SKY_WEATHER_OPACITY * 0.01;
//const float WorldSkyReflectF = WORLD_SKY_REFLECTIONS * 0.01;
const float WorldWaterDensityF = WATER_FOG_DENSITY * 0.01;
const float MaterialNormalStrengthF = MATERIAL_NORMAL_STRENGTH * 0.01;
const float MaterialNormalRoundF = MATERIAL_NORMAL_ROUND * 0.01;
const float MaterialEmissionF = MATERIAL_EMISSION_BRIGHTNESS * 0.01;
const float MaterialMetalBrightnessF = METAL_BRIGHTNESS * 0.01;
const float MaterialReflectionStrength = MATERIAL_REFLECT_STRENGTH * 0.01;
const float MaterialPorosityDarkenF = MATERIAL_POROSITY_DARKEN * 0.01;
const float MaterialScatterF = MATERIAL_SSS_SCATTER * 0.01;
const float MaterialSssBoostF = MATERIAL_SSS_BOOST * 0.01;
const float ParallaxDepthF = MATERIAL_PARALLAX_DEPTH * 0.01;
const float ParallaxSharpThreshold = (MATERIAL_PARALLAX_SHARP_THRESHOLD+0.5) / 255.0;
const float VolumetricDensityF = VOLUMETRIC_DENSITY * 0.01;
const float VolumetricBlockRangeF = VOLUMETRIC_BLOCK_RANGE * 0.01;
const float VolumetricBrightnessSky = VOLUMETRIC_BRIGHT_SKY * 0.01;
const float VolumetricBrightnessBlock = VOLUMETRIC_BRIGHT_BLOCK * 0.01;
const float VolumetricSkyDayDensityF = VOLUMETRIC_SKY_DAY_DENSITY * 0.01;
const float DynamicLightAmbientF = DYN_LIGHT_AMBIENT * 0.01;
const float DynamicLightTintF = DYN_LIGHT_TINT * 0.01;
const float DynamicLightPenumbraF = DYN_LIGHT_PENUMBRA * 0.01;
const float DynamicLightBrightness = DYN_LIGHT_BRIGHTNESS * 0.01;
const float DynamicLightTemporalStrength = DYN_LIGHT_TA * 0.01;
const float DynamicLightRangeF = DYN_LIGHT_RANGE * 0.01;
const float LpvLightmapMixF = LPV_LIGHTMAP_MIX * 0.01;
const float LpvBlockLightF = exp2(LPV_BRIGHT_BLOCK - 1);
//const float LpvRangeF = LPV_RANGE * 0.01;
const float ShadowMinPcfSize = SHADOW_PCF_SIZE_MIN * 0.01;
const float ShadowMaxPcfSize = SHADOW_PCF_SIZE_MAX * 0.01;
const float ShadowCloudBrightnessF = SHADOW_CLOUD_BRIGHTNESS * 0.01;
const float RefractionStrengthF = REFRACTION_STRENGTH * 0.01;
const float ReflectionRoughScatterF = REFLECTION_ROUGH_SCATTER * 0.01;
const float DepthOfFieldFocusScale = EFFECT_BLUR_DOF_FOCUS_SCALE * 0.01;
const float PostBrightnessF = POST_BRIGHTNESS * 0.01;
const float PostSaturationF = POST_SATURATION * 0.01;
const float PostContrastF = POST_CONTRAST * 0.01;
const float PostBloomStrengthF = EFFECT_BLOOM_STRENGTH * 0.01;
//const float PostBloomThresholdF = EFFECT_BLOOM_THRESHOLD * 0.01;
const float Bloom_HandStrength = EFFECT_BLOOM_HAND * 0.01;
const float PostWhitePoint = POST_WHITE_POINT * 0.01;

const float invPI = 1.0 / PI;
const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);
const float uint32MaxInv = 1.0 / UINT32_MAX;
const vec2 EPSILON2 = vec2(EPSILON);
const vec3 EPSILON3 = vec3(EPSILON);
const float phaseIso = 1.0 / (4.0 * PI);

const float centerDepthHalflife = 1.2;
const float wetnessHalflife = 16000.0;
const float drynessHalflife = 20.0;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    const float ShadowNormalBias = (SHADOW_CASCADED_NORMAL_BIAS * SHADOW_BIAS_SCALE);
#else
    const float ShadowNormalBias = (SHADOW_DISTORTED_NORMAL_BIAS * SHADOW_BIAS_SCALE);
#endif

const float shadowDistance = 100; // [25 50 75 100 125 150 200 250 300 400 600 800]
const float shadowIntervalSize = 2.0f;
const float shadowDistanceRenderMul = 1.0;
const int shadowMapResolution = 1536; // [128 256 512 768 1024 1536 2048 3072 4096 6144 8192]

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

//const float entityShadowDistanceMul = 0.25;
const float voxelDistance = 128.0;

//const mat4 TEXTURE_MATRIX_2 = mat4(vec4(0.00390625, 0.0, 0.0, 0.0), vec4(0.0, 0.00390625, 0.0, 0.0), vec4(0.0, 0.0, 0.00390625, 0.0), vec4(0.03125, 0.03125, 0.03125, 1.0));

#if MC_VERSION < 11700 || !defined ALPHATESTREF_ENABLED
    const float alphaTestRef = 0.1;
#endif


#define rcp(x) (1.0 / (x))

#define _pow2(x) (x*x)
#define _pow3(x) (x*x*x)

#define _lengthSq(x) dot((x), (x))

#define modelPart(x, y, z) (vec3(x, y, z)/16.0)

float pow2(const in float x) {return x*x;}
vec3 pow2(const in vec3 x) {return x*x;}
uint pow3(const in uint x) {return x*x*x;}
float pow3(const in float x) {return x*x*x;}
vec2  pow3(const in vec2  x) {return x*x*x;}
float pow4(const in float x) {float x2 = _pow2(x); return _pow2(x2);}
float pow5(const in float x) {return x * pow4(x);}
float pow6(const in float x) {float x2 = _pow2(x); return _pow3(x2);}

float saturate(const in float x) {return clamp(x, 0.0, 1.0);}
vec2 saturate(const in vec2 x) {return clamp(x, 0.0, 1.0);}
vec3 saturate(const in vec3 x) {return clamp(x, 0.0, 1.0);}
vec4 saturate(const in vec4 x) {return clamp(x, 0.0, 1.0);}

float length2(const in vec2 vec) {return dot(vec, vec);}
float length2(const in vec3 vec) {return dot(vec, vec);}

float minOf(const in vec2 vec) {return min(vec[0], vec[1]);}
float minOf(const in vec3 vec) {return min(min(vec[0], vec[1]), vec[2]);}
float minOf(const in vec4 vec) {return min(min(vec[0], vec[1]), min(vec[2], vec[3]));}

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}
float maxOf(const in vec3 vec) {return max(max(vec[0], vec[1]), vec[2]);}

int sumOf(ivec2 vec) {return vec.x + vec.y;}
int sumOf(ivec3 vec) {return vec.x + vec.y + vec.z;}

float RGBToLinear(const in float value) {
    return pow(value, GAMMA);
}

vec3 RGBToLinear(const in vec3 color) {
	return pow(color, vec3(GAMMA));
}

vec3 RGBToLinear(const in vec3 color, const in float gamma) {
    return pow(color, vec3(gamma));
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

float smootherstep(const in float x) {
    return _pow3(x) * (x * (6.0 * x - 15.0) + 10.0);
}

void fixNaNs(inout vec3 vec) {
    if (isnan(vec.x) || isinf(vec.x)) vec.x = EPSILON;
    if (isnan(vec.y) || isinf(vec.y)) vec.y = EPSILON;
    if (isnan(vec.z) || isinf(vec.z)) vec.z = EPSILON;
}
