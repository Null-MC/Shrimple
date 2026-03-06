#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in vec4 mc_Entity;
in vec4 at_midBlock;

#ifndef RENDER_SOLID
    out vec2 texcoord;
#endif

#ifdef LIGHTING_COLORED
    layout(r16ui) uniform writeonly uimage3D imgVoxels;
#endif

#ifdef WIND_ENABLED
    uniform usampler2D texBlockWaving;
#endif

uniform int renderStage;
uniform int blockEntityId;
uniform float frameTimeCounter;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#include "/lib/blocks.glsl"
#include "/lib/shadows.glsl"

#ifdef WIND_ENABLED
    #include "/lib/wind-waving.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
#endif


void main() {
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);

    bool isRenderTerrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
        || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

    int blockId = int(mc_Entity.x + EPSILON);
    if (mc_Entity.x < 0.0) blockId = BLOCK_SOLID;

    #ifdef LIGHTING_COLORED
        bool ignoreBlock = blockId <= 0
            || blockId == BLOCK_WATER
            || blockId == BLOCK_IGNORED;

        if (isRenderTerrain && !ignoreBlock && (gl_VertexID % 4) == 0) {
            vec3 localPos = mul3(shadowModelViewInverse, viewPos);
            vec3 originPos = localPos + at_midBlock.xyz / 64.0;
            ivec3 voxelPos = ivec3(GetVoxelPosition(originPos));

            if (IsInVoxelBounds(voxelPos)) {
                imageStore(imgVoxels, voxelPos, uvec4(blockId));
            }
        }
    #endif

    #ifdef SHADOWS_ENABLED
        #ifndef RENDER_SOLID
            texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        #endif

        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);

        #ifdef WIND_ENABLED
            if (isRenderTerrain) {
                vec3 localPos = mul3(shadowModelViewInverse, viewPos);

                ApplyWindWaving(localPos, blockId);

                viewPos = mul3(shadowModelView, localPos);
            }
        #endif

        vec3 viewPosOffset = viewPos;
        viewPosOffset.z -= 0.20 * viewNormal.z;

        gl_Position = gl_ProjectionMatrix * vec4(viewPosOffset, 1.0);
        distort(gl_Position.xy);
    #else
        gl_Position = vec4(-10.0);
    #endif
}
