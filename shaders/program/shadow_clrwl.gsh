#define RENDER_SHADOW
#define RENDER_GEOMETRY

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 texcoord;
    float viewDist;
    float lightRange;

    flat vec3 originPos;
} vIn[];

out VertexData {
    vec2 texcoord;
    float viewDist;
    float lightRange;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vOut;

#if defined LIGHTING_FLICKER && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler2D noisetex;
#endif

//uniform int renderStage;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
//uniform vec3 previousCameraPosition;
uniform int blockEntityId;
uniform float far;

#ifdef SHADOW_TAA
    uniform vec2 pixelSize;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform float near;

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#if LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED
    uniform int entityId;
    uniform int frameCounter;
    uniform vec3 eyePosition;
    uniform vec3 relativeEyePosition;
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
//    uniform int currentRenderedItemId;

//    #ifdef ANIM_WORLD_TIME
//        uniform int worldTime;
//    #else
//        uniform float frameTimeCounter;
//    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    
    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/block_static.glsl"
        #include "/lib/buffers/light_static.glsl"
        #include "/lib/buffers/volume.glsl"

        #include "/lib/lights.glsl"

        //#include "/lib/sampling/noise.glsl"
        #include "/lib/utility/hsv.glsl"

        #include "/lib/voxel/voxel_common.glsl"
        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_write.glsl"
    #endif
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/buffers/shadow.glsl"
    #endif

    #include "/lib/utility/matrix.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif

#ifdef SHADOW_TAA
    #include "/lib/effects/taa_jitter.glsl"
#endif


#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    // returns: tile [0-3] or -1 if excluded
    int GetShadowRenderTile(const in vec3 blockPos) {
        const int max = 4;

        for (int i = 0; i < max; i++) {
            if (CascadeContainsPosition(blockPos, i, 3.0)) return i;
        }

        return -1;
    }
#endif

void main() {
    vec3 originPos = (vIn[0].originPos + vIn[1].originPos + vIn[2].originPos) / 3.0;

    #ifdef IS_LPV_ENABLED
        float lightRange = vIn[0].lightRange;

        if (lightRange > EPSILON) {
            vec3 lpvPos = GetVoxelPosition(originPos);
            ivec3 imgCoordPrev = ivec3(lpvPos) + GetVoxelFrameOffset();

            uint lightType = StaticBlockMap[blockEntityId].lightType;
            vec3 lightColor = vec3(1.0);

            if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                StaticLightData lightInfo = StaticLightMap[lightType];
                lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
//                    vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
//                    lightRange = lightRangeSize.x * 255.0;

                lightColor = RGBToLinear(lightColor);

//                    vec3 worldPos = cameraPosition + originPos;
//                    ApplyLightAnimation(lightColor, lightRange, lightType, worldPos);

//                    #ifdef LIGHTING_FLICKER
//                        vec2 lightNoise = GetDynLightNoise(worldPos);
//                        ApplyLightFlicker(lightColor, lightType, lightNoise);
//                    #endif
            }

            AddLpvLight(imgCoordPrev, lightColor, lightRange);
        }
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 originShadowViewPos = mul3(shadowModelViewEx, originPos);

            int shadowTile = GetShadowRenderTile(originShadowViewPos);
            if (shadowTile < 0) return;

            #ifdef SHADOW_CSM_OVERLAP
                int cascadeMin = max(shadowTile - 1, 0);
                int cascadeMax = min(shadowTile + 1, 3);
            #else
                int cascadeMin = shadowTile;
                int cascadeMax = shadowTile;
            #endif

            for (int c = cascadeMin; c <= cascadeMax; c++) {
                if (c != shadowTile) {
                    #ifdef SHADOW_CSM_OVERLAP
                        // duplicate geometry if intersecting overlapping cascades
                        if (!CascadeContainsPosition(originShadowViewPos, c, 9.0)) continue;
                    #else
                        continue;
                    #endif
                }

                vec2 shadowTilePos = shadowProjectionPos[c];

                for (int v = 0; v < 3; v++) {
                    vOut.shadowTilePos = shadowTilePos;

                    vOut.texcoord = vIn[v].texcoord;
                    vOut.viewDist = vIn[v].viewDist;
                    vOut.lightRange = vIn[v].lightRange;

                    clrwl_setVertexOut(v);

                    gl_Position.xyz = mul3(cascadeProjection[c], gl_in[v].gl_Position.xyz);
                    gl_Position.w = 1.0;

                    gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
                    gl_Position.xy = gl_Position.xy * 0.5 + shadowTilePos;
                    gl_Position.xy = gl_Position.xy * 2.0 - 1.0;

                    #ifdef SHADOW_TAA
                        gl_Position.xy += getJitterOffset(frameCounter, vec2(shadowPixelSize)) * 2.0;
                    #endif

                    EmitVertex();
                }

                EndPrimitive();
            }
        #else
            for (int v = 0; v < 3; v++) {
                vOut.texcoord = vIn[v].texcoord;
                vOut.viewDist = vIn[v].viewDist;
                vOut.lightRange = vIn[v].lightRange;

                clrwl_setVertexOut(v);

                #ifdef IRIS_FEATURE_SSBO
                    gl_Position.xyz = mul3(shadowProjectionEx, gl_in[v].gl_Position.xyz);
                #else
                    gl_Position.xyz = mul3(gl_ProjectionMatrix, gl_in[v].gl_Position.xyz);
                #endif

                gl_Position.xyz = distort(gl_Position.xyz);
                gl_Position.w = 1.0;

                #ifdef SHADOW_TAA
                    gl_Position.xy += getJitterOffset(frameCounter, vec2(shadowPixelSize)) * 2.0;
                #endif

                EmitVertex();
            }

            EndPrimitive();
        #endif
    #endif
}
