#define RENDER_BEACONBEAM
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec3 vLocalPos;

uniform mat4 gbufferModelViewInverse;

#if WORLD_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vLocalPos = (gbufferModelViewInverse * viewPos).xyz;
}
