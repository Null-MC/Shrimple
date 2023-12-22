vec4 GetLightningDirectionStrength(const in vec3 localPos) {
    vec3 lightningOffset = lightningPosition - cameraPosition;
    lightningOffset.y = clamp(localPos.y, lightningOffset.y, cloudHeight - cameraPosition.y + 0.5*CloudHeight);
    lightningOffset -= localPos;

    float lightningDist = length(lightningOffset);
    float att = max(1.0 - lightningDist * LightningRangeInv, 0.0);

    vec3 lightningDir = lightningOffset / lightningDist;
    //float lightningNoLm = max(dot(lightningDir, texNormal), 0.0);
    //diffuse += lightningNoLm * lightningStrength * LightningBrightness * pow5(att);
    return vec4(lightningDir, lightningStrength * LightningBrightness * pow5(att));
}
