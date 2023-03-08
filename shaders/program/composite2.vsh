#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"


void main() {
	gl_Position = ftransform();
}
