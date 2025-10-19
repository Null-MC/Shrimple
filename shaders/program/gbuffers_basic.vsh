#define RENDER_BASIC
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vOut;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 taa_offset;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = gbufferProjection * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    // vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    // vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    // #ifdef RENDER_SHADOWS_ENABLED
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         vOut.shadowTile = -1;
    //     #endif

    //     vec3 localNormal = normalize(gl_NormalMatrix * gl_Normal);
    //     localNormal = mat3(gbufferModelViewInverse) * localNormal;

    //     const float geoNoL = 1.0;
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         ApplyShadows(vOut.localPos, localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
    //     #else
    //         vOut.shadowPos = ApplyShadows(vOut.localPos, localNormal, geoNoL);
    //     #endif
    // #endif
}
