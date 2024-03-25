#define RENDER_WEATHER
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
	vec4 color;
	vec2 lmcoord;
	vec2 texcoord;
	vec3 localPos;

	// #ifdef RENDER_CLOUD_SHADOWS_ENABLED
	//     vec3 cloudPos;
	// #endif

	#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
		#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
			vec3 shadowPos[4];
			flat int shadowTile;
		#else
			vec3 shadowPos;
		#endif
	#endif
} vOut;

uniform sampler2D lightmap;
uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

uniform float cloudHeight;
uniform float skyRainStrength;
uniform ivec2 eyeBrightnessSmooth;

#ifdef SKY_WEATHER_CLOUD_ONLY
	uniform int worldTime;
	uniform int frameCounter;
	uniform int fogShape;

    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	uniform float far;

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		uniform mat4 gbufferProjection;
		uniform float near;
	#endif

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform vec3 eyePosition;
    #endif
#endif

#ifdef DISTANT_HORIZONS
	uniform float dhFarPlane;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/blocks.glsl"

#include "/lib/sampling/noise.glsl"

#include "/lib/utility/lightmap.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
	#include "/lib/shadows/common.glsl"

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
	#elif SHADOW_TYPE != SHADOW_TYPE_NONE
		#include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
	#endif
#endif

#include "/lib/clouds/cloud_vars.glsl"

#if defined SKY_WEATHER_CLOUD_ONLY && SKY_CLOUD_TYPE > CLOUDS_VANILLA
	#include "/lib/lighting/hg.glsl"
	#include "/lib/lighting/scatter_transmit.glsl"

	#include "/lib/world/atmosphere.glsl"
	#include "/lib/fog/fog_common.glsl"
	#include "/lib/clouds/cloud_custom.glsl"
#endif

#include "/lib/lighting/common.glsl"


void main() {
	if (SKY_WEATHER_OPACITY == 0) {
		gl_Position = vec4(-1.0);
		return;
	}

    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 viewPos = BasicVertex();
    gl_Position = gl_ProjectionMatrix * viewPos;


    #if SKY_CLOUD_TYPE != CLOUDS_NONE
        #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            const float CloudHeight = 4.0;
        #endif

        vec3 worldPos = cameraPosition + vOut.localPos;

	    float cloudAlt = GetCloudAltitude();
        float cloudY = smoothstep(0.0, CloudHeight * 0.5, worldPos.y - cloudAlt);
        vOut.color.a *= 1.0 - cloudY;

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA && defined SKY_WEATHER_CLOUD_ONLY
            const vec3 worldUp = vec3(0.0, 1.0, 0.0);
            float cloudDensity = TraceCloudDensity(worldPos, worldUp, CLOUD_GROUND_SHADOW_STEPS);
            vOut.color.a *= smoothstep(0.0, 0.5, cloudDensity);
        #endif
    #endif
}
