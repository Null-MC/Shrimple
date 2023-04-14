#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define LINE_WIDTH 3.0
#define VIEW_SCALE 1.0

out vec2 lmcoord;
out vec2 texcoord;
flat out vec4 glcolor;
out vec3 vLocalPos;

// #ifdef WORLD_SHADOW_ENABLED
//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         out vec3 shadowPos[4];
//         flat out int shadowTile;
//     #elif SHADOW_TYPE != SHADOW_TYPE_NONE
//         out vec3 shadowPos;
//     #endif
// #endif

//uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

// #ifdef WORLD_SHADOW_ENABLED
//     uniform mat4 shadowModelView;
//     uniform mat4 shadowProjection;
//     uniform vec3 shadowLightPosition;
//     uniform float far;

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         uniform mat4 gbufferProjection;
//         uniform float near;
//     #endif
// #endif

// #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
//     #include "/lib/utility/matrix.glsl"
//     #include "/lib/buffers/shadow.glsl"
//     #include "/lib/shadows/common.glsl"

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         #include "/lib/shadows/cascaded.glsl"
//     #else
//         #include "/lib/shadows/basic.glsl"
//     #endif
// #endif


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    vec4 linePosStart = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition, 1.0)));
    vec3 ndc1 = unproject(linePosStart);

    vec4 linePosEnd = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition + vaNormal, 1.0)));
    vec3 ndc2 = unproject(linePosEnd);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * viewSize);
    vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * LINE_WIDTH / viewSize;

    if (lineOffset.x < 0.0) lineOffset = -lineOffset;
    if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;
    gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);

    vec3 viewPos = (gbufferProjectionInverse * gl_Position).xyz;
    vLocalPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}
