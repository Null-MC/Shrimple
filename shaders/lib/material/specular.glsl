float GetMaterialF0(const in float metal_f0) {
    return metal_f0 > 0.5 ? 0.96 : 0.04;
}
