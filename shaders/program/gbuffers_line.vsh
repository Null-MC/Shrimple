#define RENDER_GBUFFER
#define RENDER_LINE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 vaPosition;
in vec3 vaNormal;

out VertexData {
    flat vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vOut;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec2 viewSize;
uniform vec2 pixelSize;

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 linePosStart = vec4(mul3(modelViewMatrix, vaPosition), 1.0);
    linePosStart = projectionMatrix * linePosStart;
    vec3 ndc1 = unproject(linePosStart);

    vec4 linePosEnd = vec4(mul3(modelViewMatrix, vaPosition + vaNormal), 1.0);
    linePosEnd = projectionMatrix * linePosEnd;
    vec3 ndc2 = unproject(linePosEnd);

    vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * viewSize);
    vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * BLOCK_OUTLINE_WIDTH * pixelSize;

    if (lineOffset.x < 0.0) lineOffset = -lineOffset;
    if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;
    gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);

    vec3 viewPos = unproject(gbufferProjectionInverse * gl_Position);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
