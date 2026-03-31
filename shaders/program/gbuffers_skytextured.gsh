#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout(triangles) in;
layout(triangle_strip, max_vertices=18) out;

in VertexData {
    vec4 color;
    vec2 texcoord;
//    vec3 viewPos;
} vIn[];

out VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    flat int faceIndex;
    flat uint uv_min;
} vOut;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

#ifdef TAA_ENABLED
    uniform vec2 taa_offset = vec2(0.0);
#endif


void main() {
    vec3 localPos[3];

    for (int v = 0; v < 3; v++) {
        localPos[v] = mul3(gbufferModelViewInverse, gl_in[v].gl_Position.xyz);

        vOut.localPos = localPos[v];
        vOut.texcoord = vIn[v].texcoord;
        vOut.color = vIn[v].color;
        vOut.faceIndex = -1;

        gl_Position = gbufferProjection * gl_in[v].gl_Position;

        #ifdef TAA_ENABLED
            gl_Position.xy += taa_offset * (2.0 * gl_Position.w);
        #endif

        EmitVertex();
    }

    EndPrimitive();

    // cubemap panels
    const float _near = 1.0;
    const float _far = 150.0;
    const float _fov = 90.0;
    const float f = 1.0 / tan(radians(_fov)*0.5);

    const mat4 faceProjection = mat4(
        vec4(f, 0.0, 0.0, 0.0),
        vec4(0.0, f, 0.0, 0.0),
        vec4(0.0, 0.0, (_far+_near)/(_near-_far), -1.0),
        vec4(0.0, 0.0, (2.0*_far*_near)/(_near-_far), 0.0));

    mat3 faceView = mat3(1.0);

    for (int f = 4; f < 5; f++) {
        switch (f) {
            case 0:
                faceView[0] = vec3( 0, 0, 1);
                faceView[1] = vec3( 0, 1, 0);
                faceView[2] = vec3( 1, 0, 0);
                break;
            case 1:
                faceView[0] = vec3( 0, 0, 1);
                faceView[1] = vec3( 0, 1, 0);
                faceView[2] = vec3(-1, 0, 0);
                break;
            case 2:
                faceView[0] = vec3( 0, 0, 1);
                faceView[1] = vec3( 0, 1, 0);
                faceView[2] = vec3( 1, 0, 0);
                break;
            case 3:
                faceView[0] = vec3( 0, 0,-1);
                faceView[1] = vec3( 0, 1, 0);
                faceView[2] = vec3( 1, 0, 0);
                break;
            case 4: // up
                faceView[0] = vec3( 0, 0, 1);
                faceView[1] = vec3( 1, 0, 0);
                faceView[2] = vec3( 0,-1, 0);
                break;
//            case 5: // down
//                faceView[0].xyz = vec3( 1, 0, 0);
//                faceView[1].xyz = vec3( 0, 0,-1);
//                faceView[2].xyz = vec3( 0,-1, 0);
//                break;
        }

        for (int v = 0; v < 3; v++) {
            vOut.localPos = localPos[v];
            vOut.texcoord = vIn[v].texcoord;
            vOut.color = vIn[v].color;
            vOut.faceIndex = f;

            vec3 viewPos = faceView * localPos[v];
//            gl_Position = faceProjection * vec4(viewPos, 1.0);
            gl_Position.xyz = project(faceProjection, viewPos);
            gl_Position.w = 1.0;

            gl_Position.xy = gl_Position.xy*0.5 + 0.5;
            gl_Position.xy *= 1.0 / vec2(3.0, 2.0);

            // TODO: offset
            ivec2 offset = ivec2(f/2, f % 2);
            vec2 min = offset / vec2(3.0, 2.0);
            gl_Position.xy += min;

            gl_Position.xy = gl_Position.xy*2.0 - 1.0;

            vOut.uv_min = packUnorm2x16(min);

            EmitVertex();
        }

        EndPrimitive();
    }
}
