void GetVanillaLighting(out vec3 diffuse, in vec2 lmcoord, const in vec3 shadowColor, const in float occlusion) {//, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    #if LIGHTING_MODE == LIGHTING_MODE_NONE
        #ifdef RENDER_SHADOWS_ENABLED
            float shadowF = luminance(shadowColor);
            lmcoord.y *= saturate(shadowF); // WARN: fix scaling!
        #endif

        vec3 lightmapFinal = textureLod(lightmap, LightMapTex(lmcoord), 0).rgb;
        diffuse = RGBToLinear(lightmapFinal);
    #else
        vec3 lightmapBlock = _pow3(lmcoord.x) * blackbody(LIGHTING_TEMP);
        diffuse = lightmapBlock * Lighting_Brightness;
    #endif

    diffuse *= occlusion;
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, in vec3 specular, const in float metal_f0, const in float roughL, const in float emission, const in float occlusion) {
    vec3 diffuseFinal = diffuse;
    diffuseFinal += Lighting_MinF * occlusion;
    diffuseFinal += emission * MaterialEmissionF;

	return fma(albedo, diffuseFinal, specular);
}
