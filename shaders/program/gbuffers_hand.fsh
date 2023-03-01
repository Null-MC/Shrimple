#define RENDER_HAND
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vPos;
in vec3 vNormal;
in float geoNoL;
in float vLit;

#if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
    in vec3 vBlockLight;
#elif DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
    flat in int vBlockId;
#endif

#ifdef WORLD_SHADOW_ENABLED
	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		in vec3 shadowPos[4];
		flat in int shadowTile;
		flat in vec3 shadowTileColor;

		#ifndef IRIS_FEATURE_SSBO
			flat in vec2 shadowProjectionSize[4];
			flat in float cascadeSize[4];
		#endif
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		in vec3 shadowPos;
	#endif
#endif

uniform sampler2D gtexture;

uniform float far;

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
	uniform float alphaTestRef;
#endif

#ifndef SHADOW_BLUR
    #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
        uniform sampler2D texLightMap;
    #else
        uniform sampler2D lightmap;
    #endif

	uniform vec3 upPosition;
	uniform vec3 skyColor;
	//uniform float far;
	
	uniform vec3 fogColor;
	uniform float fogDensity;
	uniform float fogStart;
	uniform float fogEnd;
	uniform int fogShape;
	uniform int fogMode;
	
    uniform float blindness;
#endif 

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
	uniform sampler2D noisetex;

	uniform float frameTimeCounter;
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 cameraPosition;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

#ifdef WORLD_SHADOW_ENABLED
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
	
	uniform vec3 shadowLightPosition;
	
	#if SHADOW_TYPE != SHADOW_TYPE_NONE
		uniform mat4 shadowProjection;
	#endif
#endif

#include "/lib/sampling/noise.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/sampling/ign.glsl"
    #include "/lib/buffers/shadow.glsl"

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded.glsl"
		#include "/lib/shadows/cascaded_render.glsl"
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		#include "/lib/shadows/basic.glsl"
		#include "/lib/shadows/basic_render.glsl"
	#endif
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
    #include "/lib/blocks.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
    //#include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor0;
#ifdef SHADOW_BLUR
	layout(location = 1) out vec4 outColor1;
	layout(location = 2) out vec4 outColor2;
#endif

void main() {
	vec4 color = GetColor();

	#if SHADOW_COLORS == SHADOW_COLOR_ENABLED
		vec3 lightColor = GetFinalShadowColor();
	#else
		vec3 lightColor = vec3(GetFinalShadowFactor());
	#endif

	#ifdef SHADOW_BLUR
		outColor0 = color;
		outColor1 = vec4(lightColor, 1.0);
		outColor2 = vec4(lmcoord, glcolor.a, 1.0);
	#else
		outColor0 = GetFinalLighting(color, lightColor, vPos, lmcoord, glcolor.a);
	#endif
}
