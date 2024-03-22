#define RENDER_SHADOW
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 texcoord;
    vec4 color;

    flat uint blockId;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vIn;

uniform sampler2D gtexture;

uniform int renderStage;

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#include "/lib/blocks.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        vec2 p = gl_FragCoord.xy / shadowMapSize - vIn.shadowTilePos;
        if (clamp(p, vec2(0.0), vec2(0.5)) != p) discard;
    #endif

    vec4 color = texture(gtexture, vIn.texcoord);

    float alphaF = renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
        ? (1.5/255.0) : alphaTestRef;

    if (color.a < alphaF) {
        discard;
        return;
    }

    color.rgb *= vIn.color.rgb;

    #if defined SHADOW_COLORED && defined SHADOW_COLOR_BLEND
        color.rgb = RGBToLinear(color.rgb);
        color.rgb = mix(color.rgb, vec3(1.0), _pow2(color.a));
        color.rgb = LinearToRGB(color.rgb);
    #endif

    if (vIn.blockId == BLOCK_WATER)
        color = vec4(0.90, 0.94, 0.96, 0.0);
    
    outColor0 = color;
}
