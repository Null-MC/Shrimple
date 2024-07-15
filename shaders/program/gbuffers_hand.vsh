#define RENDER_HAND
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_midTexCoord;
in vec4 at_tangent;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;
    
    #ifdef EFFECT_TAA_ENABLED
        vec3 velocity;
    #endif

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    #if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    		vec3 shadowPos[4];
    		flat int shadowTile;
    	#else
    		vec3 shadowPos;
    	#endif
    #endif
} vOut;

uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform ivec2 atlasSize;

#ifdef WORLD_SHADOW_ENABLED
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	uniform float far;

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		attribute vec3 at_midBlock;

		uniform mat4 gbufferProjection;
		uniform float near;
	#endif

    #if SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform mat4 gbufferPreviousModelView;
    uniform vec3 previousCameraPosition;
    uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    // #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/utility/lightmap.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    #include "/lib/utility/tbn.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif

	#include "/lib/shadows/common.glsl"

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		#include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
	#else
		#include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
	#endif
#endif

#include "/lib/material/normalmap.glsl"
#include "/lib/vertex_common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 viewPos = BasicVertex();

    PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    #ifdef PARALLAX_ENABLED
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

        vOut.viewPos_T = viewPos.xyz * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            vOut.lightPos_T = shadowLightPosition * matViewTBN;
        #endif
    #endif

    #ifdef EFFECT_TAA_ENABLED
        vOut.velocity = vec3(0.0);

        // mat4 gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView);
        // vec3 localPosPrev = (gbufferPreviousModelViewInverse * viewPos).xyz;
        // vOut.velocity += vOut.localPos - localPosPrev;

        vOut.velocity += cameraPosition - previousCameraPosition;
    #endif

    #if DISPLACE_MODE != DISPLACE_TESSELATION
        gl_Position = gl_ProjectionMatrix * viewPos;

        #ifdef EFFECT_TAA_ENABLED
            jitter(gl_Position);
        #endif
    #else
        gl_Position = viewPos;
    #endif
}
