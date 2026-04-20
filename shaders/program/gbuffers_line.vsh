#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 vaPosition;
in vec3 vaNormal;

out VertexData {
    flat uint color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vOut;

uniform vec2 viewSize;
uniform int renderStage;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/sampling/lightmap.glsl"


void main() {
    #if BLOCK_OUTLINE_TYPE == BLOCK_OUTLINE_NONE
        if (renderStage == MC_RENDER_STAGE_OUTLINE) {
            gl_Position = vec4(-10.0);
            return;
        }
    #endif

    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vOut.color = packUnorm4x8(gl_Color);

    vec2 pixelSize = 1.0 / viewSize;

    vec4 linePosStart = vec4(mul3(modelViewMatrix, vaPosition), 1.0);
    linePosStart = projectionMatrix * linePosStart;
    vec3 ndc1 = project(linePosStart);

    vec4 linePosEnd = vec4(mul3(modelViewMatrix, vaPosition + vaNormal), 1.0);
    linePosEnd = projectionMatrix * linePosEnd;
    vec3 ndc2 = project(linePosEnd);

    vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * viewSize);
    vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * BLOCK_OUTLINE_WIDTH * pixelSize;

    if (lineOffset.x < 0.0) lineOffset = -lineOffset;
    if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;
    gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);

    vec3 viewPos = project(gbufferProjectionInverse * gl_Position);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #ifdef TAA_ENABLED
        gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
    #endif

    #if RENDER_SCALE != 0
        gl_Position.xy /= gl_Position.w;
        gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
        gl_Position.xy *= RENDER_SCALE_F;
        gl_Position.xy = gl_Position.xy * 2.0 - 1.0;
        gl_Position.xy *= gl_Position.w;
    #endif
}
