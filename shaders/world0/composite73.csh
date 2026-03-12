#version 430 compatibility

#define BLOOM_TILE 3
#define TEX_SOURCE TEX_BLOOM_TILES

#include "overworld.glsl"
#include "/program/composite_bloom-down.csh"
