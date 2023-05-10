#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float viewHeight;
uniform float viewWidth;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float blindness;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec2 texcoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    
    vec3 clipPos = vec3(texcoord * 2.0 - 1.0, 1.0);
    vec3 viewPos = (gbufferProjectionInverse * vec4(clipPos, 1.0)).xyz;

    vec3 color;
    if (starData.a > 0.5) {
        color = starData.rgb;
    }
    else {
        vec3 viewDir = normalize(viewPos);
        float upF = dot(viewDir, gbufferModelView[1].xyz);
        color = GetFogColor(fogColor, upF);
    }

    color *= 1.0 - blindness;

    color = RGBToLinear(color);
    
    outFinal = vec4(color, 1.0);
}
