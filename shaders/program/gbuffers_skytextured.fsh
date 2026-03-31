#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    flat int faceIndex;
    flat uint uv_min;
} vIn;

layout(rgba16f) uniform writeonly image2D colorimg7;


#ifndef WORLD_END
    uniform sampler2D texSkyTransmit;
#endif

uniform sampler2D gtexture;

uniform vec3 cameraPosition;
uniform float rainStrength;
uniform int renderStage;
uniform vec2 viewSize;

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

    if (vIn.faceIndex < 0) {
        outFinal = color;
    }
    else {
        ivec2 uv = ivec2(gl_FragCoord.xy);

        ivec2 uv_min = ivec2(unpackUnorm2x16(vIn.uv_min) * viewSize + 0.5);
        ivec2 uv_max = uv_min + ivec2(viewSize)/ivec2(3,2);

        if (all(greaterThanEqual(uv, uv_min)) && all(lessThan(uv, uv_max)))
            imageStore(colorimg7, uv, color);

        discard;
    }
}
