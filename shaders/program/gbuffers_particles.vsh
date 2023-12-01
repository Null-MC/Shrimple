#define RENDER_PARTICLES
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef MATERIAL_PARTICLES
    in vec4 at_tangent;
    in vec4 mc_midTexCoord;
#endif

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
// out vec3 vBlockLight;
out vec3 vLocalPos;
out vec3 vLocalNormal;

#ifdef MATERIAL_PARTICLES
    out vec2 vLocalCoord;
    out vec3 vLocalTangent;
    out float vTangentW;

    flat out mat2 atlasBounds;
#endif

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

uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

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
        uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
        uniform vec3 eyePosition;
    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

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

#ifdef MATERIAL_PARTICLES
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/utility/tbn.glsl"

    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/lighting/common.glsl"


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    
    lmcoord = LightMapNorm(lmcoord);

    BasicVertex();

    #ifdef MATERIAL_PARTICLES
        PrepareNormalMap();

        GetAtlasBounds(atlasBounds, vLocalCoord);
    #endif
}
