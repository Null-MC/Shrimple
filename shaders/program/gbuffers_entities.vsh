#define RENDER_ENTITIES
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out float vLit;
out vec3 vBlockLight;

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || HAND_LIGHT_MODE == HAND_LIGHT_PIXEL
    out vec3 vLocalPos;
    out vec3 vLocalNormal;
#endif

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

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
    flat out int vBlockId;
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX || HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
	uniform sampler2D noisetex;
#endif

uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int entityId;

#ifdef WORLD_SHADOW_ENABLED
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	uniform float far;

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		attribute vec3 at_midBlock;

		uniform mat4 gbufferProjection;
		uniform int entityId;
		uniform float near;
	#endif
#endif

#if HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded.glsl"
	#else
		#include "/lib/shadows/basic.glsl"
	#endif
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE || HAND_LIGHT_MODE != HAND_LIGHT_NONE
    #include "/lib/blocks.glsl"
    #include "/lib/entities.glsl"
    #include "/lib/items.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX || HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
	#include "/lib/buffers/lighting.glsl"
	#include "/lib/lighting/dynamic.glsl"
#endif

#if HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
    #include "/lib/lighting/blackbody.glsl"
	#include "/lib/lighting/dynamic_blocks.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE || HAND_LIGHT_MODE != HAND_LIGHT_NONE
	#include "/lib/lighting/dynamic_entities.glsl"
#endif

#include "/lib/lighting/basic.glsl"


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	
	BasicVertex();
}
