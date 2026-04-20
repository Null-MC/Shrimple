#include "/lib/constants.glsl"
#include "/lib/common.glsl"


out VertexData {
    flat uint color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vOut;


uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform mat4 gbufferModelViewInverse;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;

#ifdef TAA_ENABLED
    uniform vec2 taa_offset = vec2(0.0);
#endif


#include "/lib/sampling/lightmap.glsl"

#ifdef LIGHTING_HAND
    #include "/lib/lighting/hand.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vOut.color = packUnorm4x8(gl_Color);

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

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

    #if defined(LIGHTING_HAND) && LIGHTING_MODE == LIGHTING_MODE_VANILLA && !defined(LIGHTING_COLORED)
        float handDist = GetHandDistance(vOut.localPos);

        float handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
        float handLight = max(handLightLevel - handDist, 0.0) / 15.0;
        vOut.lmcoord.x = max(vOut.lmcoord.x, handLight);
    #endif
}
