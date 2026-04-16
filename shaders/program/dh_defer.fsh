#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat int materialId;
} vIn;


#ifdef RENDER_TRANSLUCENT
    uniform sampler2D depthtex0;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D texLightmap;
#endif

#ifdef SHADOWS_ENABLED
    uniform SHADOW_SAMPLER TEX_SHADOW;

    #ifdef SHADOW_COLORED
        uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

uniform float far;
//uniform float nearPlane;
//uniform float farPlane;
//uniform vec3 fogColor;
//uniform float fogStart;
//uniform float fogEnd;
//uniform vec3 skyColor;
//uniform float skyDayF;
//uniform int hasSkylight;
//uniform float rainStrength;
//uniform float weatherStrength;
//uniform float weatherDensity;
//uniform float cloudHeight;
//uniform float cloudTime;
//uniform vec3 eyePosition;
//uniform vec3 sunLocalDir;
//uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
//uniform mat4 gbufferModelViewInverse;
//uniform mat4 gbufferProjectionInverse;
//uniform mat4 shadowModelView;
//uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
//uniform ivec2 eyeBrightnessSmooth;
//uniform int isEyeInWater;
//uniform float frameTimeCounter;
//uniform int frameCounter;
//uniform vec2 viewSize;

//uniform int vxRenderDistance;
//uniform float dhNearPlane;
//uniform float dhFarPlane;

//#include "/lib/oklab.glsl"
//#include "/lib/ign.glsl"
//#include "/lib/fog.glsl"
//#include "/lib/sampling/depth.glsl"
//#include "/lib/sampling/lightmap.glsl"
#include "/lib/dh-noise.glsl"
//#include "/lib/shadows.glsl"
#include "/lib/octohedral.glsl"


layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outNormals;
layout(location = 2) out uvec2 outSpecularMeta;

#ifdef VELOCITY_ENABLED
    /* RENDERTARGETS: 4,5,6,3 */
    layout(location = 3) out vec3 outVelocity;
#else
    /* RENDERTARGETS: 4,5,6 */
#endif

void main() {
    vec3 localNormal = normalize(vIn.localNormal);
    float viewDist = length(vIn.localPos);

    vec4 color = vIn.color;

    vec3 worldPos = vIn.localPos + cameraPosition;
    applyNoise(color.rgb, 1.0, worldPos, viewDist);

    if (viewDist < dh_clipDistF * far) {discard;}


    outAlbedo = color;

    #ifdef DEFERRED_ENABLED
        const float occlusion = 1.0;
        const vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);
        uint matId = MAT_NONE;

        if (vIn.materialId == DH_BLOCK_WATER)
            matId = MAT_WATER;

        vec3 viewNormal = mat3(gbufferModelView) * localNormal;
        outNormals = vec4(OctEncode(localNormal), OctEncode(viewNormal));

        outSpecularMeta = uvec2(
            packUnorm4x8(specularData),
            packUnorm4x8(vec4(vIn.lmcoord, occlusion, matId / 255.0))
        );
    #endif

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif
}
