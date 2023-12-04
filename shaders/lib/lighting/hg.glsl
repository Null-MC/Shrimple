float HG(const in float VoL, const in float G) {
    float G2 = _pow2(G);
    return phaseIso * ((1.0 - G2) / (pow(1.0 + G2 - (2.0 * G) * VoL, 1.5)));
}

float DHG(const in float VoL, const in float G_back, const in float G_forward, const in float direction) {
    float phaseBack = HG(VoL, G_back);
    float phaseForward = HG(VoL, G_forward);
    return mix(phaseBack, phaseForward, direction);
}
