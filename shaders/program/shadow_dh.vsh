#define RENDER_SHADOW_DH
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    float cameraViewDist;

    flat uint materialId;
} vOut;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
    #include "/lib/world/curvature.glsl"
#endif

#ifdef RENDER_SHADOWS_ENABLED
    // #include "/lib/utility/matrix.glsl"
    // #include "/lib/buffers/shadow.glsl"
    // #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        // #include "/lib/shadows/cascaded/common.glsl"
    #elif SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif


void main() {
    vOut.materialId = uint(dhMaterialId);
    vOut.color = gl_Color;

    vOut.color.rgb = RGBToLinear(vOut.color.rgb);

    bool isWater = (dhMaterialId == DH_BLOCK_WATER);
    //if (isWater) vOut.color = vec4(0.90, 0.94, 0.96, 0.0);

    vec4 vPos = gl_Vertex;
    
    vec3 cameraOffset = fract(cameraPosition);
    vPos.xyz = floor(vPos.xyz + cameraOffset + 0.5) - cameraOffset;

    gl_Position = vec4(mul3(gl_ModelViewMatrix, vPos.xyz), 1.0);

    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            mat4 shadowModelViewEx = shadowModelView;
        #endif

        vec3 localPos = mul3(shadowModelViewInverse, gl_Position.xyz);

        #if WORLD_CURVE_RADIUS > 0 && defined WORLD_CURVE_SHADOWS
            localPos = GetWorldCurvedPosition(localPos);
        #endif

        vOut.cameraViewDist = length(localPos);

        gl_Position.w = 1.0;
        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED

            #ifdef IRIS_FEATURE_SSBO
                gl_Position.xyz = mul3(shadowModelViewProjection, localPos);
            #else
                gl_Position.xyz = mul3(gl_ModelViewMatrix, localPos);
                gl_Position.xyz = mul3(gl_ProjectionMatrix, gl_Position.xyz);
            #endif

            gl_Position.xyz = distort(gl_Position.xyz);
        #else
            gl_Position.xyz = mul3(shadowModelViewEx, localPos);
        #endif
    #endif
}
