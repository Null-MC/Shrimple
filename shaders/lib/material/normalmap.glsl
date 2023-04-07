mat3 GetLocalTBN(const in vec3 localNormal, const in vec3 localTangent) {
    vec3 localBinormal = normalize(cross(localTangent, localNormal) * vTangentW);
    return mat3(localTangent, localBinormal, localNormal);
}

mat3 GetViewTBN(const in vec3 viewNormal, const in vec3 viewTangent) {
    vec3 viewBinormal = normalize(cross(viewTangent, viewNormal) * vTangentW);
    return mat3(viewTangent, viewBinormal, viewNormal);
}

#ifdef RENDER_VERTEX
    void PrepareNormalMap() {
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vLocalTangent = mat3(gbufferModelViewInverse) * viewTangent;

        //vTangentW = at_tangent.w;
    }
#endif

#ifdef RENDER_FRAG
    bool GetMaterialNormal(const in vec2 texcoord, inout vec3 normal) {
        bool valid = false;
        #if MATERIAL_NORMALS == NORMALMAP_LAB
            vec3 texNormal = texture(normals, texcoord).rgg;

            if (any(greaterThan(texNormal.rg, EPSILON2))) {
                normal.xy = texNormal.xy * 2.0 - 1.0;
                normal.z = sqrt(max(1.0 - dot(normal.xy, normal.xy), EPSILON));
                valid = true;
            }
        #elif MATERIAL_NORMALS == NORMALMAP_OLD
            vec3 texNormal = texture(normals, texcoord).rgb;

            if (any(greaterThan(texNormal, EPSILON3))) {
                normal = normalize(texNormal * 2.0 - 1.0);
                valid = true;
            }
        #endif

        return valid;
    }
#endif
