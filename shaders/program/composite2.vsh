#define RENDER_COMPOSITE_LIGHTS
#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

#if DYN_LIGHT_TEMPORAL > 2
	flat out vec2 vOffset;
#endif

uniform int frameCounter;

#if DYN_LIGHT_TEMPORAL > 2
	uniform mat4 gbufferModelView;
	uniform mat4 gbufferProjection;
	uniform vec3 cameraPosition;

	#include "/lib/buffers/lighting.glsl"
#endif


void main() {
	gl_Position = ftransform();

	#if DYN_LIGHT_TEMPORAL > 2
		int i = int(mod(frameCounter, 4));
		vOffset.x = mod(i, 2);
		vOffset.y = floor(i / 2.0);

		gl_Position.xy = gl_Position.xy * 0.5 + vOffset - 0.5;

		lightCameraPosition[i] = cameraPosition;
		gbufferLightModelView[i] = gbufferModelView;
		gbufferLightProjection[i] = gbufferProjection;
	#endif
}
