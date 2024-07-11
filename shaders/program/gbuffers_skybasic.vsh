#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if SKY_STARS == STARS_VANILLA
    varying vec4 starData; //rgb = star color, a = flag for wether or not this pixel is a star.
#endif

uniform int renderStage;

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
    uniform vec2 pixelSize;

    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    gl_Position = ftransform();

    #if SKY_STARS == STARS_VANILLA
        starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
    #else
        if (renderStage == MC_RENDER_STAGE_STARS) {
            gl_Position = vec4(-1.0);
            return;
        }
    #endif

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
