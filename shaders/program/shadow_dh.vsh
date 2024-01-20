#define RENDER_SHADOW_DH
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;

    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        // TODO: this isn't really needed but throws error without
        flat vec2 shadowTilePos;
    #endif
} vOut;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif


void main() {
    vOut.color = gl_Color;

    gl_Position = gl_ModelViewMatrix * gl_Vertex;

    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            mat4 shadowModelViewEx = shadowModelView;
        #endif

        gl_Position = shadowModelViewInverse * gl_Position;
        gl_Position = shadowModelViewEx * gl_Position;
    #endif
}
