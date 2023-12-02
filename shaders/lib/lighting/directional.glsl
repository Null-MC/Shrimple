void ApplyDirectionalLightmap(inout float blockLight, const in vec3 viewPos, const in vec3 geoViewNormal, const in vec3 texViewNormal) {
    vec3 dFdViewposX = dFdx(viewPos);
    vec3 dFdViewposY = dFdy(viewPos);

    vec2 dFdTorch = vec2(dFdx(blockLight), dFdy(blockLight));

    float blockLightNew = 0.0;
    if (dot(dFdTorch, dFdTorch) > 1.0e-10) {
        vec3 torchLightViewDir = normalize(dFdViewposX * dFdTorch.x + dFdViewposY * dFdTorch.y);
        float f = dot(torchLightViewDir, texViewNormal);
        blockLightNew = saturate(f + 0.6) * 0.8 + 0.2;
    }
    else {
        float f = dot(geoViewNormal, texViewNormal);
        blockLightNew = saturate(f)*0.8;
    }

    blockLightNew *= blockLight;

    blockLight = blockLight * 0.8 + blockLightNew * 0.8;

    blockLight = saturate(blockLight / 1.5);
}
