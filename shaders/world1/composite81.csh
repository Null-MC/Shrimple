#version 430 compatibility

#define BLOOM_TILE 6
#define TEX_DEST TEX_BLOOM_TILES
#define IMG_DEST IMG_BLOOM_TILES

#include "end.glsl"
#include "/program/composite_bloom-up.csh"
