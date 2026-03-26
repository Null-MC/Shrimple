#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
} vIn;


#ifndef WORLD_END
    uniform sampler2D texSkyTransmit;
#endif

uniform sampler2D gtexture;

uniform vec3 cameraPosition;
uniform float rainStrength;
uniform int renderStage;

#ifndef WORLD_END
    #include "/lib/sky-transmit.glsl"
#endif


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

        #ifndef WORLD_END
//        if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON) {
            vec3 localViewDir = normalize(vIn.localPos);
            color.rgb *= sampleSkyTransmit(cameraPosition.y, localViewDir.y);
//        }
        #endif

        color.rgb *= 1.0 - rainStrength;
    #endif

    outFinal = color;
}
