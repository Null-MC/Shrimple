void modify_restir_gi(inout vec3 color) {
    ivec2 uv = ivec2(gl_FragCoord.xy);

    uvec2 reflectData = texelFetch(TEX_ALBEDO_SPECULAR, uv, 0).rg;
    vec4 albedoData = unpackUnorm4x8(reflectData.r);
    vec4 specularData = unpackUnorm4x8(reflectData.g);
    vec3 albedo = RGBToLinear(albedoData.rgb);

    color *= albedo/PI;
}
