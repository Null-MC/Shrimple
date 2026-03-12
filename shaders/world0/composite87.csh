#version 430 compatibility

#define BLOOM_TILE 0
#define TEX_DEST TEX_FINAL
#define IMG_DEST IMG_FINAL

#include "overworld.glsl"
#include "/program/composite_bloom-up.csh"
