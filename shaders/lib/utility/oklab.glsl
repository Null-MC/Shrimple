vec3 LinearToLab(const in vec3 c) {
    const mat3 invB = mat3(
        0.4121656120,  0.2118591070,  0.0883097947,
        0.5362752080,  0.6807189584,  0.2818474174,
        0.0514575653,  0.1074065790,  0.6302613616);

    const mat3 invA = mat3(
         0.2104542553,  1.9779984951,  0.0259040371,
         0.7936177850, -2.4285922050,  0.7827717662,
        -0.0040720468,  0.4505937099, -0.8086757660);

    vec3 lms = invB * c;
    return invA * (sign(lms) * pow(abs(lms), vec3(1.0/3.0)));
}

vec3 LabToLinear(const in vec3 c) {
    const mat3 fwdA = mat3(
        1.0         ,  1.0         ,  1.0         ,
        0.3963377774, -0.1055613458, -0.0894841775,
        0.2158037573, -0.0638541728, -1.2914855480);

    const mat3 fwdB = mat3(
         4.0767245293, -1.2681437731, -0.0041119885,
        -3.3072168827,  2.6093323231, -0.7034763098,
         0.2307590544, -0.3411344290,  1.7068625689);

    vec3 lms = fwdA * c;
    return fwdB * _pow3(lms);
}

vec3 LabMixLinear(const in vec3 rgb_1, const in vec3 rgb_2, const in float factor) {
    vec3 lab_1 = LinearToLab(rgb_1);
    vec3 lab_2 = LinearToLab(rgb_2);

    vec3 lab_final = mix(lab_1, lab_2, factor);
    return LabToLinear(lab_final);
}
