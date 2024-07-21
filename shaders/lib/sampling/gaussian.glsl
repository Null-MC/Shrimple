float Gaussian(const in float sigma, const in float x) {
    // return exp(-_pow2(x) / (2.0 * _pow2(sigma)));
    return 0.39894 * exp(-0.5 * _pow2(x) / _pow2(sigma)) / sigma;
}

vec3 Gaussian(const in float sigma, const in vec3 x) {
    return exp(-_pow2(x) / (2.0 * _pow2(sigma)));
}
