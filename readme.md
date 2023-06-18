# Shrimple [shader]

A Minecraft Java shader that attempts to maintain a minimal "vanilla" aesthetic, while adding some optional features:
 - Waving Plants.
 - FXAA (anti-aliasing).
 - Sharp/Soft Shadows.
 - CSM (Cascaded Shadow Mapping). **\***
 - Dynamic colored lighting. **\***
 - Ray-Traced block-light shadows. **\***
 - Volumetric fog lighting.
 - Rain puddles & ripples.
 - POM (Parallax Occlusion Mapping).
 - Normal Mapping.
 - Specular (shininess).

**\*** Feature only available with [Iris 1.6.0](https://modrinth.com/mod/iris/versions) or later!


## Mod Support
 - Create
 - Create Deco
 - Maccaws Lights
 - Supplementaries


## Known Issues
- The technique I use for lighting has the advantage of being very fast for few lights, but can also be dead slow with a lot of visible/nearby light sources.
- Ray-traced block-light volumetrics are known to be incredibly slow. It's more of a cool looking gimmick than meant for gameplay.


## FAQ
- **Q:** Why isn't block-lighting being ray traced?  
**A:** RT is off by default. Either change BLock Light > Mode to "Traced", or apply the "RTX" profile.

- **Q:** How do I remove the grainy noise from block-light shadows?  
**A:** Reduce the Block Light > Penumbra setting as needed, or to zero to completely disable temporal filtering. The "noise" is only needed for block-light soft shadows.

- **Q:** How do I make colored/dynamic/traced shadows work further from player/camera?  
**A:** You can increase the Block Lighting > Advanced > Horizontal/Vertical Bin Counts. Increasing the Bin Size option will also help, but it will educe the maximum "density" of light sources per area.

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
