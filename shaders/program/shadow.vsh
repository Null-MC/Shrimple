#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

out VertexData {
    vec4 color;
    vec2 texcoord;
    float viewDist;

    flat int blockId;
    flat vec3 originPos;
} vOut;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int renderStage;
uniform float far;

uniform int blockEntityId;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferProjection;
    uniform float near;
#endif

#include "/lib/blocks.glsl"
#include "/lib/utility/anim.glsl"

#include "/lib/utility/lightmap.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    //#include "/lib/buffers/shadow.glsl"
#endif

#if WORLD_WIND_STRENGTH > 0
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/world/waving.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #if WATER_WAVE_SIZE > 0
        #include "/lib/world/water_waves.glsl"
    #endif
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.color = gl_Color;

    bool isRenderTerrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
                        || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

    int blockId = int(mc_Entity.x + 0.5);
    if (blockId <= 0) blockId = BLOCK_SOLID;

    #ifndef SHADOW_COLORED
        if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && blockId != BLOCK_WATER) {
            gl_Position = vec4(-1.0);
            return;
        }
    #endif

    vec3 geoViewNormal = normalize(gl_NormalMatrix * gl_Normal);

    if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES) {
        blockId = blockEntityId;

        if (blockId == 0xFFFF)
            blockId = BLOCK_EMPTY;
    }

    vec4 pos = gl_Vertex;
    vOut.originPos = pos.xyz;
    if ((blockId < BLOCK_LIGHT_1 || blockId > BLOCK_LIGHT_15) && isRenderTerrain) {
        vOut.originPos += at_midBlock / 64.0;
    }

    vOut.originPos = mul3(gl_ModelViewMatrix, vOut.originPos);

    if (!isRenderTerrain) {
        vOut.originPos -= 0.05 * geoViewNormal;
    }

    // #ifdef SHADOW_FRUSTUM_CULL
    //     if (isRenderTerrain && blockId > 0) {
    //         if (clamp(vOut.originPos.xy, shadowViewBoundsMin, shadowViewBoundsMax) != vOut.originPos.xy) {
    //             gl_Position = vec4(-1.0);
    //             return;
    //         }
    //     }
    // #endif

    vOut.originPos = mul3(shadowModelViewInverse, vOut.originPos);

    if (renderStage == MC_RENDER_STAGE_ENTITIES)
        blockId = BLOCK_EMPTY;

    vOut.blockId = blockId;

    vec3 viewPos = mul3(gl_ModelViewMatrix, pos.xyz);
    vec3 localPos = mul3(shadowModelViewInverse, viewPos);
    vOut.viewDist = length(localPos);

    #if WORLD_WIND_STRENGTH > 0
        ApplyWavingOffset(localPos, localPos, blockId);
    #endif

    #if defined WORLD_WATER_ENABLED && defined WATER_DISPLACEMENT && WATER_WAVE_SIZE > 0
        if ((renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT && blockId == BLOCK_WATER) || (isRenderTerrain && vOut.blockId == BLOCK_LILY_PAD)) {
            //float viewDist = length(localPos);
            float distF = 1.0 - smoothstep(0.2, 2.8, vOut.viewDist);
            distF = 1.0 - _pow2(distF);

            if (vOut.blockId == BLOCK_WATER) {
                // reduce wave strength lower surface is
                // prevent waving if connected to above water
                float vertexY = saturate(-at_midBlock.y/64.0 + 0.5);
                distF *= vertexY * step(vertexY, (15.5/16.0));
            }

            #ifdef DISTANT_HORIZONS
                float viewDistXZ = length(localPos.xz);
                float waterClipFar = dh_clipDistF*far;
                distF *= 1.0 - smoothstep(0.8*waterClipFar, waterClipFar, viewDistXZ);
            #endif

            #if WATER_WAVE_SIZE > 0
                vec2 lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

                float time = GetAnimationFactor();
                float skyLight = 1.0;//LightMapNorm(lmcoord).y;

                if (vOut.blockId == BLOCK_LILY_PAD) {
                    vec3 originPos = localPos + at_midBlock/64.0;
                    vec3 waveOffset = GetWaveHeight(cameraPosition + originPos, lmcoord.y, time, WATER_WAVE_DETAIL_VERTEX);
                    localPos.xz += distF * waveOffset.xz;
                    localPos.y -= (1.0/16.0);
                }

                vec3 waveOffset = GetWaveHeight(cameraPosition + localPos, skyLight, time, WATER_WAVE_DETAIL_VERTEX);
                localPos.y += distF * waveOffset.y;
            #endif
        }
    #endif

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
