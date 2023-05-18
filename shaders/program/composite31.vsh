#define RENDER_COMPOSITE_POST
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"


void main() {
	gl_Position = ftransform();
}
