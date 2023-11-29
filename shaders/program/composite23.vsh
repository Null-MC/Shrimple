#define RENDER_COMPOSITE_BLOOM
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;

uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/post/bloom.glsl"


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	UpdateTileVertexBounds_Up(EFFECT_BLOOM_TILE_MAX-3);
}
