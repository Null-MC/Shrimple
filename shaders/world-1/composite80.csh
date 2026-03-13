#version 430 compatibility

#define BLOOM_TILE 7
#define TEX_DEST TEX_BLOOM_TILES
#define IMG_DEST IMG_BLOOM_TILES

#include "nether.glsl"
#include "/program/composite_bloom-up.csh"
