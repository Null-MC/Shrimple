#define RENDER_SHADOW_DH
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    float cameraViewDist;

    flat uint materialId;

    // #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //     // TODO: this isn't really needed but throws error without
    //     flat vec2 shadowTilePos;
    // #endif
} vOut;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif


void main() {
    vOut.materialId = uint(dhMaterialId);
    vOut.color = gl_Color;

    bool isWater = (dhMaterialId == DH_BLOCK_WATER);
    //if (isWater) vOut.color = vec4(0.90, 0.94, 0.96, 0.0);

    vec4 vPos = gl_Vertex;
    
    vec3 cameraOffset = fract(cameraPosition);
    vPos.xyz = floor(vPos.xyz + cameraOffset + 0.5) - cameraOffset;

    gl_Position = gl_ModelViewMatrix * vPos;

    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            mat4 shadowModelViewEx = shadowModelView;
        #endif

        gl_Position = shadowModelViewInverse * gl_Position;

        vOut.cameraViewDist = length(gl_Position.xyz);

        gl_Position = shadowModelViewEx * gl_Position;
    #endif
}
