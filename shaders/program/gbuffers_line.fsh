#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in VertexData {
    flat uint color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 cameraPosition;
uniform float alphaTestRef;
uniform int renderStage;

#include "/lib/sampling/lightmap.glsl"


#include "_output.glsl"

void main() {
    vec4 color = unpackUnorm4x8(vIn.color);
    float emission = 0.0;

    if (renderStage == MC_RENDER_STAGE_OUTLINE) {
        const vec3 outlineColor = pow(vec3(BLOCK_OUTLINE_COLOR_R, BLOCK_OUTLINE_COLOR_G, BLOCK_OUTLINE_COLOR_B) / 255.0, vec3(2.2));

        #if BLOCK_OUTLINE_TYPE == BLOCK_OUTLINE_CONSTRUCTION
            const float interval = 16.0;
            vec3 worldPos = vIn.localPos + cameraPosition;
            float offset = sumOf(worldPos) * interval;
            color.rgb = step(1.0, mod(offset, 2.0)) * outlineColor;
        #else
            color.rgb = outlineColor;
        #endif

        color.a = 1.0;
        emission = BLOCK_OUTLINE_EMISSION;
    }
    else {
        color *= texture(gtexture, vIn.texcoord);
    }

    if (color.a < alphaTestRef) {discard; return;}

    color.rgb = RGBToLinear(color.rgb);

    vec4 final = color;

    vec2 lmFinal = LightMapTex(vIn.lmcoord);
    vec3 lightmap = RGBToLinear(texture(lightmap, lmFinal).rgb);
    final.rgb *= lightmap + emission;

    // TODO: fog?

    outFinal = final;

    #ifdef RENDER_TRANSLUCENT
        outTint = vec3(1.0);
    #endif

    #ifdef DEFERRED_NORMAL_ENABLED
        outNormal = uvec2(0u);
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outAlbedoSpecular = uvec2(0u);
    #endif
}
