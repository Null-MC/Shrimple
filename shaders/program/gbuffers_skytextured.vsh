#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
	vec4 color;
	vec2 texcoord;
} vOut;

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
	uniform vec2 pixelSize;

    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
	gl_Position = ftransform();
	
	vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vOut.color = gl_Color;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
