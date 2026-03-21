#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in vec4 mc_Entity;
in vec4 at_midBlock;

#if defined(SHADOWS_ENABLED) && (!defined(RENDER_SOLID) || defined(SHADOW_COLORED))
    out vec2 texcoord;

    #ifdef SHADOW_COLORED
        out vec4 color;
        flat out int blockId;
    #endif
#endif

#ifdef LIGHTING_COLORED
    layout(r16ui) uniform writeonly uimage3D imgVoxels;

    uniform sampler2D texBlockLight;
#endif

#ifdef WIND_ENABLED
    uniform usampler2D texBlockWaving;
#endif

#ifdef WATER_WAVE_ENABLED
    uniform sampler2D texWaterHeight;
#endif

uniform int renderStage;
uniform int entityId;
uniform int blockEntityId;
uniform int currentRenderedItemId;
uniform float windTime;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#include "/lib/entities.glsl"
#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/shadows.glsl"

#ifdef WIND_ENABLED
    #include "/lib/hash-noise.glsl"
    #include "/lib/wind-waving.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
    #include "/lib/sampling/block-light.glsl"
#endif


void main() {
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);

    bool isRenderTerrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
        || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

    #if !defined(SHADOWS_ENABLED) || !defined(SHADOW_COLORED)
        int blockId;
    #endif
    blockId = int(mc_Entity.x + EPSILON);
    if (mc_Entity.x < 0.0) blockId = BLOCK_SOLID;

    #ifdef LIGHTING_COLORED
        bool ignoreBlock = blockId <= 0
            || blockId == BLOCK_WATER
            || blockId == BLOCK_IGNORED;

        vec3 localPos = mul3(shadowModelViewInverse, viewPos);
        vec3 originPos = vec3(-9999.0);

        int lpvId = blockId;
        if (!isRenderTerrain) {
//            if (lightRange > 0) {
            lpvId = currentRenderedItemId;
//                originPos = localPos;
//            }
        }

        vec3 lightColor;
        float lightRange;
        GetBlockColorRange(lpvId, lightColor, lightRange);

        if (isRenderTerrain) {
            #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
                if (lightRange > 0.0) ignoreBlock = true;
            #endif

            if (!ignoreBlock && (gl_VertexID % 4) == 0) {
                originPos = localPos + at_midBlock.xyz / 64.0;
            }
        }
        else if (entityId != ENTITY_PLAYER_CURRENT) {
            if (lightRange > 0) {
//                lpvId = currentRenderedItemId;
                originPos = localPos;
            }
        }

        ivec3 voxelPos = ivec3(GetVoxelPosition(originPos));
        if (IsInVoxelBounds(voxelPos)) {
            imageStore(imgVoxels, voxelPos, uvec4(lpvId));
        }
    #endif

    #ifdef SHADOWS_ENABLED
        #if !defined(RENDER_SOLID) || defined(SHADOW_COLORED)
            texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        #endif

        #ifdef SHADOW_COLORED
            color = gl_Color;
        #endif

        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);

        if (isRenderTerrain) {
            #if defined(WATER_WAVE_ENABLED) || defined(WIND_ENABLED)
                vec3 localPos = mul3(shadowModelViewInverse, viewPos);
            #endif

            #ifdef WATER_WAVE_ENABLED
                if (blockId == BLOCK_WATER) {
                    vec2 waterWorldPos = (localPos.xz + cameraPosition.xz) / WaterNormalScale;
                    // add 1px offset to avoid flickering at seams
                    vec2 water_uv = fract(waterWorldPos + (1.0/WaterNormalResolution));
                    float waveHeight = texture(texWaterHeight, water_uv).r;

                    float viewDist = length(localPos);
                    float fadeDist = smoothstep(0.0, 2.0, viewDist);
                    localPos.y += (waveHeight*0.5 - 0.4) * fadeDist;
                }
            #endif

            #ifdef WIND_ENABLED
                vec3 originPos = localPos + at_midBlock.xyz / 64.0;
                vec3 wind = GetWindForce(originPos, windTime);
                localPos += GetWindWavingOffset(wind, blockId);
            #endif

            #if defined(WATER_WAVE_ENABLED) || defined(WIND_ENABLED)
                viewPos = mul3(shadowModelView, localPos);
            #endif
        }

        vec3 viewPosOffset = viewPos;

        #ifndef RENDER_TRANSLUCENT
            viewPosOffset.z -= 0.20 * max(viewNormal.z, 0.0);
        #endif

        gl_Position = gl_ProjectionMatrix * vec4(viewPosOffset, 1.0);
        distort(gl_Position.xy);
    #else
        gl_Position = vec4(-10.0);
    #endif
}
