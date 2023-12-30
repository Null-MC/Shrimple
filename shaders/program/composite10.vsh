#define RENDER_COMPOSITE_TAA
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;


void main() {
 	gl_Position = ftransform();
 	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
