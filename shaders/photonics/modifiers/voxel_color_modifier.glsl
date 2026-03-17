void voxel_color_modifier(inout vec4 color, inout vec3 position, inout ivec3 block_position) {
    color.rgb = RGBToLinear(color.rgb);
}
