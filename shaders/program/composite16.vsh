#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/post/bloom.glsl"


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	UpdateTileVertexBounds(5);
}
