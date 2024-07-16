void GetVanillaLighting(out vec3 diffuse, in vec2 lmcoord, const in vec3 shadowColor, const in float occlusion) {//, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
        #ifdef RENDER_SHADOWS_ENABLED
            float shadowF = luminance(shadowColor);
            lmcoord.y *= shadowF; // WARN: fix scaling!
        #endif

        vec3 lightmapFinal = textureLod(TEX_LIGHTMAP, LightMapTex(lmcoord), 0).rgb;
        diffuse = RGBToLinear(lightmapFinal);
    #else
        vec3 lightmapBlock = _pow3(lmcoord.x) * blackbody(LIGHTING_TEMP);
        diffuse = lightmapBlock * Lighting_Brightness;
    #endif

    diffuse *= occlusion;
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, in vec3 specular, const in float metal_f0, const in float roughL, const in float emission, const in float occlusion) {
    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        vec3 final = vec3(WHITEWORLD_VALUE);
    #else
        vec3 final = albedo;
    #endif

	final *= (Lighting_MinF * occlusion + diffuse) + emission * MaterialEmissionF;
	final += specular;

	return final;
}
