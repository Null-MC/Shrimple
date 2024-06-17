# Shrimple [shader]

A Minecraft Java shader that attempts to maintain a minimal "vanilla" aesthetic, while adding some optional features:
 - Waving Plants.
 - Rain puddles & ripples.
 - Volumetric fog lighting.
 - TAA / FXAA (anti-aliasing).
 - Normal / Specular Mapping (PBR).
 - POM (Parallax Occlusion Mapping).
 - Dynamic Soft Shadows / +Cascaded Shadow Mapping.
 - Dynamic Colored Lighting / +Ray-Traced block-light shadows.


## Mod Support
 - BigGlobe
 - Create
 - Create Deco
 - Distant Horizons
 - Maccaws Lights
 - PhysicsMod
 - Supplementaries


## FAQ
- **Q:** Why isn't block-lighting being ray traced?  
**A:** RT is off by default. Either change Block Light > Mode to "Traced", or apply the "RTX" profile.

- **Q:** How do I make colored/dynamic/traced shadows work further from player/camera?  
**A:** You can increase the Block Lighting > Advanced > Horizontal/Vertical Bin Counts. Increasing the Bin Size option will also help, but it will reduce the maximum "density" of light sources per area.

- **Q:** How do I make colored/dynamic/traced shadows faster?  
**A:** There are several options under Block Lighting > Advanced settings:
  - Reduce the Horizontal/Vertical Bin Counts to reduce the size of the light volume.
  - Reduce the Block Lighting > Advanced > Bin Size to use smaller bins (less blocks per bin).
  - Reduce the maximum number of lights per-bin.
  - Reduce the Range multiplier for lights.


## Special Thanks
- Fayer: _very_ extensive help with QA, support, repairs, and motivation.
- Builderb0y: help with optimized bit-magic supporting the core of voxelization.
- Bálint: Created the fancy Iris warning, as well as DDA tracing & bit-shifting madness.
- Tech: Helped implement improved soft shadow filtering & dithering.
