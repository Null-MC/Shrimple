#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef DISTANT_HORIZONS
        float viewPosZ;
    #endif
} vOut;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 taa_offset;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/sampling/noise.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.color = gl_Color;

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    // TODO: scale?
    // vOut.localPos;

    #if WORLD_CURVE_RADIUS > 0
        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, vOut.localPos);
        #else
            vec3 localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, localPos);
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        vOut.viewPosZ = -viewPos.z;
    #endif

    vec3 viewNormal = gl_NormalMatrix * gl_Normal;
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
