#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"


#if DYN_LIGHT_TEMPORAL > 2
	flat in vec2 vOffset;
#endif

uniform sampler2D colortex4;
uniform sampler2D colortex5;

#if DYN_LIGHT_TEMPORAL > 2
	uniform sampler2D depthtex1;
#endif

uniform float frameTime;

#if DYN_LIGHT_TEMPORAL > 2
	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferPreviousProjection;
	uniform mat4 gbufferPreviousModelView;
	uniform vec3 previousCameraPosition;
	uniform vec3 cameraPosition;
	uniform float viewWidth;
	uniform float viewHeight;

	//uniform int frameCounter;
#endif


/* RENDERTARGETS: 5 */
layout(location = 0) out vec3 outColor0;

void main() {
	vec2 uv = gl_FragCoord.xy;

	#if DYN_LIGHT_TEMPORAL > 2
	    vec2 viewSize = vec2(viewWidth, viewHeight);
		uv -= vOffset * viewSize;
	#endif

	vec3 colorCurrent = texelFetch(colortex4, ivec2(uv), 0).rgb;

	// #if DYN_LIGHT_TEMPORAL > 2

    //     float depth = texelFetch(depthtex1, ivec2(uv), 0).r;

    //     vec3 clipPos = vec3(uv / viewSize, depth) * 2.0 - 1.0;
    //     vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
    //     vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    //     vec3 viewPosPrev = (gbufferPreviousModelView * vec4(worldPos - previousCameraPosition, 1.0)).xyz;
    //     vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));

    //     vec2 uv = clipPosPrev.xy * 0.5 - 0.5;
	// 	vec3 colorLast = texelFetch(colortex5, ivec2(uv * viewSize), 0).rgb;
	// 	colorCurrent = mix(colorLast, colorCurrent, 1.0);
	// #endif

	//float time = saturate(100.0 * frameTime);

	outColor0 = colorCurrent;
}
