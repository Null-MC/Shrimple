#define RENDER_TERRAIN
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out float vLit;

#ifdef WORLD_SHADOW_ENABLED
	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		out vec3 shadowPos[4];
		flat out int shadowTile;
		flat out vec3 shadowTileColor;

		#ifndef IRIS_FEATURE_SSBO
			flat out vec2 shadowProjectionSize[4];
			flat out float cascadeSize[4];
		#endif
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		out vec3 shadowPos;
	#endif
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
	out vec3 vBlockLight;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef WORLD_SHADOW_ENABLED
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	uniform float far;

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		uniform mat4 gbufferProjection;
		uniform float near;
	#endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/waving.glsl"

#ifdef WORLD_SHADOW_ENABLED
	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded.glsl"
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		#include "/lib/shadows/basic.glsl"
	#endif
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
	#include "/lib/buffers/lighting.glsl"
	#include "/lib/lighting/dynamic.glsl"
	#include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/lighting/basic.glsl"


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	BasicVertex();
}
