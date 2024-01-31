// #if LPV_SIZE > 0 && LPV_SHADOW_SAMPLES > 0
//     vec3 GetLpvAmbient(const in vec3 lpvPos, const in vec3 normal) {
//         vec3 lpvLight = SampleLpv(lpvPos, normal).rgb;
//         //lpvLight = log2(lpvLight + EPSILON) / LpvRangeF;
//         lpvLight *= 0.1;
//         lpvLight /= (lpvLight + 2.0);
//         //lpvLight *= DynamicLightAmbientF;
//         return lpvLight;
//     }
// #endif

void GetVanillaLighting(out vec3 diffuse, const in vec2 lmcoord, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    vec2 lmFinal = lmcoord;

    lmFinal = LightMapTex(lmFinal);

    vec3 lightmapBlock = textureLod(TEX_LIGHTMAP, vec2(lmFinal.x, lmCoordMin), 0).rgb;
    lightmapBlock = RGBToLinear(lightmapBlock) * blackbody(LIGHTING_TEMP);
    // TODO: just ditch lightmap and use blackbody temp?

    diffuse = lightmapBlock * DynamicLightBrightness;

    // #if LPV_SIZE > 0 && LPV_SHADOW_SAMPLES > 0
    //     vec3 lpvPos = GetLPVPosition(localPos);
    //     float lpvFade = GetLpvFade(lpvPos);
    //     lpvFade = _smoothstep(lpvFade);

    //     vec3 lpvLight = GetLpvAmbient(lpvPos, localNormal);
    //     diffuse += lpvLight * lpvFade;
    // #endif
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

	final *= (WorldMinLightF + diffuse) * occlusion + emission * MaterialEmissionF;
	final += specular;

	return final;
}
