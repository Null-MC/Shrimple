# Shrimple [shader]

A Minecraft Java shader that attempts to maintain a minimal "vanilla" aesthetic, while adding some optional features:
- TAA +CAS. Temporal AntiAliasing reduces jagged edges, and improves subpixel details. Filtered using a modified version of AMD's Contrast-Aware Sharpening.
- Colored Lighting. Uses custom floodfill implementation to replace nearby lighting with a similar RGB variant.
- PBR Materials. Both "OldPbr" and "LabPbr" packs are supported, with a very minimal "PBR" implementation.
- Sky-Light Soft Shadows; cast from the sun & moon.
- Reflections. Screen-space by default; use Photonics for world-space reflections.
- Parallax/"POM". Also support "smooth" and "sharp" methods.


## Mod Support

### Photonics
The [Photonics](https://modrinth.com/mod/photonics) mod can be used to replace screen-space reflection with fully world-space reflections. RT lighting is not currently supported.

### Other
 - [Colorwheel](https://modrinth.com/mod/colorwheel)
 - [Distant Horizons](https://modrinth.com/mod/distanthorizons)
 - [Physics Mod](https://www.patreon.com/c/Haubna/posts)
 - [Voxy](https://modrinth.com/mod/voxy)


## FAQ
- **Q:** What happened to the "RTX" profile /ray-traced lighting?  
**A:** I removed it, never should have added to Shrimple; but good news, you can get it back with Photonics mod.
