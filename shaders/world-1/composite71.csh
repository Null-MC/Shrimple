#version 430 compatibility

#define BLOOM_TILE 1
#define TEX_SOURCE TEX_BLOOM_TILES

#include "nether.glsl"
#include "/program/composite_bloom-down.csh"
