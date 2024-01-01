#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
	uniform vec2 pixelSize;

    #include "/lib/effects/taa.glsl"
#endif


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
