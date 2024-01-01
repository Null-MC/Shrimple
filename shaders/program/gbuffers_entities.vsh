#define RENDER_ENTITIES
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;
in vec4 mc_midTexCoord;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

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

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform ivec2 atlasSize;

uniform int entityId;
uniform vec4 entityColor;

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
    #endif
#endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 pixelSize;
    uniform int frameCounter;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/items.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/utility/lightmap.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    #include "/lib/utility/tbn.glsl"
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

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE
    #include "/lib/entities.glsl"

    #include "/lib/lighting/voxel/entities.glsl"
#endif

#include "/lib/material/normalmap.glsl"
#include "/lib/lighting/common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);
    
    vec4 viewPos = BasicVertex();
    gl_Position = gl_ProjectionMatrix * viewPos;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

        //viewPos = (gbufferModelView * vec4(vOut.localPos, 1.0)).xyz;
        vOut.viewPos_T = viewPos.xyz * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            vOut.lightPos_T = shadowLightPosition * matViewTBN;
        #endif
    #endif
}
