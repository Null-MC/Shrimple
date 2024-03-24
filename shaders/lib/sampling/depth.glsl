float linearizeDepth(const in float clipDepth, const in float zNear, const in float zFar) {
    float ndcDepth = clipDepth * 2.0 - 1.0;
    return 2.0 * zNear * zFar / (zFar + zNear - ndcDepth * (zFar - zNear));
}

float linearizeDepthFast(const in float depth, const in float near, const in float far) {
    return (near * far) / (depth * (near - far) + far);
}

vec3 linearizeDepthFast3(const in vec3 depth, const in float near, const in float far) {
    return (near * far) / (depth * (near - far) + far);
}

float delinearizeDepth(const in float linearDepth, const in float near, const in float far) {
    return 4.0 * far * (1.0 - near / linearDepth) / (far - near);
}

// float delinearizeDepthFast(const in float linearDepth, const in float near, const in float far) {
//     return 4.0 * far * (1.0 - near / linearDepth) / (far - near);
// }
