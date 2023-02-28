#define RENDER_ARMOR_GLINT
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;


void main() {
	//use same transforms as entities and hand to avoid z-fighting issues
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}
