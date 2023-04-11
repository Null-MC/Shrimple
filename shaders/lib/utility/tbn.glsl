mat3 GetLocalTBN(const in vec3 localNormal, const in vec3 localTangent) {
    vec3 localBinormal = normalize(cross(localTangent, localNormal) * vTangentW);
    return mat3(localTangent, localBinormal, localNormal);
}

mat3 GetViewTBN(const in vec3 viewNormal, const in vec3 viewTangent) {
    vec3 viewBinormal = normalize(cross(viewTangent, viewNormal) * vTangentW);
    return mat3(viewTangent, viewBinormal, viewNormal);
}
