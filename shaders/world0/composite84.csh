#version 430 compatibility

#define BLOOM_TILE 3
#define TEX_DEST TEX_BLOOM_TILES
#define IMG_DEST IMG_BLOOM_TILES

#include "overworld.glsl"
#include "/program/composite_bloom-up.csh"
