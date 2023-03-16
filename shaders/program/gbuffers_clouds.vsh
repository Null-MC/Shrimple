#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out vec4 vColor;
out float vDist;


void main() {
    gl_Position = ftransform();
    vColor = gl_Color;

    vec3 viewPos = (gl_ModelViewMatrix * vec4(gl_Vertex.x, 0.0, gl_Vertex.z, 1.0)).xyz;
    vDist = length(viewPos);
}
