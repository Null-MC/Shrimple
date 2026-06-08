#define VOXEL_COLOR_MODIFIER_SIMPLE

void voxel_color_modifier(inout vec4 color) {
    color.rgb = RGBToLinear(color.rgb);
}
