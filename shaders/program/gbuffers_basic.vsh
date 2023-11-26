#define RENDER_BASIC
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 lmcoord;
out vec2 texcoord;
flat out vec4 glcolor;
out vec3 vLocalPos;

#ifdef RENDER_CLOUD_SHADOWS_ENABLED
    out vec3 cloudPos;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        out vec3 shadowPos[4];
        flat out int shadowTile;
    #else
        out vec3 shadowPos;
    #endif
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform vec3 cameraPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #if SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
        uniform vec3 eyePosition;
    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vLocalPos = (gbufferModelViewInverse * viewPos).xyz;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            shadowTile = -1;
        #endif

        vec3 localNormal = normalize(gl_NormalMatrix * gl_Normal);
        localNormal = mat3(gbufferModelViewInverse) * localNormal;

        const float geoNoL = 1.0;
        ApplyShadows(vLocalPos, localNormal, geoNoL);
    #endif
}
