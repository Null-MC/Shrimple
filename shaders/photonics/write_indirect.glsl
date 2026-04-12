layout(rgba16f) uniform writeonly image2D imgPhotonicsIndirect;


void write_indirect(vec3 color) {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    imageStore(imgPhotonicsIndirect, uv, vec4(color, 1.0));
}
