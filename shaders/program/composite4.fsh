#define RENDER_OPAQUE_SSAO
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform usampler2D BUFFER_DEFERRED_DATA;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/lighting/ssao.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = textureLod(depthtex1, texcoord, 0).r;
    vec4 final = vec4(1.0);

    if (depth < 1.0) {
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        #ifdef DEFERRED_BUFFER_ENABLED
            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(gl_FragCoord.xy), 0);
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texViewNormal = deferredTexture.rgb;

            if (any(greaterThan(texViewNormal, EPSILON3))) {
                texViewNormal = normalize(texViewNormal * 2.0 - 1.0);
                texViewNormal = mat3(gbufferModelView) * texViewNormal;
            }
        #else
            vec3 texViewNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
        #endif

        float occlusion = GetSpiralOcclusion(texcoord, viewPos, texViewNormal);

        //float distF = smoothstep(-1.0, 1.0, length(viewPos));
        final.a = 1.0 - occlusion;// * distF;
    }

    outAO = final;
}
