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

    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
        float waveHeight;
    #endif

    #if defined(MATERIAL_PBR_ENABLED) || defined(WATER_WAVE_ENABLED)
        flat uint localTangent;
        flat float localTangentW;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec3 tangentViewPos;
        flat uint atlasTilePos;
        flat uint atlasTileSize;
    #endif

//    #if defined(MATERIAL_PBR_ENABLED) || defined(REFLECT_ENABLED)
    #ifdef RENDER_TERRAIN
        flat int blockId;
    #endif

    #if defined(VELOCITY_ENABLED) && defined(RENDER_TERRAIN)
        vec3 velocity;
    #endif
} vOut;


#if defined(RENDER_TERRAIN) && defined(WIND_ENABLED)
    uniform usampler2D texBlockWaving;
#endif

uniform float far;
uniform float windTime;
uniform float windTimeLast;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform vec2 taa_offset = vec2(0.0);


#include "/lib/blocks.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/tbn.glsl"

#ifdef MATERIAL_PARALLAX_ENABLED
    #include "/lib/sampling/atlas.glsl"
#endif

#ifdef RENDER_TERRAIN
    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
        #include "/lib/water-waves.glsl"
    #endif

    #ifdef WIND_ENABLED
        #include "/lib/hash-noise.glsl"
        #include "/lib/wind-waving.glsl"
    #endif
#endif

#ifdef LIGHTING_HAND
    #include "/lib/lighting/hand.glsl"
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
        vec3 velocity = vec3(0.0);

        #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
            if (vOut.blockId == BLOCK_WATER) {
                vec2 waterWorldPos = (vOut.localPos.xz + cameraPosition.xz) / WaterNormalScale;
                float waveHeight = wave_fbm(waterWorldPos, 8);

                float viewDist = length(viewPos);
                float waveFadeF = smoothstep(0.0, 2.0, viewDist);
                #if defined(DISTANT_HORIZONS) || defined(VOXY)
                    waveFadeF *= smoothstep(dh_clipDistF * far, 0.8 * dh_clipDistF * far, viewDist);
                #endif
                vOut.waveHeight = (waveHeight*0.5 - 0.4) * waveFadeF;
                vOut.localPos.y += vOut.waveHeight;
            }
        #endif

        #ifdef WIND_ENABLED
            if (vOut.blockId > 0 && vOut.blockId < 256*256) {
            #ifdef VELOCITY_ENABLED
                vec3 windOffset = GetWindWavingOffset(vOut.localPos, at_midBlock.xyz / 64.0, vOut.blockId, velocity, windTime, windTimeLast);
            #else
                vec3 windOffset = GetWindWavingOffset(vOut.localPos, at_midBlock.xyz / 64.0, vOut.blockId, windTime);
            #endif

            vOut.localPos += windOffset;
            }
        #endif

        #if defined(WATER_WAVE_ENABLED) || defined(WIND_ENABLED)
            viewPos = mul3(gbufferModelView, vOut.localPos);
        #endif

        #ifdef VELOCITY_ENABLED
            vOut.velocity = velocity;
        #endif
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

    #if defined(MATERIAL_PBR_ENABLED) || defined(WATER_WAVE_ENABLED)
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vec3 localTangent = mat3(gbufferModelViewInverse) * viewTangent;
        vOut.localTangent = packUnorm2x16(OctEncode(localTangent));
        vOut.localTangentW = at_tangent.w;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec2 atlasTilePos, atlasTileSize;
        GetAtlasBounds(vOut.texcoord, atlasTilePos, atlasTileSize);
        vOut.atlasTilePos = packHalf2x16(atlasTilePos);
        vOut.atlasTileSize = packHalf2x16(atlasTileSize);

        mat3 matViewTBN = BuildTBN(viewNormal, viewTangent, at_tangent.w);

        vOut.tangentViewPos = viewPos.xyz * matViewTBN;
    #endif
}
