void modify_restir_gi(inout vec3 color) {
    #ifdef PHOTONICS_SPECULAR_ENABLED
        #ifdef DEBUG_WHITEWORLD
            vec3 albedo = vec3(0.86);
        #else
            ivec2 uv = ivec2(gl_FragCoord.xy);
            vec3 albedo = texelFetch(TEX_GB_COLOR, uv, 0).rgb;
            albedo = RGBToLinear(albedo);
        #endif

        color *= albedo/PI;
    #endif
}
