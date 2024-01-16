#define RENDER_WATER_DH
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

// in vec3 at_midBlock;
// in vec4 at_tangent;
// in vec4 mc_Entity;
// in vec4 mc_midTexCoord;
// in vec3 vaPosition;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    // vec2 texcoord;
    vec3 localPos;
    // vec2 localCoord;
    vec3 localNormal;
    // vec4 localTangent;

    // flat int blockId;
    // flat mat2 atlasBounds;

    // #if defined PARALLAX_ENABLED || defined WORLD_WATER_ENABLED
    //     vec3 viewPos_T;

    //     #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
    //         vec3 lightPos_T;
    //     #endif
    // #endif

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        vec3 physics_localPosition;
        float physics_localWaviness;
    #endif

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;

uniform sampler2D lightmap;

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE //&& !defined RENDER_SHADOWS_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
// uniform ivec2 atlasSize;

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
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE //&& !defined RENDER_SHADOWS_ENABLED
    // uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
#endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    // uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"

    // #if LIGHTING_MODE != DYN_LIGHT_NONE
    //     #include "/lib/buffers/light_static.glsl"
    //     #include "/lib/buffers/block_voxel.glsl"
    // #endif

    // #if LIGHTING_MODE == DYN_LIGHT_TRACED
    //     #include "/lib/buffers/light_voxel.glsl"
    // #endif
#endif

// #include "/lib/blocks.glsl"
// #include "/lib/lights.glsl"

// #include "/lib/sampling/atlas.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
// #include "/lib/utility/tbn.glsl"

#if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
    //#include "/lib/buffers/block_static.glsl"
    // #include "/lib/world/waving.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif

// #include "/lib/material/normalmap.glsl"

#ifdef WORLD_WATER_ENABLED
    #ifdef PHYSICS_OCEAN
        #include "/lib/physics_mod/ocean.glsl"
    #elif WATER_WAVE_SIZE != WATER_WAVES_NONE
        #include "/lib/world/water_waves.glsl"
    #endif
#endif

// #include "/lib/lighting/common.glsl"

// #if LIGHTING_MODE != DYN_LIGHT_NONE //&& !defined RENDER_SHADOWS_ENABLED
//     #ifdef LIGHTING_FLICKER
//         #include "/lib/lighting/blackbody.glsl"
//         #include "/lib/lighting/flicker.glsl"
//     #endif

//     #include "/lib/lighting/voxel/mask.glsl"
//     #include "/lib/lighting/voxel/block_mask.glsl"
//     #include "/lib/lighting/voxel/blocks.glsl"

//     #if LPV_SIZE > 0 && (LIGHTING_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
//         #include "/lib/lighting/voxel/lpv.glsl"
//         // #include "/lib/lighting/voxel/entities.glsl"
//     #endif

//     #if LIGHTING_MODE == DYN_LIGHT_TRACED
//         #include "/lib/lighting/voxel/lights.glsl"
//         #include "/lib/lighting/voxel/light_mask.glsl"
//     #endif

//     #if LPV_SIZE > 0 //&& (LIGHTING_MODE == DYN_LIGHT_LPV || LPV_SUN_SAMPLES > 0)
//         #include "/lib/buffers/volume.glsl"
//     #endif

//     #include "/lib/lighting/voxel/lights_render.glsl"
// #endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa.glsl"
#endif


