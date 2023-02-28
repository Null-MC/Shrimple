#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

out vec2 texcoord;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
	uniform float near;
	uniform float far;

	#include "/lib/shadows/cascaded.glsl"
#endif


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
