float GetShadowNormalBias(const in float geoNoL) {
    return 0.02 * max(1.0 - geoNoL, 0.0) * SHADOW_BIAS_SCALE;
}

float GetShadowOffsetBias() {
    return (0.00004 * SHADOW_BIAS_SCALE);
}

// euclidian distance is defined as sqrt(a^2 + b^2 + ...)
// this length function instead does cbrt(a^3 + b^3 + ...)
// this results in smaller distances along the diagonal axes.

float cubeLength(const in vec2 v) {
	return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
}

float getDistortFactor(const in vec2 v) {
	return cubeLength(v) + SHADOW_DISTORT_FACTOR;
}

vec3 distort(const in vec3 v, const in float factor) {
	return vec3(v.xy / factor, v.z);
}

vec3 distort(const in vec3 v) {
	return distort(v, getDistortFactor(v.xy));
}

#if defined RENDER_VERTEX && !defined RENDER_SHADOW
	// out vec3 cloudPos;
	// uniform float cloudTime;
	// #if defined RENDER_BASIC || defined RENDER_TEXTURED || defined RENDER_CLOUDS || defined RENDER_PARTICLES || defined RENDER_WEATHER
	// 	uniform vec3 eyePosition;
	// #endif

	// void ApplyCloudShadows(const in vec3 localPos) {
	// 	vec2 cloudOffset = vec2(-cloudTime/12.0, 0.33);
	// 	cloudOffset = mod(cloudOffset, vec2(256.0));
	// 	cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

	// 	const float irisCamWrap = 1024.0;
	// 	vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
	// 	camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
	// 	vec3 vertexWorldPos = localPos + mod(eyePosition, 3072.0) + camOffset; // 3072 is one full cloud pattern
	// 	float cloudHeightDifference = 192.2 - vertexWorldPos.y;

	// 	#ifdef IRIS_FEATURE_SSBO
	// 		vec3 lightWorldDir = localSkyLightDirection;//mat3(gbufferModelViewInverse)*shadowLightPosition;
	// 	#else
    //         vec3 lightWorldDir = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
	// 	#endif

	// 	lightWorldDir /= lightWorldDir.y;
	// 	cloudPos = vec3((vertexWorldPos.xz + lightWorldDir.xz * cloudHeightDifference + vec2(0.0, 4.0))/12.0 - cloudOffset.xy, cloudHeightDifference);
	// 	cloudPos.xy *= 0.00390625;
	// }

	void ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL) {
        float bias = GetShadowNormalBias(geoNoL);

        float viewDist = 1.0;

        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            viewDist += length(localPos);
        #endif

        vec3 offsetLocalPos = localPos + localNormal * viewDist * bias;

        #ifndef IRIS_FEATURE_SSBO
			vec3 shadowViewPos = (shadowModelView * vec4(offsetLocalPos, 1.0)).xyz;
			shadowPos = (shadowProjection * vec4(shadowViewPos, 1.0)).xyz;
		#else
			shadowPos = (shadowModelViewProjection * vec4(offsetLocalPos, 1.0)).xyz;
		#endif

		#if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
			shadowPos = distort(shadowPos);
		#endif

		shadowPos = shadowPos * 0.5 + 0.5;

		ApplyCloudShadows(localPos);
	}
#endif
