#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;
out vec3 vPos;
out vec3 vLocalPos;
out vec4 vColor;
out float geoNoL;
out vec3 vBlockLight;

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        out vec3 shadowPos[4];
        flat out int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        out vec3 shadowPos;
    #endif
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/sampling/noise.glsl"

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/basic.glsl"
    #endif
#endif

#include "/lib/lighting/basic.glsl"


void main() {
    vColor = gl_Color;

    #ifndef IS_IRIS
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #endif

    BasicVertex();
}
