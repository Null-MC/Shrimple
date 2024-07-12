void GetVanillaLighting(out vec3 diffuse, const in vec2 lmcoord) {//, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
        vec3 lightmapFinal = textureLod(TEX_LIGHTMAP, LightMapTex(lmcoord), 0).rgb;
        diffuse = RGBToLinear(lightmapFinal);// * blackbody(LIGHTING_TEMP);
    #else
        vec3 lightmapBlock = _pow3(lmcoord.x) * blackbody(LIGHTING_TEMP);
        diffuse = lightmapBlock * Lighting_Brightness;
    #endif
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, in vec3 specular, const in float metal_f0, const in float roughL, const in float emission, const in float occlusion) {
    #if MATERIAL_SPECULAR != SPECULAR_NONE
        #if MATERIAL_SPECULAR == SPECULAR_LABPBR
            float metalF = IsMetal(metal_f0) ? 1.0 : 0.0;
        #else
            float metalF = metal_f0;
        #endif

        diffuse *= mix(1.0, MaterialMetalBrightnessF, metalF * (1.0 - _pow2(roughL)));
        specular *= GetMetalTint(albedo, metal_f0);
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        vec3 final = vec3(WHITEWORLD_VALUE);
    #else
        vec3 final = albedo;
    #endif

	final *= (Lighting_MinF + diffuse) * occlusion + emission * MaterialEmissionF;
	final += specular;

	return final;
}
