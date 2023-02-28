#define RENDER_COMPOSITE
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

out vec2 texcoord;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    #ifdef DEBUG_CSM_FRUSTUM
    	out vec3 shadowTileColors[4];
    	out mat4 matShadowToScene[4];

        #ifdef SHADOW_CSM_TIGHTEN
            out vec3 clipSize[4];
        #else
        	out vec3 clipMin[4];
        	out vec3 clipMax[4];
        #endif
    #endif

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
	uniform float near;
	uniform float far;

    #ifndef IS_IRIS
        uniform mat4 gbufferPreviousModelView;
    	uniform mat4 gbufferPreviousProjection;
    #endif

	#include "/lib/shadows/cascaded.glsl"
#endif


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED && defined DEBUG_CSM_FRUSTUM
		#ifndef IRIS_FEATURE_SSBO
			float cascadeSize[4];
	        cascadeSize[0] = GetCascadeDistance(0);
	        cascadeSize[1] = GetCascadeDistance(1);
	        cascadeSize[2] = GetCascadeDistance(2);
	        cascadeSize[3] = GetCascadeDistance(3);
		#endif

		for (int tile = 0; tile < 4; tile++) {
			//vec2 shadowTilePos = GetShadowTilePos(tile);
			shadowTileColors[tile] = GetShadowTileColor(tile);

			#ifdef IRIS_FEATURE_SSBO
                mat4 _cascadeProjection = cascadeProjection[tile];
				float rangeNear = tile > 0 ? cascadeSize[tile - 1] : near;
				float rangeFar = cascadeSize[tile];
			#else
                mat4 _cascadeProjection = GetShadowTileProjectionMatrix(cascadeSize, tile);
				float rangeNear = tile > 0 ? cascadeSize[tile - 1] : near;
				float rangeFar = cascadeSize[tile];
			#endif

            mat4 matSceneProjectionRanged = gbufferProjection;
            SetProjectionRange(matSceneProjectionRanged, rangeNear, rangeFar);
			
			mat4 matShadowWorldViewProjectionInv = inverse(_cascadeProjection * shadowModelView);
			matShadowToScene[tile] = matSceneProjectionRanged * gbufferModelView * matShadowWorldViewProjectionInv;

            #ifdef SHADOW_CSM_TIGHTEN
                clipSize[tile] = GetCascadePaddedFrustumClipBounds(_cascadeProjection, -1.5);
            #else
                // project frustum points
                mat4 matModelViewProjectionInv = inverse(matSceneProjectionRanged * gbufferModelView);
                mat4 matSceneToShadow = _cascadeProjection * shadowModelView * matModelViewProjectionInv;

                GetFrustumMinMax(matSceneToShadow, clipMin[tile], clipMax[tile]);
            #endif
		}
	#endif
}
