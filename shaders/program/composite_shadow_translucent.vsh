#define RENDER_SHADOW_TRANSLUCENT
#define RENDER_COMPOSITE
#define RENDER_VERTEX
#define RENDER_TRANSLUCENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
