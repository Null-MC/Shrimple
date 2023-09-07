#define RENDER_DAMAGEDBLOCK
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;
in vec4 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;
out vec3 vLocalPos;
out vec2 vLocalCoord;
out vec3 vLocalNormal;
out vec3 vLocalTangent;
out float vTangentW;

flat out mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    out vec3 tanViewPos;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#include "/lib/sampling/atlas.glsl"
#include "/lib/utility/tbn.glsl"

#include "/lib/material/normalmap.glsl"

#include "/lib/lighting/basic.glsl"


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    BasicVertex();

    PrepareNormalMap();

    GetAtlasBounds(atlasBounds, vLocalCoord);

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent);

        vec3 viewPos = (gbufferModelView * vec4(vLocalPos, 1.0)).xyz;
        tanViewPos = viewPos * matViewTBN;
    #endif
}
