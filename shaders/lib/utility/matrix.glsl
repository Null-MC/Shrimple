mat4 BuildOrthoProjectionMatrix(const in float width, const in float height, const in float zNear, const in float zFar) {
    return mat4(
        vec4(2.0 / width, 0.0, 0.0, 0.0),
        vec4(0.0, 2.0 / height, 0.0, 0.0),
        vec4(0.0, 0.0, -2.0 / (zFar - zNear), 0.0),
        vec4(0.0, 0.0, -(zFar + zNear)/(zFar - zNear), 1.0));
}

mat4 BuildTranslationMatrix(const in vec3 delta) {
    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(delta, 1.0));
}

mat4 BuildScalingMatrix(const in vec3 scale) {
    return mat4(
        vec4(scale.x, 0.0, 0.0, 0.0),
        vec4(0.0, scale.y, 0.0, 0.0),
        vec4(0.0, 0.0, scale.z, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0));
}

mat3 rotateX(const in float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0,   c,  -s),
        vec3(0.0,   s,   c)
    );
}

mat3 rotateZ(const in float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat3(
        vec3(  c,  -s, 0.0),
        vec3(  s,   c, 0.0),
        vec3(0.0, 0.0, 1.0)
    );
}
