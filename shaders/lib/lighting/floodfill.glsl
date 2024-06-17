void GetFloodfillLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec2 lmcoord, const in vec3 shadowColor, const in vec3 albedo, const in float metal_f0, const in float roughL, const in float occlusion, const in float sss, const in bool tir) {
    vec2 lmBlockFinal = LightMapTex(vec2(lmcoord.x, 0.0));
    vec3 lmBlockLight = textureLod(TEX_LIGHTMAP, lmBlockFinal, 0).rgb;
    lmBlockLight = RGBToLinear(lmBlockLight);

    vec3 localViewDir = normalize(localPos);

    vec3 lpvPos = GetLPVPosition(localPos);

    #ifdef RENDER_GBUFFER
        lpvPos += GetLPVFrameOffset();
    #endif

    if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) == lpvPos) {
        // vec3 surfaceNormal = localNormal;

        // if (!all(lessThan(abs(texNormal), EPSILON3))) {
        //     surfaceNormal = normalize(localNormal + texNormal);
        // }

        vec4 lpvSample = SampleLpv(lpvPos, localNormal, texNormal);
        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = _smoothstep(lpvFade);
        //lpvFade *= 1.0 - Lpv_LightmapMixF;

        vec3 lpvLight = GetLpvBlockLight(lpvSample);
        blockDiffuse += mix(lmBlockLight, lpvLight, lpvFade);
    }
    else {
        blockDiffuse += lmBlockLight;
    }
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        vec3 final = vec3(WHITEWORLD_VALUE);
    #else
        vec3 final = albedo;
    #endif

    return final * (Lighting_MinF * occlusion + diffuse) + specular * _pow3(occlusion);
}
