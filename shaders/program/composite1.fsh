#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

#ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
	uniform sampler2D texLightMap;
#else
	uniform sampler2D colortex3;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform vec3 upPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindness;

#if MC_VERSION >= 11700
	uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bilateral_gaussian.glsl"

#include "/lib/world/fog.glsl"
#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
	ivec2 iTex = ivec2(gl_FragCoord.xy);
	vec4 color = texelFetch(colortex0, iTex, 0);
	float depth = texelFetch(depthtex0, iTex, 0).r;
	vec4 final;

	if (depth < 1.0) {
		vec4 lightMap = texelFetch(colortex2, iTex, 0);
		
		vec2 viewSize = vec2(viewWidth, viewHeight);
		float linearDepth = linearizeDepthFast(depth, near, far);

		float sigmaV = 3.0 / linearDepth;

		#if SHADOW_COLORS == SHADOW_COLOR_ENABLED
			vec3 lightColor = BilateralGaussianDepthBlurRGB_5x(texcoord, colortex1, viewSize, depthtex0, viewSize, linearDepth, sigmaV);
		#else
			vec3 lightColor = vec3(BilateralGaussianDepthBlur_5x(texcoord, colortex1, viewSize, depthtex0, viewSize, linearDepth, sigmaV));
		#endif

		vec3 clipPos = vec3(gl_FragCoord.xy / viewSize, depth) * 2.0 - 1.0;
		vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
		vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
		final = GetFinalLighting(color, lightColor, localPos, lightMap.xy, lightMap.z);
	}
	else {
		final = vec4(color.rgb, 1.0);
	}

	outColor0 = final;
}
