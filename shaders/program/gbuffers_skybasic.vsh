#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
	uniform vec2 pixelSize;

    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
	gl_Position = ftransform();

	starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
