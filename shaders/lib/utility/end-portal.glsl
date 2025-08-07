#define PORTAL_LAYERS 16

const vec3[] COLORS = vec3[](
    vec3(0.022087, 0.098399, 0.110818),
    vec3(0.011892, 0.095924, 0.089485),
    vec3(0.027636, 0.101689, 0.100326),
    vec3(0.046564, 0.109883, 0.114838),
    vec3(0.064901, 0.117696, 0.097189),
    vec3(0.063761, 0.086895, 0.123646),
    vec3(0.084817, 0.111994, 0.166380),
    vec3(0.097489, 0.154120, 0.091064),
    vec3(0.106152, 0.131144, 0.195191),
    vec3(0.097721, 0.110188, 0.187229),
    vec3(0.133516, 0.138278, 0.148582),
    vec3(0.070006, 0.243332, 0.235792),
    vec3(0.196766, 0.142899, 0.214696),
    vec3(0.047281, 0.315338, 0.321970),
    vec3(0.204675, 0.390010, 0.302066),
    vec3(0.080955, 0.314821, 0.661491));

const mat4 SCALE_TRANSLATE = mat4(
    0.5, 0.0, 0.0, 0.25,
    0.0, 0.5, 0.0, 0.25,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0);

mat4 end_portal_layer(float layer) {
    float time = frameTimeCounter * 0.001;

    mat4 translate = mat4(
        1.0, 0.0, 0.0, 17.0 / layer,
        0.0, 1.0, 0.0, (2.0 + layer / 1.5) * (time * 1.5),
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0);

    float _radians = radians((layer * layer * 4321.0 + layer * 9.0) * 2.0);

    mat2 rotate = mat2(
        cos(_radians), -sin(_radians),
        sin(_radians), cos(_radians)
    );

    mat2 scale = mat2((4.5 - layer / 4.0) * 2.0);

    return mat4(scale * rotate) * translate * SCALE_TRANSLATE;
}

vec3 render_endPortal(const in vec4 texProj0) {
    #define Sampler0 gtexture
    #define Sampler1 gtexture

    vec3 color = textureProj(Sampler0, texProj0).rgb * COLORS[0];

    for (int i = 0; i < PORTAL_LAYERS; i++) {
        color += textureProj(Sampler1, texProj0 * end_portal_layer(i + 1)).rgb * COLORS[i];
    }

    return color;
}
