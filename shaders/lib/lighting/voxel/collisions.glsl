bool BoxRayTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 t1 = (boxMin - rayStart) * rayInv;
    vec3 t2 = (boxMax - rayStart) * rayInv;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float rmin = maxOf(tmin);
    float rmax = minOf(tmax);

    if (rmin >= 1.0) return false;

    return !isinf(rmin) && rmax >= max(rmin, 0.0);
}

bool BoxPointTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 point) {
    return all(greaterThanEqual(point, boxMin)) && all(lessThanEqual(point, boxMax));
}

bool CylinderRayTest(const in vec3 rayOrigin, const in vec3 rayVec, const in float radius, const in float height) {
    float rayLen = length(rayVec);
    vec3 rayDir = rayVec / max(rayLen, EPSILON);

    float k2 = 1.0 - _pow2(rayDir.y);
    float k1 = dot(rayOrigin, rayDir) - rayOrigin.y*rayDir.y;
    float k0 = length2(rayOrigin) - _pow2(rayOrigin.y) - _pow2(radius);
    
    float h = k1*k1 - k2*k0;
    if (h < 0.0) return false;

    h = sqrt(h);
    float t = (-k1 - h) / k2;

    float y = rayOrigin.y + t*rayDir.y;
    if (y > -height && y < height) return t > 0.0 && t < rayLen;
    
    t = (((y < 0.0) ? -height : height) - rayOrigin.y) / rayDir.y;
    if (abs(k1 + k2*t) < h) return t > 0.0 && t < rayLen;

    return false;
}

bool TraceHitTest(const in uint blockId, const in vec3 rayStart, const in vec3 rayInv) {
    uint shapeCount = CollissionMaps[blockId].Count;

    bool hit = false;
    for (uint i = 0u; i < BLOCK_MASK_PARTS; i++) {
        if (i >= shapeCount || hit) break;

        uvec2 shapeBounds = CollissionMaps[blockId].Bounds[i];
        vec3 boundsMin = unpackUnorm4x8(shapeBounds.x).xyz;
        vec3 boundsMax = unpackUnorm4x8(shapeBounds.y).xyz;

        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
            hit = BoxPointTest(boundsMin, boundsMax, rayStart);
        #else
            hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
        #endif
    }

    return hit;
}
