#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"


#if DYN_LIGHT_TEMPORAL > 2
	flat in vec2 vOffset;
#endif

uniform sampler2D depthtex1;
uniform sampler2D colortex4;

uniform float near;
uniform float far;

#if DYN_LIGHT_TEMPORAL > 2
	uniform float viewWidth;
	uniform float viewHeight;
#endif

#include "/lib/sampling/depth.glsl"


/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec2 uv = gl_FragCoord.xy - 0.5;

	#if DYN_LIGHT_TEMPORAL > 2
		uv -= vOffset * vec2(viewWidth, viewHeight);
	#endif

	vec3 colorCurrent = texelFetch(colortex4, ivec2(uv + 0.5), 0).rgb;
	float depth = texelFetch(depthtex1, ivec2(uv + 0.5), 0).r;
    float depthLinear = linearizeDepthFast(depth, near, far);

	outColor0 = vec4(colorCurrent, depthLinear);
}
