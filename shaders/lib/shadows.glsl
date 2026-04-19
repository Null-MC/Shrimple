const float Shadow_DistortF = 0.08;


float GetShadowDistortionF(const in vec2 shadowScreenPos) {
    return length(shadowScreenPos) + Shadow_DistortF;
}

void distort(inout vec2 shadowScreenPos) {
    shadowScreenPos /= GetShadowDistortionF(shadowScreenPos);
}

float GetShadowBiasF(const in vec2 shadowScreenPos, const in float shadowViewNormalZ) {
    float distortF = GetShadowDistortionF(shadowScreenPos);
    distortF *= length(shadowScreenPos);

    return 4.0 * distortF * max(shadowViewNormalZ, 0.0);
}
