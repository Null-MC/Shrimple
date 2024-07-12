#define RENDER_BEACONBEAM
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
	vec4 color;
	vec3 localPos;
	vec2 texcoord;
} vOut;

uniform vec2 pixelSize;
uniform int frameCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
	gl_Position = ftransform();
	vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vOut.color = gl_Color;

	#if LIGHTING_MODE != LIGHTING_MODE_NONE //&& defined DEFERRED_BUFFER_ENABLED
		vOut.color.rgb = normalize(vOut.color.rgb);
	#endif

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
