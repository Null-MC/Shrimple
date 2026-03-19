#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_TRANSLUCENT_FINAL;
uniform sampler2D TEX_TRANSLUCENT_TINT;

#ifdef REFRACT_ENABLED
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    uniform sampler2D TEX_NORMAL;
#endif

uniform mat4 gbufferModelView;
uniform float viewWidth;
uniform float viewHeight;
uniform float nearPlane;
uniform float farPlane;

#ifdef REFRACT_ENABLED
    #include "/lib/sampling/depth.glsl"
    #include "/lib/octohedral.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec3 tint = texelFetch(TEX_TRANSLUCENT_TINT, uv, 0).rgb;
    vec4 color = texelFetch(TEX_TRANSLUCENT_FINAL, uv, 0);

    #ifdef REFRACT_ENABLED
        float depthOpaque = texelFetch(depthtex1, uv, 0).r;
        float depthTranslucent = texelFetch(depthtex0, uv, 0).r;
        vec4 normalData = texelFetch(TEX_NORMAL, uv, 0);

        vec2 coord = texcoord;
        if (depthTranslucent < depthOpaque) {
            const float eta = 1.0 / 1.33;
            vec3 geoLocalNormal = OctDecode(normalData.xy);
            vec3 texViewNormal = OctDecode(normalData.zw);
            vec3 geoViewNormal = mat3(gbufferModelView) * geoLocalNormal;
            texViewNormal = normalize(texViewNormal*1.02 - geoViewNormal);

            vec3 refractViewDir = refract(vec3(0.0, 0.0, 1.0), texViewNormal, eta);
            refractViewDir = normalize(refractViewDir);

            float depthNearL = linearizeDepth(depthTranslucent * 2.0 - 1.0, nearPlane, farPlane);
            float depthFarL = linearizeDepth(depthOpaque * 2.0 - 1.0, nearPlane, farPlane);
            float depthL = 0.06 * (depthFarL - depthNearL);

            vec2 refract_uv = refractViewDir.xy * depthL;
            refract_uv /= max(length(refract_uv), 1.0);

            coord += refract_uv * 0.02 * vec2(viewWidth / viewHeight, 1.0);
        }

        vec3 src = texture(TEX_FINAL, coord).rgb;
    #else
        vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    #endif

    outFinal = mix(src * normalize(RGBToLinear(tint)), color.rgb, color.a);
}
