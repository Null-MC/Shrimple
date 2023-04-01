float linearizeDepth(const in float ndcDepth, const in float near, const in float far) {
    // Convert depth back to NDC depth
    //float ndcDepth = depth * 2 - 1;
    return 2 * far * near / (far + near - ndcDepth * (far - near));
}

float delinearizeDepth(const in float linearDepth, const in float near, const in float far) {
    //float depth = 2 * far * near / (far + near - ndcDepth * (far - near));
    float depth = 4.0 * far * (1.0 - near / linearDepth) / (far - near);

    // Convert NDC depth back to clip depth
    return depth;// * 0.5 + 0.5;
}

float linearizeDepthFast(const in float depth, const in float near, const in float far) {
    return (near * far) / (depth * (near - far) + far);
}

float delinearizeDepthFast(const in float linearDepth, const in float near, const in float far) {
    return 4.0 * far * (1.0 - near / linearDepth) / (far - near);
}
