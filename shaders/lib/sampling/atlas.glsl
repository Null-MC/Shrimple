#ifdef RENDER_VERTEX
    //uniform ivec2 atlasSize;

    void GetAtlasBounds(out mat2 atlasBounds, out vec2 localCoord) {
        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;// + 0.5*rcp(atlasSize);
        vec2 coordNMid = texcoord - coordMid;

        atlasBounds[0] = min(texcoord, coordMid - coordNMid);
        atlasBounds[1] = abs(coordNMid) * 2.0;

        localCoord = sign(coordNMid) * 0.5 + 0.5;// - 0.001;

        //vec2 localPixelSize = rcp(atlasSize);
        //atlasBounds[0] += localPixelSize;
        //atlasBounds[1] -= localPixelSize;
    }
#endif

#ifdef RENDER_FRAG
    // atlasBounds: [0]=position [1]=size
    vec2 GetAtlasCoord(const in vec2 localCoord) {
        return fract(localCoord) * atlasBounds[1] + atlasBounds[0];
    }

    vec2 GetLocalCoord(const in vec2 atlasCoord) {
        return (atlasCoord - atlasBounds[0]) / atlasBounds[1];
    }
#endif
