mat3 rotateX(const in float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0,   c,  -s),
        vec3(0.0,   s,   c)
    );
}

mat3 rotateY(const in float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat3(
        vec3(  c, 0.0,   s),
        vec3(0.0, 1.0, 0.0),
        vec3( -s, 0.0,   c)
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
