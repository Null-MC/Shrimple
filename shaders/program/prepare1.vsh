#define RENDER_PREPARE
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"


void main() {
	gl_Position = ftransform();
}
