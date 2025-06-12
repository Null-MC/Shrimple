#define RENDER_PHY_LIQUID
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

//in vec3 at_midBlock;
//in vec4 at_tangent;
//in vec4 mc_Entity;
//in vec4 mc_midTexCoord;
//in vec3 vaPosition;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;
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
//uniform ivec2 atlasSize;
uniform float far;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;

    #ifdef WORLD_SKY_ENABLED
        uniform float rainStrength;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    // uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    uniform float cloudTime;
    uniform float cloudHeight;

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    // uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
#endif

uniform bool firstPersonCamera;
uniform vec3 eyePosition;

#ifdef EFFECT_TAA_ENABLED
    // uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/buffers/light_static.glsl"
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/buffers/light_voxel.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"

//#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/noise.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/tbn.glsl"

//#if WORLD_WIND_STRENGTH > 0 //&& defined WORLD_SKY_ENABLED
//    //#include "/lib/buffers/block_static.glsl"
//    #include "/lib/world/waving.glsl"
//#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

//    #ifdef SHADOW_CLOUD_ENABLED
//        #include "/lib/clouds/cloud_vanilla.glsl"
//    #endif

    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
    #endif
#endif

#include "/lib/lights.glsl"

//#include "/lib/material/normalmap.glsl"

//#ifdef WORLD_WATER_ENABLED
//    #if WATER_WAVE_SIZE > 0
//        #include "/lib/water/water_waves.glsl"
//    #endif
//#endif

#include "/lib/vertex_common.glsl"

#if (LIGHTING_MODE != LIGHTING_MODE_NONE && !defined DEFERRED_BUFFER_ENABLED) || (defined IS_LPV_ENABLED && !defined RENDER_SHADOWS_ENABLED)
    #include "/lib/voxel/voxel_common.glsl"
    #include "/lib/voxel/lights/mask.glsl"
    #include "/lib/voxel/blocks.glsl"

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/voxel/lights/light_mask.glsl"
    #endif
#endif

#if !defined DEFERRED_BUFFER_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    // #include "/lib/voxel/lights/mask.glsl"
    // #include "/lib/voxel/blocks.glsl"

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
    #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_write.glsl"
        // #include "/lib/lighting/voxel/entities.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/voxel/lights.glsl"
    #endif

    #include "/lib/lighting/voxel/lights_render.glsl"
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    //vec4 viewPos = BasicVertex();
    vec4 pos = gl_Vertex;
    vec3 viewPos = mul3(gl_ModelViewMatrix, pos.xyz);

    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #if WORLD_CURVE_RADIUS > 0
        float angleY = 1.0;

        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos, angleY);
            viewPos = mul3(gbufferModelView, vOut.localPos);

            if (vOut.localPos.y + cameraPosition.y < -WORLD_CURVE_RADIUS) viewPos = vec3(666.666);
        #else
            vec3 localPos = GetWorldCurvedPosition(vOut.localPos, angleY);
            viewPos = mul3(gbufferModelView, localPos);
        #endif

        //        if (angleY <= 0.0) viewPos = vec3(666.666);
    #endif

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    #if defined RENDER_SHADOWS_ENABLED && (!defined DEFERRED_BUFFER_ENABLED || defined RENDER_WEATHER)
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vOut.shadowTile = -1;
        #endif

        #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED && !defined RENDER_BILLBOARD
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
            #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
                vOut.shadowPos = ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL);
            #else
                vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
            #endif
        #endif

        // #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS && SKY_CLOUD_TYPE == CLOUD_TYPE_VANILLA
        //     vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
        // #endif
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
