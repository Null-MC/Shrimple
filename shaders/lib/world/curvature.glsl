// vec3 GetWorldCurvedPosition(in vec3 position) {
//     // horizon-stretching fix by cr0420
//     position.xz *= 1.0 + length2(position.xz) / _pow2(WORLD_CURVE_RADIUS) * 0.25;

//     position.y += WORLD_CURVE_RADIUS;
//     position = normalize(position) * position.y;
//     position.y -= WORLD_CURVE_RADIUS;
// }

float GetWorldAltitude(in vec3 localPos) {
    localPos.y += World_CurveRadius + cameraPosition.y;
    return length(localPos) - World_CurveRadius;
}

// by cr0420
vec3 GetWorldCurvedPosition(in vec3 localPos) {
    const float WorldCurveRadiusInv = rcp(World_CurveRadius);

    vec3 angle = vec3(localPos.x, length(localPos.xz), localPos.z) * WorldCurveRadiusInv;
    float planetHeight = localPos.y + World_CurveRadius;
    
    localPos.y  = cos(angle.y) * planetHeight - World_CurveRadius;
    localPos.xz = sin(angle.xz) * planetHeight;

    return localPos;
}
