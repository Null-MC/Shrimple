#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 at_midBlock;

out VertexData {
    vec2 texcoord;
    float viewDist;
    float lightRange;

    flat vec3 originPos;
} vOut;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float far;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferProjection;
    uniform float near;
#endif

#include "/lib/utility/lightmap.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    //#include "/lib/buffers/shadow.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
    #include "/lib/world/curvature.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    //vOut.color = gl_Color;

    vec3 geoViewNormal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 pos = gl_Vertex;
    vOut.originPos = pos.xyz;
//    if ((blockId < BLOCK_LIGHT_1 || blockId > BLOCK_LIGHT_15) && isRenderTerrain) {
//        vOut.originPos += at_midBlock.xyz / 64.0;
//    }

    vOut.originPos = mul3(gl_ModelViewMatrix, vOut.originPos);

//    if (!isRenderTerrain) {
        vOut.originPos -= 0.05 * geoViewNormal;
//    }

    vOut.originPos = mul3(shadowModelViewInverse, vOut.originPos);

    vOut.lightRange = at_midBlock.w;

    vec3 viewPos = mul3(gl_ModelViewMatrix, pos.xyz);
    vec3 localPos = mul3(shadowModelViewInverse, viewPos);
    vOut.viewDist = length(localPos);

    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            mat4 shadowModelViewEx = shadowModelView;
        #endif

        #if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
            localPos = GetWorldCurvedPosition(localPos);
        #endif

        gl_Position = vec4(mul3(shadowModelViewEx, localPos), 1.0);
    #endif
}
