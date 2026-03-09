#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    vec3 physics_localPosition;
    float physics_localWaviness;
} vOut;


uniform mat4 gbufferModelViewInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/sampling/lightmap.glsl"
#include "/lib/phy-ocean.glsl"


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vOut.color = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    float distF = 1.0 - smoothstep(0.2, 2.8, length(viewPos));
    distF = 1.0 - _pow2(distF);

    vOut.physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

    vec3 modelPos = gl_Vertex.xyz;
    modelPos.y += distF * physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, vOut.physics_localWaviness, physics_gameTime);
    vOut.physics_localPosition = modelPos;

    viewPos = mul3(gl_ModelViewMatrix, modelPos);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
}
