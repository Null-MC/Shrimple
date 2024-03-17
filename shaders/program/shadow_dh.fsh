#define RENDER_SHADOW_DH
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    float cameraViewDist;

    flat uint materialId;

    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vIn;

uniform int renderStage;
uniform float far;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        vec2 p = gl_FragCoord.xy / shadowMapSize - vIn.shadowTilePos;
        if (clamp(p, vec2(0.0), vec2(0.5)) != p) {discard; return;}
    #endif

    if (vIn.cameraViewDist < dh_clipDistF * far) {discard; return;}

    vec4 color = vIn.color;
    
    // if (vIn.materialId == DH_BLOCK_WATER)
    //     color = vec4(0.90, 0.0, 0.0, 0.0);

    #if defined SHADOW_COLORED && defined SHADOW_COLOR_BLEND
        color.rgb = mix(color.rgb, vec3(1.0), _pow2(color.a));
    #endif

    color.rgb = LinearToRGB(color.rgb);

    if (vIn.materialId == DH_BLOCK_WATER)
        color = vec4(0.90, 0.94, 0.96, 0.0);

    outColor0 = color;
}
