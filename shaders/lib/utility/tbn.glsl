mat3 GetLocalTBN(const in vec3 localNormal, const in vec3 localTangent, const in float tangentW) {
    vec3 localBinormal = normalize(cross(localTangent, localNormal) * tangentW);
    return mat3(localTangent, localBinormal, localNormal);
}

mat3 GetViewTBN(const in vec3 viewNormal, const in vec3 viewTangent, const in float tangentW) {
    vec3 viewBinormal = normalize(cross(viewTangent, viewNormal) * tangentW);
    return mat3(viewTangent, viewBinormal, viewNormal);
}
