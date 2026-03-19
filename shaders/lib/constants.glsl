#define PI 3.1415926538
#define EPSILON 1e-6
#define UINT_MAX 0xFFFFFFFFu
#define USHORT_MAX 0xFFFFu

#define BLOCK_SOLID 1
#define BLOCK_PHYMOD_SNOW 829925

#define BLOCK_OUTLINE_NONE 0
#define BLOCK_OUTLINE_SOLID 1
#define BLOCK_OUTLINE_CONSTRUCTION 2

#define SKY_VANILLA 0
#define SKY_ENHANCED 1

#define MAT_DEFAULT 0
#define MAT_LABPBR 2
#define MAT_OLDPBR 1

#define PARALLAX_DEFAULT 0
#define PARALLAX_SHARP 1
#define PARALLAX_SMOOTH 2

#define LIGHTING_MODE_VANILLA 0
#define LIGHTING_MODE_ENHANCED 1

#define TEX_FINAL colortex0
#define IMG_FINAL colorimg0
#define TEX_TRANSLUCENT_FINAL colortex1
#define TEX_TRANSLUCENT_TINT colortex2
#define TEX_ALBEDO_SPECULAR colortex3
#define TEX_NORMAL colortex4
#define TEX_SSAO colortex5
#define TEX_VELOCITY colortex6
#define TEX_WATER_NORMAL colortex7
#define IMG_WATER_NORMAL colorimg7

#define TEX_BLOOM_TILES texBloomTiles
#define IMG_BLOOM_TILES imgBloomTiles

#define DEBUG_VIEW_NONE 0
#define DEBUG_VIEW_SSAO 1
#define DEBUG_VIEW_IRRADIANCE 2
#define DEBUG_VIEW_BLOOM 3

const int WaterNormalResolution = 512;
const float WaterNormalScale = 32.0;

const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);
const float GoldenAngle = PI * (3.0 - sqrt(5.0));
const float PHI = (1.0 + sqrt(5.0)) / 2.0;

const float vxNearPlane = 16.0;
const float vxFarPlane = 16*3000;
