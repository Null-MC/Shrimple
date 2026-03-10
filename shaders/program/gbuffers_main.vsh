#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in vec4 at_tangent;
in vec4 at_midBlock;
in vec4 mc_midTexCoord;
in vec4 mc_Entity;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;

    #ifdef RENDER_ENTITY
        vec3 localNormal;
    #else
        flat uint localNormal;
    #endif

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        flat float chunkFade;
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        flat uint localTangent;
        flat float localTangentW;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec3 tangentViewPos;
        flat uint atlasTilePos;
        flat uint atlasTileSize;
    #endif

//    #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
    #ifdef RENDER_TERRAIN
        flat int blockId;
    #endif
} vOut;


#if defined(WIND_ENABLED) && defined(RENDER_TERRAIN)
    uniform usampler2D texBlockWaving;
#endif

uniform float windTime;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform vec3 cameraPosition;
uniform vec2 taa_offset = vec2(0.0);


#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/tbn.glsl"

#ifdef MATERIAL_PARALLAX_ENABLED
    #include "/lib/sampling/atlas.glsl"
#endif

#if defined(WIND_ENABLED) && defined(RENDER_TERRAIN)
    #include "/lib/hash-noise.glsl"
    #include "/lib/wind-waving.glsl"
#endif

#ifdef LIGHTING_HAND
    #include "/lib/hand-light.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vOut.color = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    #ifdef RENDER_ENTITY
        vOut.localNormal = localNormal;
    #else
        vOut.localNormal = packUnorm2x16(OctEncode(localNormal));
    #endif

    #if defined(RENDER_TERRAIN) && defined(IRIS_FEATURE_FADE_VARIABLE)
        vOut.chunkFade = saturate(mc_chunkFade);
        if (mc_chunkFade < 0.0) vOut.chunkFade = 1.0;
    #endif

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #ifdef RENDER_TERRAIN
        vOut.blockId = int(mc_Entity.x + EPSILON);
    #endif

    #if defined(WIND_ENABLED) && defined(RENDER_TERRAIN)
        vec3 originPos = vOut.localPos + at_midBlock.xyz / 64.0;
        vOut.localPos += GetWindWavingOffset(originPos, vOut.blockId);

        viewPos = mul3(gbufferModelView, vOut.localPos);
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef TAA_ENABLED
        gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
    #endif

    #if defined(LIGHTING_HAND) && LIGHTING_MODE == LIGHTING_MODE_VANILLA && !defined(LIGHTING_COLORED)
        float handDist = GetHandDistance(vOut.localPos);

        float handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
        float handLight = max(handLightLevel - handDist, 0.0) / 15.0;
        vOut.lmcoord.x = max(vOut.lmcoord.x, handLight);
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vec3 localTangent = mat3(gbufferModelViewInverse) * viewTangent;
        vOut.localTangent = packUnorm2x16(OctEncode(localTangent));
        vOut.localTangentW = at_tangent.w;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec2 atlasTilePos, atlasTileSize;
        GetAtlasBounds(vOut.texcoord, atlasTilePos, atlasTileSize);
        vOut.atlasTilePos = packUnorm2x16(atlasTilePos);
        vOut.atlasTileSize = packUnorm2x16(atlasTileSize);

        mat3 matViewTBN = BuildTBN(viewNormal, viewTangent, at_tangent.w);

        vOut.tangentViewPos = viewPos.xyz * matViewTBN;
    #endif
}
