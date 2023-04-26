#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define LINE_WIDTH 3.0
#define VIEW_SCALE 1.0

in vec3 vaPosition;
in vec3 vaNormal;

out vec2 lmcoord;
out vec2 texcoord;
flat out vec4 glcolor;
out vec3 vLocalPos;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif


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

    // TODO: Does this need perspective divide?
    vLocalPos = (gbufferModelViewProjectionInverse * gl_Position).xyz;
}
