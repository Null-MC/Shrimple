#define RENDER_BEACONBEAM
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec3 vLocalPos;

uniform mat4 gbufferModelViewInverse;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vLocalPos = (gbufferModelViewInverse * viewPos).xyz;
}
