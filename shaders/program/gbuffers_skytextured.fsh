#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in VertexData {
    vec4 color;
    vec2 texcoord;
} vIn;

uniform sampler2D gtexture;

uniform float rainStrength;
uniform int renderStage;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;


void main() {
    vec4 color = texture(gtexture, vIn.texcoord);

    color *= vIn.color;

    color.rgb = RGBToLinear(color.rgb);

    #if OVERWORLD_SKY == SKY_VANILLA
        if (renderStage == MC_RENDER_STAGE_SUN) {
            color.rgb *= 8.0;
        }

//        color = saturate(color);
    #endif

    #if OVERWORLD_SKY == SKY_ENHANCED
        if (renderStage == MC_RENDER_STAGE_SUN) {
            color.rgb *= 16.0;
        }

        color.rgb *= 1.0 - rainStrength;
    #endif

    outFinal = color;
}
