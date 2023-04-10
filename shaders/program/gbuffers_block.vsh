#define RENDER_BLOCK
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    in vec4 mc_midTexCoord;
#endif

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out float vLit;
out vec3 vBlockLight;
out vec3 vLocalPos;
out vec3 vLocalNormal;
flat out int vBlockId;

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
	in vec4 at_tangent;

	out vec3 vLocalTangent;
	out float vTangentW;
#endif

#if MATERIAL_PARALLAX != PARALLAX_NONE
    out vec2 vLocalCoord;
    out vec3 tanViewPos;
	flat out mat2 atlasBounds;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        out vec3 tanLightPos;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		out vec3 shadowPos[4];
		flat out int shadowTile;
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		out vec3 shadowPos;
	#endif
#endif

uniform sampler2D lightmap;
uniform sampler2D noisetex;

uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/tbn.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/world/waving.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
	#include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
	#include "/lib/shadows/common.glsl"

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded.glsl"
	#else
		#include "/lib/shadows/basic.glsl"
	#endif
#endif

#if defined IRIS_FEATURE_SSBO
	#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
		#include "/lib/buffers/lighting.glsl"
		#include "/lib/lighting/dynamic.glsl"
	#endif

	#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
		#include "/lib/lighting/dynamic_lights.glsl"
		//#include "/lib/lighting/dynamic_blocks.glsl"
	    #include "/lib/lighting/dynamic_items.glsl"
	#endif
#endif

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/lighting/sampling.glsl"
#include "/lib/lighting/basic.glsl"


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	BasicVertex();

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        PrepareNormalMap();
    #endif

    #if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
        vTangentW = at_tangent.w;
    #endif

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
        vec2 coordNMid = texcoord - coordMid;

        atlasBounds[0] = min(texcoord, coordMid - coordNMid);
        atlasBounds[1] = abs(coordNMid) * 2.0;

        vLocalCoord = sign(coordNMid) * 0.5 + 0.5;

        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent);

        tanViewPos = vPos * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            tanLightPos = shadowLightPosition * matViewTBN;
        #endif
    #endif
}
