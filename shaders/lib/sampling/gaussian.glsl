float Gaussian(const in float sigma, const in float x) {
    return exp(-_pow2(x) / (2.0 * _pow2(sigma)));
}
