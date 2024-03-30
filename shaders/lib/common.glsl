const float sunPathRotation = -20; // [-60 -55 -50 -45 -40 -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50 55 60]

/*
const int shadowcolor0Format = RGBA8;

const int colortex0Format  = RGB16F;
const int colortex1Format  = RGBA8;
const int colortex2Format  = RGBA8;
const int colortex3Format  = RGBA32UI;
const int colortex4Format  = RGB16F;
const int colortex5Format  = RGBA16F;
const int colortex6Format  = R32F;
const int colortex7Format  = RGBA16F;
const int colortex8Format = RGB16F;
const int colortex9Format = RGB8;
const int colortex10Format = RGB16F;
const int colortex11Format = RGBA16F;
const int colortex12Format = RGB16F;
const int colortex15Format = RGBA16F;
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

const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex5Clear = false;

const vec4 colortex6ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex6Clear = false;

const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex7Clear = true;

const vec4 colortex8ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex8Clear = true;

const vec4 colortex9ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex9Clear = true;

const vec4 colortex10ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
const bool colortex10Clear = true;

const vec4 colortex11ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex11Clear = false;

const vec4 colortex12ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const bool colortex12Clear = false;

const vec4 colortex15ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex15Clear = true;


// Sky Options
#define SKY_TYPE 1 // [0 1]
#define SKY_SUN_BRIGHTNESS 400  // [10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]
#define SKY_MOON_BRIGHTNESS 10 // [1 2 4 6 8 10 12 14 16 18 20 25 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define SKY_BRIGHTNESS 400  // [10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 800]
#define SKY_WEATHER_OPACITY 60 // [0 2 4 6 8 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define SKY_WEATHER_CLOUD_ONLY

// Sky Cloud Options
#define SKY_CLOUD_TYPE 1 // [0 1 2 3]
#define SKY_CLOUD_SPEED 24 // [0 2 4 8 12 16 20 24 32 48 64 96 128]
#define SKY_CLOUD_COVER_MIN 10 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define SKY_CLOUD_ALTITUDE 280 // [0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 750 800 850 900 950 1000 1100 1200]
#define SKY_CLOUD_HEIGHT 512 // [128 256 512 768 1024]

// Sky Fog Options
#define SKY_VOL_FOG_TYPE 2 // [0 1 2]
#define SKY_FOG_DENSITY 6 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0 3.5 4.0 4.5 5 6 7 8 9 10 12 14 16 18 20 24 28 32 36 40 48 56 62 70]
#define SKY_CAVE_FOG_ENABLED
#define SKY_CAVE_FOG_DENSITY 32 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0 3.5 4.0 4.5 5 6 7 8 9 10 12 14 16 18 20 24 28 32 36 40 48 56 62 70]
#define SKY_BORDER_FOG_ENABLED
#define SKY_FOG_SHAPE 0 // [0 1 2]


// World Options
#define WORLD_WIND_STRENGTH 8 // [0 2 4 6 8 10 12 14 16 18 20]
//#define WORLD_AMBIENT_MODE 1 // [0 1 2]
//#define WORLD_AO_ENABLED
//#define WORLD_SKY_REFLECTIONS 100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WORLD_WETNESS_ENABLED
#define WORLD_WETNESS_PUDDLES 3 // [0 1 2 3 4]
#define WORLD_NETHER_AMBIENT 10 // [0 1 2 3 4 5 6 8 10 15 20 25 30 35 40 50]
#define WORLD_END_AMBIENT 10 // [0 1 2 3 4 5 6 8 10 15 20 25 30 35 40 50]
#define WORLD_CURVE_RADIUS 0 // [1 2 3 4 6 8 10 12 16 20 24 28 32 40 60 80 120 160 200 400 800 1200 1600 2400 3200 0]
// #define WORLD_CURVE_SHADOWS
#define WORLD_NETHER_SMOKE
#define WORLD_END_SMOKE
//#define WORLD_SMOKE


// Water Options
//#define WATER_TEXTURED
#define WATER_COLOR_TYPE 0 // [0 1 2 3]
//#define WATER_OPACITY 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WATER_SURFACE_PIXEL_RES 0 // [0 8 16 32 64 128]
#define WATER_VOL_FOG_TYPE 2 // [0 1 2]
#define WATER_FOG_DENSITY 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 500 600]
#define WATER_TESSELLATION_QUALITY 0 // [0 4 8 12 16 20 24 28 32]
#define WATER_WAVE_SIZE 2 // [0 1 2 3]
#define WATER_WAVE_DETAIL 20 // [10 12 14 16 18 20 24 28 32 36 40 44 48]
#define WATER_WAVE_DETAIL_VERTEX 12
// #define WATER_WAVE_SHARP 50 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define WATER_DEPTH_LAYERS 1 // [1 2 3 4 5 6]
#define WATER_WAVE_MIN 0.1
#define WATER_REFLECTIONS
#define WATER_DISPLACEMENT
#define WATER_CAUSTICS


// Material Options
#define MATERIAL_PARTICLES

#define MATERIAL_REFRACT_ENABLED
#define REFRACTION_STRENGTH 100 // [2 4 6 8 10 15 20 25 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define REFRACTION_BLUR
//#define REFRACTION_SNELL

#define MATERIAL_REFLECTIONS 2 // [0 1 2]
#define MATERIAL_REFLECT_STRENGTH 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define REFLECTION_ROUGH_SCATTER
//#define MATERIAL_REFLECT_CLOUDS
//#define MATERIAL_REFLECT_HIZ
//#define MATERIAL_REFLECT_GLASS
#define SSR_MAXSTEPS 32 // [16 24 32 40 48 64 80 96 112 128 160 192 224 256]
#define SSR_LOD_MAX 5 // [0 1 2 3 4 5]

#define DISPLACE_MODE 0 // [0 1 2 3 4]
#define MATERIAL_PARALLAX_SAMPLES 32 // [16 24 32 48 64 96 128]
#define MATERIAL_PARALLAX_SHADOW_SAMPLES 0 // [0 16 24 32 48 64 96 128]
//#define MATERIAL_PARALLAX_SHADOW_SMOOTH
#define MATERIAL_DISPLACE_DEPTH 25 // [5 10 15 20 25 30 40 50 60 70 80 90 100]
#define MATERIAL_DISPLACE_OFFSET 100 // [0 25 50 75 100]
#define MATERIAL_DISPLACE_MAX_DIST 30 // [10 20 30 40 50 60 70 80]
#define MATERIAL_PARALLAX_SHARP_THRESHOLD 1 // [1 2 3 4 6 8 12 16 20 24 28]
//#define MATERIAL_PARALLAX_DEPTH_WRITE
#define MATERIAL_TESSELLATION_QUALITY 24 // [4 6 8 12 16 20 24 28 32 40 48 56 64]
#define MATERIAL_TESSELLATION_EDGE_FADE
#define MATERIAL_DISPLACE_ENTITIES

#define MATERIAL_NORMALS 1 // [0 1 2 3]
#define MATERIAL_NORMAL_SCALE 2 // [1 2 4 8 16]
#define MATERIAL_NORMAL_STRENGTH 100 // [50 100 150 200 250 300 350 400 500 600 700 800]
#define MATERIAL_NORMAL_ROUND 40 // [0 10 20 30 40 50 60 70 80 90 100]
#define MATERIAL_NORMAL_EDGE 0 // [0 1 2]

#define MATERIAL_SPECULAR 1 // [0 1 2 3]
#define METAL_BRIGHTNESS 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define MATERIAL_HCM_ALBEDO_TINT

#define MATERIAL_EMISSION 0 // [0 1 2]
#define MATERIAL_EMISSION_BRIGHTNESS 500 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 350 400 450 500 550 600 650 700 750 800 950 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000 4500 5000 5500 6000 6500 7000 7500 8000]

#define MATERIAL_POROSITY 1 // [0 1 2]
#define MATERIAL_POROSITY_DARKEN 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300]

#define MATERIAL_SSS 1 // [0 1 2]
#define MATERIAL_SSS_MAXDIST 4.5 // [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0]
#define MATERIAL_SSS_SCATTER 0.8 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0]
#define MATERIAL_SSS_STRENGTH 300 // [100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 420 440 460 480 500]

#define MATERIAL_OCCLUSION 1 // [0 1 2]


// Shadow Options
#define SHADOW_ENABLED
#define SHADOW_TYPE 2 // [2 3]
//#define SHADOW_COLORED
//#define SHADOW_COLOR_BLEND
#define SHADOW_BIAS_SCALE 100 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 750 800]
#define SHADOW_DISTORT_FACTOR 80 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100]
#define SHADOW_FILTER 2 // [0 1 2]
#define SHADOW_PCF_SIZE_MIN 1.0 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.5 4.0 4.5 5.0 5.5 6.0]
#define SHADOW_PCF_SIZE_MAX 40 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 35 40 45 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 250 300 350 400]
#define SHADOW_PCF_SAMPLES 6 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_PCSS_SAMPLES 4 // [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
#define SHADOW_BLUR_SIZE 1 // [0 1 2]
#define SHADOW_ENABLE_HWCOMP
#define SHADOW_SCREEN
#define SHADOW_SCREEN_STEPS 12 // [4 8 12 16 20 24 28 32]

#define SHADOW_PENUMBRA_SCALE 0.08
#define SHADOW_DISTORTED_NORMAL_BIAS 0.02
#define SHADOW_CASCADED_NORMAL_BIAS 0.02
//#define SHADOW_FRUSTUM_CULL
#define SHADOW_CSM_FITRANGE
#define SHADOW_CSM_OVERLAP

#define SHADOW_CLOUD_ENABLED
#define SHADOW_CLOUD_RADIUS 1.0 // [0.2 0.4 0.6 0.8 1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0 8.0]
#define SHADOW_CLOUD_BRIGHTNESS 30 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]


// Lighting
#define LIGHTING_MODE 1 // [0 1 2 3]
#define LIGHTING_MODE_HAND 1 // [0 1 2]
#define LIGHTING_BRIGHTNESS 200 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 650 700 750 800]
#define LIGHTING_AMBIENT 50 // [0 2 4 6 8 10 12 14 16 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define LIGHTING_MIN 0.6 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0]
#define LIGHTING_RANGE 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 210 220 230 240 250 260 270 280 290 300]
#define LIGHTING_FLICKER
#define LIGHTING_TINT_MODE 1 // [0 1 2]
#define LIGHTING_TINT_STRENGTH 100 // [0 20 40 60 80 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
//#define LIGHTING_COLORED_CANDLES

// LightMap Lighting
#define LIGHTING_TEMP 5600 // [3000 3200 3400 3600 3800 4000 4400 4800 5200 5600 6000 6400 6800 7200 7600 8000 8400 8800]
#define DIRECTIONAL_LIGHTMAP
//#define LIGHTING_OLD

// Traced Lighting
#define LIGHTING_TRACE_RES 1 // [2 1 0]
#define LIGHTING_TRACE_PENUMBRA 0 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define LIGHTING_TRACE_SAMPLE_MAX 0 // [0 2 4 8 12 16 24 32 48 64 96 128]
#define LIGHTING_TRACED_PLAYER_SHADOW 2 // [0 1 2]
#define LIGHTING_TRACE_FILTER 1 // [0 1 2]
#define LIGHT_BIN_MAX_COUNT 128 // [16 32 48 64 96 128 160 192 224 256 320 384 448 512]
#define LIGHT_BIN_SIZE 8 // [4 8 16]
#define LIGHT_SIZE_XZ 32 // [4 8 16 32 64]
#define LIGHT_SIZE_Y 16 // [4 8 16 32]
//#define LIGHT_HAND_SOFT_SHADOW
//#define DYN_LIGHT_FRUSTUM_TEST
//#define DYN_LIGHT_BLOCK_ENTITIES
//#define DYN_LIGHT_WEATHER

// Dynamic LPV
#define LPV_SIZE 0 // [0 1 2 3]
#define LPV_SKYLIGHT 0 // [0 1 2]
#define LPV_SAMPLE_MODE 1 // [0 1 2]
#define LPV_SHADOW_SAMPLES 6 // [1 2 3 4 5 6 7 8 9 12 15 18 21 25]
#define LPV_LIGHTMAP_MIX 20 // [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 55 60 65 70 75 80 85 90 95 100]
#define LPV_SKYLIGHT_RANGE 32.0 // [16 24 32]
#define LPV_BLOCKLIGHT_SCALE 32.0 // [16 24 32 48 64 96 128]
#define LPV_FRUSTUM_OFFSET 30 // [0 5 10 15 20 25 30 35 40 45 50]
//#define LPV_BLEND_ALT
#define LPV_GLASS_TINT
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
#define VOLUMETRIC_SAMPLES 24 // [12 24 36 48 60 72 84 96]
//#define VOLUMETRIC_DENSITY 100 // [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 175 200 250 300 400 600 800 1000]
#define VOLUMETRIC_RES 2 // [2 1 0]
#define VOLUMETRIC_BRIGHT_SKY   100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_BRIGHT_BLOCK 100 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define VOLUMETRIC_BLUR_SIZE 1 // [0 1 2]
//#define VOLUMETRIC_BLOCK_RT
//#define VOLUMETRIC_HANDLIGHT
#define VOLUMETRIC_SKY_DAY_DENSITY 30 // [0 10 20 30 40 50 60 70 80 90 100]


// Effects
//#define EFFECT_AUTO_EXPOSE

#define EFFECT_BLOOM_ENABLED
#define EFFECT_BLOOM_STRENGTH 60 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define EFFECT_BLOOM_POWER 6.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0]
#define EFFECT_BLOOM_HAND 20 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define EFFECT_BLOOM_TILE_MAX 6

#define EFFECT_BLUR_ENABLED
#define EFFECT_BLUR_SAMPLE_COUNT 8 // [2 4 8 12 16 20 24 28 32]
#define EFFECT_BLUR_DOF_FOCUS_SCALE 40 // [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200]
#define EFFECT_BLUR_MAX_RADIUS 2 // [0 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]
#define EFFECT_BLUR_WATER_RADIUS 20 // [0 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]
#define EFFECT_BLUR_RADIUS_WEATHER 8 // [0 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]
#define EFFECT_BLUR_RADIUS_BLIND 128 // [0 64 128 256]
#define EFFECT_BLUR_ABERRATION_ENABLED
#define EFFECT_BLUR_ABERRATION_STRENGTH 100 // [20 40 60 80 100 120 140 160 180 200 220 240 260 280 300]

#define EFFECT_SSAO_ENABLED
#define EFFECT_SSAO_SAMPLES 12 // [2 4 6 8 10 12 14 16 24 32]
#define EFFECT_SSAO_RADIUS 1.5 // [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define EFFECT_SSAO_STRENGTH 6 // [1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 24 28 32]
#define EFFECT_SSAO_MIN 0.0
#define EFFECT_SSAO_BIAS 0.04

#define EFFECT_TAA_ENABLED
#define EFFECT_TAA_MAX_ACCUM 16 // [4 6 8 10 12 16 20 24 28 32 48 64]
#define EFFECT_TAA_SHARPEN

//#define EFFECT_FXAA_ENABLED
#define EFFECT_FXAA_ITERATIONS 12 // [4 8 12 16 20 24]


// Post-Processing
#define POST_TONEMAP 2 // [0 1 2 3 4]
#define POST_BRIGHTNESS 100 // [0 10 20 30 40 50 60 70 75 80 85 90 95 100 105 110 115 120 125 130 140 150 160 170 180 190 200 220 240 260 280 300]
#define POST_SATURATION 100 // [0 10 20 30 40 50 60 70 75 80 82 84 86 88 90 92 94 96 98 100 102 104 106 108 110 112 114 116 118 120 125 130 140 150 160 170 180 190 200]
#define POST_CONTRAST 100 // [80 85 90 92 94 96 98 100 102 104 106 108 110 115 120]
#define POST_TEMP 78 // [10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100 120 140 160 180 200 220 240 260 280 300 320 340 360 380 400]
#define GAMMA_OUT 2.2 // [0.6 0.8 1.0 1.2 1.4 1.6 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.8 3.0 3.4 3.8 4.2 4.6 5.0 6.0 7.0 8.0]
#define POST_WHITE_POINT 300 // [50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 240 260 280 300 320 340 360 380 400 450 500 550 600 700 800 900]
#define POST_EXPOSURE -1.4 // [-6.0 -5.5 -5.0 -4.5 -4.0 -3.5 -3.0 -2.8 -2.6 -2.4 -2.2 -2.0 -1.8 -1.6 -1.4 -1.2 -1.0 -0.8 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]


// Debug Options
#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17]
//#define DEBUG_TRANSPARENT
#define DH_CLIP_DIST 70 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define DH_TRANSITION
//#define DYN_LIGHT_DEBUG_COUNTS
//#define DYN_LIGHT_OREBLOCKS
#define DEFER_TRANSLUCENT
//#define SHADOW_FORCE_CULLING
#define AF_SAMPLES 1
#define LIGHT_LEAK_FIX
//#define ANIM_WORLD_TIME
//#define MAGNIFICENT_COLORS
//#define WATER_MULTIDEPTH_DEBUG
//#define ALPHATESTREF_ENABLED


// INTERNAL SETTINGS
#define LIGHT_COLOR_MESSAGE 0 // [0]
#define PHYSICS_OCEAN_SUPPORT
#define SHADOW_CSM_FIT_FARSCALE 1.1
#define SHADOW_CSM_FITSCALE 0.1
#define CSM_PLAYER_ID 0
#define ROUGH_MIN 0.06
#define WATER_ROUGH 0.0
#define MIP_BIAS 0.25 // [1.0 0.5 0.25]
#define WHITEWORLD_VALUE 0.6
//#define TRANSLUCENT_SSS_ENABLED
//#define DEFERRED_PARTICLES
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

#define LIGHTING_TEMP_FIRE 2600
#define TEMP_FIRE_RANGE 600 // [100 200 300 400 500 600]
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

#ifdef WORLD_NETHER
    const float WorldAmbientF = WORLD_NETHER_AMBIENT * 0.01;
#elif defined WORLD_END
    const float WorldAmbientF = WORLD_END_AMBIENT * 0.01;
#else
    const float WorldAmbientF = 0.0;
#endif

#if DISPLACE_MODE == DISPLACE_POM || DISPLACE_MODE == DISPLACE_POM_SMOOTH || DISPLACE_MODE == DISPLACE_POM_SHARP
    #define PARALLAX_ENABLED
#endif

#if WATER_TESSELLATION_QUALITY > 0 && WATER_WAVE_SIZE > 0 && defined IRIS_FEATURE_SSBO
	#define WATER_TESSELLATION_ENABLED
#endif

#if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY || (defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA)
    #define VL_BUFFER_ENABLED
#endif

#if defined WORLD_SHADOW_ENABLED && defined SHADOW_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    #define RENDER_SHADOWS_ENABLED
#endif

#if defined MATERIAL_REFRACT_ENABLED || (defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED) || (defined RENDER_SHADOWS_ENABLED && SHADOW_BLUR_SIZE > 0) || defined VL_BUFFER_ENABLED
    #define DEFERRED_BUFFER_ENABLED
#endif

#if defined SHADOW_CLOUD_ENABLED && defined WORLD_SHADOW_ENABLED && defined WORLD_SKY_ENABLED //&& SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
    #define RENDER_CLOUD_SHADOWS_ENABLED
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0
    #define IS_LPV_ENABLED
#endif

#if defined IS_LPV_ENABLED && LPV_SKYLIGHT != LPV_SKYLIGHT_NONE
    #define IS_LPV_SKYLIGHT_ENABLED
#endif

#if defined IRIS_FEATURE_SSBO && (LIGHTING_MODE == LIGHTING_MODE_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED)
    #define IS_TRACING_ENABLED
#endif

#if (defined WORLD_END_SMOKE && defined WORLD_END) || (defined WORLD_NETHER_SMOKE && defined WORLD_NETHER)
	#define IS_WORLD_SMOKE_ENABLED
#endif


#ifdef ANIM_WORLD_TIME
#endif
#ifdef WORLD_WETNESS_ENABLED
#endif
#ifdef WORLD_AO_ENABLED
#endif
#ifdef WORLD_NETHER_SMOKE
#endif
#ifdef WORLD_END_SMOKE
#endif
#ifdef WATER_CAUSTICS
#endif
#ifdef DIRECTIONAL_LIGHTMAP
#endif
#ifdef LIGHTING_OLD
#endif
#ifdef MATERIAL_PARALLAX_SHADOW_SMOOTH
#endif
#ifdef MATERIAL_DISPLACE_ENTITIES
#endif
#ifdef MATERIAL_REFLECT_CLOUDS
#endif
#ifdef REFRACTION_BLUR
#endif
#ifdef SHADOW_COLORED
#endif
#ifdef SHADOW_COLOR_BLEND
#endif
#ifdef SHADOW_SCREEN
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
#ifdef WATER_MULTIDEPTH_DEBUG
#endif
#ifdef ALPHATESTREF_ENABLED
#endif
#ifdef DEBUG_TRANSPARENT
#endif


const vec3 HandLightOffsetL = vec3(-0.16, -0.24, -0.08);
const vec3 HandLightOffsetR = vec3( 0.16, -0.24, -0.08);

const float WorldMinLightF = LIGHTING_MIN * 0.01;
const float WorldSunBrightnessF = SKY_SUN_BRIGHTNESS * 0.01;
const float WorldMoonBrightnessF = SKY_MOON_BRIGHTNESS * 0.01;
const float WorldSkyBrightnessF = SKY_BRIGHTNESS * 0.01;
const float WorldRainOpacityF = SKY_WEATHER_OPACITY * 0.01;
const float WorldWaterDensityF = WATER_FOG_DENSITY * 0.01;
const float WorldCurveRadius = WORLD_CURVE_RADIUS * 1000.0;
const float MaterialNormalStrengthF = MATERIAL_NORMAL_STRENGTH * 0.01;
const float MaterialNormalRoundF = MATERIAL_NORMAL_ROUND * 0.01;
const float MaterialEmissionF = MATERIAL_EMISSION_BRIGHTNESS * 0.01;
const float MaterialMetalBrightnessF = METAL_BRIGHTNESS * 0.01;
const float MaterialReflectionStrength = MATERIAL_REFLECT_STRENGTH * 0.01;
const float MaterialTessellationOffset = MATERIAL_DISPLACE_OFFSET * 0.01;
const float MaterialPorosityDarkenF = MATERIAL_POROSITY_DARKEN * 0.01;
const float MaterialSssStrengthF = MATERIAL_SSS_STRENGTH * 0.01;
const float ParallaxDepthF = MATERIAL_DISPLACE_DEPTH * 0.01;
const float ParallaxSharpThreshold = (MATERIAL_PARALLAX_SHARP_THRESHOLD+0.5) / 255.0;
const float VolumetricBlockRangeF = VOLUMETRIC_BLOCK_RANGE * 0.01;
const float VolumetricBrightnessSky = VOLUMETRIC_BRIGHT_SKY * 0.01;
const float VolumetricBrightnessBlock = VOLUMETRIC_BRIGHT_BLOCK * 0.01;
const float VolumetricSkyDayDensityF = VOLUMETRIC_SKY_DAY_DENSITY * 0.01;
const float DynamicLightAmbientF = LIGHTING_AMBIENT * 0.01;
const float DynamicLightTintF = LIGHTING_TINT_STRENGTH * 0.01;
const float DynamicLightPenumbraF = LIGHTING_TRACE_PENUMBRA * 0.01;
const float DynamicLightBrightness = LIGHTING_BRIGHTNESS * 0.01;
const float DynamicLightRangeF = LIGHTING_RANGE * 0.01;
const float LpvLightmapMixF = LPV_LIGHTMAP_MIX * 0.01;
// const float LpvBlockLightF = exp2(LPV_BRIGHT_BLOCK - 1);
const float ShadowMinPcfSize = SHADOW_PCF_SIZE_MIN * 0.01;
const float ShadowMaxPcfSize = SHADOW_PCF_SIZE_MAX * 0.01;
const float ShadowBiasScale = SHADOW_BIAS_SCALE * 0.01;
const float ShadowDistortF = 1.0 - SHADOW_DISTORT_FACTOR * 0.01;
const float ShadowCloudBrightnessF = SHADOW_CLOUD_BRIGHTNESS * 0.01;
const float RefractionStrengthF = REFRACTION_STRENGTH * 0.01;
const float DepthOfFieldFocusScale = EFFECT_BLUR_DOF_FOCUS_SCALE * 0.01;
const float PostBrightnessF = POST_BRIGHTNESS * 0.01;
const float PostSaturationF = POST_SATURATION * 0.01;
const float PostContrastF = POST_CONTRAST * 0.01;
const float PostBloomStrengthF = EFFECT_BLOOM_STRENGTH * 0.01;
const float Bloom_HandStrength = EFFECT_BLOOM_HAND * 0.01;
const float PostWhitePoint = POST_WHITE_POINT * 0.01;
const float dh_clipDistF = DH_CLIP_DIST * 0.01;

const float WorldWaterOpacityF = 0.02;
const float ShadowScreenSlope = 0.85;

const float invPI = 1.0 / PI;
const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);
const float uint32MaxInv = 1.0 / UINT32_MAX;
//const float GAMMA_INV = 1.0 / GAMMA;
const vec2 EPSILON2 = vec2(EPSILON);
const vec3 EPSILON3 = vec3(EPSILON);
const float phaseIso = 1.0 / (4.0 * PI);

const float centerDepthHalflife = 1.2;
const float wetnessHalflife = 16000.0;
const float drynessHalflife = 20.0;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    const float ShadowNormalBias = SHADOW_CASCADED_NORMAL_BIAS * ShadowBiasScale;
#else
    const float ShadowNormalBias = SHADOW_DISTORTED_NORMAL_BIAS * ShadowBiasScale;
#endif

const float shadowDistance = 100; // [25 50 75 100 125 150 200 250 300 350 400 450 500 600 700 800 900 1000 1200 1400 1600 1800 2000 2200 2400 2600 2800 3000 3200 3400 3600 3800 4000]
const float shadowIntervalSize = 2.0f;
const float shadowDistanceRenderMul = -1.0;
const int shadowMapResolution = 1024; // [128 256 512 768 1024 1536 2048 3072 4096 6144 8192]

const float shadowNearPlane = -1.0;
//const float shadowFarPlane = -1.0;

#ifdef MC_SHADOW_QUALITY
    const float shadowMapSize = shadowMapResolution * MC_SHADOW_QUALITY;
#else
    const float shadowMapSize = shadowMapResolution;
#endif

const float shadowPixelSize = 1.0 / shadowMapSize;

#ifdef SHADOW_ENABLE_HWCOMP
    const bool shadowHardwareFiltering = true;
#endif

const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;
const bool shadowcolor0Nearest = false;

//const float entityShadowDistanceMul = 0.25;

#if LPV_SIZE == 3
	const float voxelDistance = 64.0;
#elif LPV_SIZE == 2
	const float voxelDistance = 32.0;
#elif LPV_SIZE == 1
	const float voxelDistance = 16.0;
#else
	const float voxelDistance = 0.0;
#endif

//const mat4 TEXTURE_MATRIX_2 = mat4(vec4(0.00390625, 0.0, 0.0, 0.0), vec4(0.0, 0.00390625, 0.0, 0.0), vec4(0.0, 0.0, 0.00390625, 0.0), vec4(0.03125, 0.03125, 0.03125, 1.0));

#if MC_VERSION < 11700 || !defined ALPHATESTREF_ENABLED
    const float alphaTestRef = 0.1;
#endif



#define _pow2(x) (x*x)
#define _pow3(x) (x*x*x)

#define _lengthSq(x) dot((x), (x))

#define rcp(x) (1.0 / (x))
#define _smoothstep(x) smoothstep(0.0, 1.0, (x))
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
float sumOf(vec3 vec) {return vec.x + vec.y + vec.z;}

#define _RGBToLinear(color) (pow((color), vec3(GAMMA)))

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

vec3 unproject(const in mat4 matProj, const in vec3 pos) {
    return unproject(matProj * vec4(pos, 1.0));
}

float expStep(const in float x) {
    return 1.0 - exp(-x*x);
}

uint half2float(const in uint h) {
    return ((h & uint(0x8000)) << 16u) | (((h & uint(0x7c00)) + uint(0x1c000)) << 13u) | ((h & uint(0x03ff)) << 13u);
}

uvec3 half2float(const in uvec3 h) {
    return ((h & uint(0x8000)) << 16u) | (((h & uint(0x7c00)) + uint(0x1c000)) << 13u) | ((h & uint(0x03ff)) << 13u);
}

uint float2half(const in uint f) {
    return ((f >> 16u) & uint(0x8000)) |
        ((((f & uint(0x7f800000)) - uint(0x38000000)) >> 13u) & uint(0x7c00)) |
        ((f >> 13u) & uint(0x03ff));
}

uvec3 float2half(const in uvec3 f) {
    return ((f >> 16u) & uint(0x8000)) |
        ((((f & uint(0x7f800000)) - uint(0x38000000)) >> 13u) & uint(0x7c00)) |
        ((f >> 13u) & uint(0x03ff));
}

// float _smoothstep(const in float x) {return smoothstep(0.0, 1.0, x);}

float smootherstep(const in float x) {
    return _pow3(x) * (x * (6.0 * x - 15.0) + 10.0);
}

vec3 mul3(const in mat4 matrix, const in vec3 vector) {
	return mat3(matrix) * vector + matrix[3].xyz;
}
