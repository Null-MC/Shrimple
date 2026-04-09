#define PI 3.1415926538
#define EPSILON 1e-6
#define UINT_MAX 0xFFFFFFFFu
#define USHORT_MAX 0xFFFFu

#define BLOCK_SOLID 1
#define BLOCK_PHYMOD_SNOW 829925

#define MAT_NONE 0
#define MAT_HAND 1
#define MAT_WATER 2
#define MAT_STAINED_GLASS 3

#define BLOCK_OUTLINE_NONE 0
#define BLOCK_OUTLINE_SOLID 1
#define BLOCK_OUTLINE_CONSTRUCTION 2

#define SKY_VANILLA 0
#define SKY_ENHANCED 1

#define FORMAT_DEFAULT 0
#define FORMAT_LABPBR 2
#define FORMAT_OLDPBR 1

#define PARALLAX_DEFAULT 0
#define PARALLAX_SHARP 1
#define PARALLAX_SMOOTH 2

#define LIGHTING_MODE_VANILLA 0
#define LIGHTING_MODE_ENHANCED 1

#define TEX_FINAL colortex0
#define IMG_FINAL colorimg0
#define TEX_TRANSLUCENT_FINAL colortex1
#define TEX_TRANSLUCENT_TINT colortex2
#define TEX_VELOCITY colortex3

#define TEX_GB_COLOR colortex4
#define TEX_GB_NORMALS colortex5
#define TEX_GB_SPECULAR colortex6

//#define TEX_ALBEDO_SPECULAR colortex3
//#define TEX_NORMAL colortex4
#define TEX_SSAO colortex7
//#define TEX_META colortex8

#define TEX_BLOOM_TILES texBloomTiles
#define IMG_BLOOM_TILES imgBloomTiles

#define DEBUG_VIEW_NONE 0
#define DEBUG_VIEW_SSAO 1
#define DEBUG_VIEW_IRRADIANCE 2
#define DEBUG_VIEW_BLOOM 3

const float Water_f0 = 0.02;
const int WaterNormalResolution = 256;
const float WaterNormalScale = 1.0;

const vec3 luma_factor = vec3(0.2126, 0.7152, 0.0722);
const float GoldenAngle = PI * (3.0 - sqrt(5.0));
const float PHI = (1.0 + sqrt(5.0)) / 2.0;

const float dh_clipDistF = 0.85;

const float vxNearPlane = 16.0;
const float vxFarPlane = 16*3000;
