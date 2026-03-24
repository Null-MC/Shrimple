vec3 GetHandLightPosition() {
    return firstPersonCamera ? vec3(0.0) : -relativeEyePosition;
}

float GetHandDistance(const in vec3 localPos) {
    vec3 handLocalPos = GetHandLightPosition();
    return distance(localPos, handLocalPos);
}