void main() {
    // vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    // vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord  = gl_MultiTexCoord1.xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    // vec4 viewPos = BasicVertex();

    vec4 pos = gl_Vertex;
    pos.y -= (2.0/16.0);

    vec4 viewPos = gl_ModelViewMatrix * pos;

    const bool isWater = true;

    // if (isWater) {
    //     float distF = 1.0 - smoothstep(0.2, 2.8, length(viewPos.xyz));
    //     distF = 1.0 - _pow2(distF);

    //     #ifdef PHYSICS_OCEAN
    //         vOut.physics_localWaviness = texelFetch(physics_waviness, ivec2(pos.xz) - physics_textureOffset, 0).r;

    //         #ifdef WATER_DISPLACEMENT
    //             pos.y += distF * physics_waveHeight(pos.xz, PHYSICS_ITERATIONS_OFFSET, vOut.physics_localWaviness, physics_gameTime);
    //         #endif

    //         vOut.physics_localPosition = pos.xyz;
    //     #elif WATER_WAVE_SIZE != WATER_WAVES_NONE && defined WATER_DISPLACEMENT
    //         vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;
    //         float time = GetAnimationFactor();

    //         vec2 uvOffset = vec2(0.0);
    //         // if (vOut.blockId == BLOCK_LILY_PAD) {
    //         //     vec3 originPos = vOut.localPos + at_midBlock/64.0;
    //         //     water_waveHeight(cameraPosition.xz + originPos.xz, vOut.lmcoord.y, time, uvOffset);
    //         //     uvOffset *= 0.5;
    //         //     pos.xz += uvOffset;
    //         // }

    //         // vec2 _o;
    //         float waveOffset = distF * water_waveHeight(vOut.localPos.xz + cameraPosition.xz + uvOffset, vOut.lmcoord.y, time, uvOffset);
    //         pos.y += waveOffset;

    //         // #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
    //         //     float timePrev = time - frameTime;
                
    //         //     vec2 uvOffsetPrev;
    //         //     if (vOut.blockId == BLOCK_LILY_PAD) {
    //         //         vec3 originPos = vOut.localPos + at_midBlock/64.0;
    //         //         water_waveHeight(previousCameraPosition.xz + originPos.xz, vOut.lmcoord.y, timePrev, uvOffsetPrev);
    //         //         uvOffsetPrev *= 0.5;

    //         //         vOut.velocity.xz += uvOffset - uvOffsetPrev;
    //         //     }
                
    //         //     float waveOffsetPrev = distF * water_waveHeight(vOut.localPos.xz + previousCameraPosition.xz + uvOffset, vOut.lmcoord.y, timePrev, _o);
    //         //     vOut.velocity.y += waveOffset - waveOffsetPrev;
    //         // #endif
    //     #endif

    //     viewPos = gl_ModelViewMatrix * pos;
    // }

    vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;

    // vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);

    // #if defined RENDER_BILLBOARD //|| defined RENDER_CLOUDS
    //     vec3 _vLocalNormal = mat3(gbufferModelViewInverse) * viewNormal;
    // #else
    //     vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;
    // #endif

    // vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = gl_Normal;// mat3(gbufferModelViewInverse) * viewNormal;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vOut.shadowTile = -1;
        #endif

        // #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
        //     vec3 skyLightDir = normalize(shadowLightPosition);
        //     float geoNoL = dot(skyLightDir, viewNormal);
        // #else
            float geoNoL = 1.0;
        // #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            // #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
            //     ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
            // #else
                ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
            // #endif
        #else
            // #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
            //     vOut.shadowPos = ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL);
            // #else
                vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
            // #endif
        #endif

        #if defined RENDER_CLOUD_SHADOWS_ENABLED //&& !defined RENDER_CLOUDS
            vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
        #endif
    #endif

    // #if (defined RENDER_WATER && defined WORLD_WATER_ENABLED && WATER_TESSELLATION_QUALITY > 0) || DISPLACE_MODE == DISPLACE_TESSELATION
    //     gl_Position = viewPos;
        
    //     #if DISPLACE_MODE != DISPLACE_TESSELATION
    //         if (vOut.blockId != BLOCK_WATER) {
    //             gl_Position = gl_ProjectionMatrix * gl_Position;
        
    //             #ifdef EFFECT_TAA_ENABLED
    //                 jitter(gl_Position);
    //             #endif
    //         }
    //     #endif
    // #else
        gl_Position = gl_ProjectionMatrix * viewPos;

        #ifdef EFFECT_TAA_ENABLED
            jitter(gl_Position);
        #endif
    // #endif

    // PrepareNormalMap();

    // GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    // #if defined PARALLAX_ENABLED || defined WORLD_WATER_ENABLED
    //     vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    //     vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
    //     mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

    //     //vec3 viewPos = (gbufferModelView * vec4(vOut.localPos, 1.0)).xyz;
    //     vOut.viewPos_T = viewPos.xyz * matViewTBN;

    //     #ifdef WORLD_SHADOW_ENABLED
    //         vOut.lightPos_T = shadowLightPosition * matViewTBN;
    //     #endif
    // #endif
}
