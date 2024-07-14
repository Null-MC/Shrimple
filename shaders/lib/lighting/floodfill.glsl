void GetFloodfillLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec2 lmcoord, const in vec3 shadowColor, const in vec3 albedo, const in float metal_f0, const in float roughL, const in float occlusion, const in float sss, const in bool tir) {
    vec3 lmBlockLight = (_pow3(lmcoord.x) * Lighting_Brightness) * blackbody(LIGHTING_TEMP);

    vec3 lpvPos = GetLPVPosition(localPos);

    #ifdef RENDER_GBUFFER
        lpvPos += GetLPVFrameOffset();
    #endif

    float lpvFade = 0.0;
    vec3 lpvLight = vec3(0.0);
    if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) == lpvPos) {
        vec3 samplePos = GetLpvSamplePos(lpvPos, localNormal, texNormal);
        vec4 lpvSample = SampleLpv(samplePos);
        lpvFade = GetLpvFade(lpvPos);
        lpvFade = _smoothstep(lpvFade);

        #ifdef LPV_AO_FIX
            vec4 lpvSampleN = SampleLpvNearest(ivec3(samplePos));
            lpvSampleN.rgb = RGBToLinear(lpvSampleN.rgb);
            lpvSample.rgb = max(lpvSample.rgb, 0.5 * lpvSampleN.rgb);
        #endif

        lpvLight = GetLpvBlockLight(lpvSample);
        // lpvLight = GetLpvBlockLight(lpvSample, lmcoord.x);
    }

    blockDiffuse += mix(lmBlockLight, lpvLight, lpvFade) * occlusion;
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        vec3 final = vec3(WHITEWORLD_VALUE);
    #else
        vec3 final = albedo;
    #endif

    return final * (Lighting_MinF * occlusion + diffuse) + specular * _pow3(occlusion);
}
