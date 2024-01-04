#define RENDER_COMPOSITE_BLOOM_DEBUG_MERGE
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"


void main() {
	gl_Position = ftransform();
}
