#define RENDER_ARMOR_GLINT
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 taa_offset;

    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	//lmcoord = (TEXTURE_MATRIX_2 * vec4(lmcoord, 0.0, 1.0)).xy;

    //use same transforms as entities and hand to avoid z-fighting issues
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
