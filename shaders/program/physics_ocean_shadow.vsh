#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    out VertexData {
        vec3 localPos;
    } vOut;
#endif

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform float far;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferProjection;
    uniform float near;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
    #include "/lib/world/curvature.glsl"
#endif

#include "/lib/physics_mod/ocean.glsl"


void main() {
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vec3 localPos = mul3(shadowModelViewInverse, viewPos);

    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        vOut.localPos = localPos;
    #endif

    float viewDist = length(localPos);
    float distF = 1.0 - smoothstep(0.2, 2.8, viewDist);
    distF = 1.0 - _pow2(distF);

    #ifdef DISTANT_HORIZONS
        float viewDistXZ = length(localPos.xz);
        float waterClipFar = dh_clipDistF*far;
        distF *= 1.0 - smoothstep(0.8*waterClipFar, waterClipFar, viewDistXZ);
    #endif

    float physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;
    localPos.y += distF * physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime);

    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            mat4 shadowModelViewEx = shadowModelView;
        #endif

        #if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
            localPos = GetWorldCurvedPosition(localPos);
        #endif

        gl_Position = vec4(mul3(shadowModelViewEx, localPos), 1.0);
    #endif
}
