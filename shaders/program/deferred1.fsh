#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

//in vec2 texcoord;

uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

#include "/lib/sampling/depth.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outColor0;

void main() {
	ivec2 iTex = ivec2(gl_FragCoord.xy);
	float depth = texelFetch(depthtex0, iTex, 0).r;

	if (depth < 1.0) {
		vec2 viewSize = vec2(viewWidth, viewHeight);

		vec3 clipPos = vec3(gl_FragCoord.xy / viewSize, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

		vec3 blockLight = GetFinalBlockLighting(const in float lmcoordX);
	}
	else {
		final = vec4(0.0);
	}

	outColor0 = final;
}
