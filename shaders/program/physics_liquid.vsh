#define RENDER_PHY_LIQUID
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    ivec2 vertId = gl_VertexID & ivec2(1, 2);
    ivec2 xy = (vertId << ivec2(2, 1)) - 1;
    gl_Position = vec4(xy, 0.0, 1.0);

//    #ifdef EFFECT_TAA_ENABLED
//        jitter(gl_Position);
//    #endif
}
