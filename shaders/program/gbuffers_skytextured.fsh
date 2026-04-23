#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
} vIn;


#ifdef WORLD_OVERWORLD
    uniform sampler2D texSkyTransmit;
#endif

uniform sampler2D gtexture;

uniform vec3 cameraPosition;
uniform float rainStrength;
uniform int renderStage;
uniform vec2 viewSizeScaled;

#ifdef WORLD_OVERWORLD
    #include "/lib/sky-transmit.glsl"
#endif

#if OVERWORLD_SKY == SKY_ENHANCED
    const float SunMultiplyF = 16.0;
#else
    const float SunMultiplyF = 8.0;
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    #if RENDER_SCALE != 0
        ivec2 uv = ivec2(gl_FragCoord.xy);
        if (any(greaterThan(uv, viewSizeScaled))) return;
    #endif

    vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;
    color.rgb = RGBToLinear(color.rgb);

    #ifdef WORLD_OVERWORLD
        if (renderStage == MC_RENDER_STAGE_SUN) {
            color.rgb *= SunMultiplyF;
        }

        #if OVERWORLD_SKY == SKY_ENHANCED
            vec3 localViewDir = normalize(vIn.localPos);
            color.rgb *= sampleSkyTransmit(cameraPosition.y, localViewDir.y);

            color.rgb *= 1.0 - rainStrength;
        #endif
    #endif

    #ifdef WORLD_END
        color.rgb *= 0.05;
    #endif

    outFinal = color;
}
