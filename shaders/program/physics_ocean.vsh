#define RENDER_OCEAN
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

    vec3 physics_localPosition;
    float physics_localWaviness;

    vec3 viewPos_T;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        vec3 lightPos_T;
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

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float far;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

uniform int isEyeInWater;

#ifdef WORLD_SKY_ENABLED
    uniform float rainStrength;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

// #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
//     uniform mat4 gbufferPreviousModelView;
// #endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/atlas.glsl"

#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/tbn.glsl"

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

#include "/lib/physics_mod/ocean.glsl"

#include "/lib/lighting/common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    float viewDist = length(viewPos);

    float distF = 1.0 - smoothstep(0.2, 2.8, viewDist);
    distF = 1.0 - _pow2(distF);

    #ifdef DISTANT_HORIZONS
        float waterClipFar = dh_clipDistF*far;
        distF *= 1.0 - smoothstep(0.6*waterClipFar, waterClipFar, viewDist);
    #endif

    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    vOut.physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

    vec4 vertexPos = gl_Vertex;
    #ifdef WATER_DISPLACEMENT
        vertexPos.y += distF * physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, vOut.physics_localWaviness, physics_gameTime);
    #endif

    vOut.physics_localPosition = vertexPos.xyz;

    viewPos = mul3(gl_ModelViewMatrix, vertexPos.xyz);

    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #if WORLD_CURVE_RADIUS > 0
        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, vOut.localPos);
        #else
            vec3 worldPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, worldPos);
        #endif
    #endif

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    #if defined RENDER_SHADOWS_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vOut.shadowTile = -1;
        #endif

        #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED
            vec3 skyLightDir = normalize(shadowLightPosition);
            float geoNoL = dot(skyLightDir, viewNormal);
        #else
            float geoNoL = 1.0;
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
                ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
            #else
                ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
            #endif
        #else
            vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
        #endif
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    // PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    // vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
    mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

    vOut.viewPos_T = viewPos * matViewTBN;

    #ifdef WORLD_SHADOW_ENABLED
        vOut.lightPos_T = shadowLightPosition * matViewTBN;
    #endif
}
