#define RENDER_PREPARE
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"


void main() {
	gl_Position = ftransform();
}
