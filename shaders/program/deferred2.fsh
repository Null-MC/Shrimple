#define RENDER_OPAQUE_SSAO
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/effects/ssao.glsl"


/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = textureLod(depthtex1, texcoord, 0).r;
    float occlusion = 0.0;

    if (depth < 1.0) {
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        vec3 texViewNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));

        occlusion = GetSpiralOcclusion(texcoord, viewPos, texViewNormal);
    }

    outAO = vec4(vec3(occlusion), 1.0);
}
