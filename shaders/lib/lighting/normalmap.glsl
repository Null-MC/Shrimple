#ifdef RENDER_VERTEX
	void PrepareNormalMap() {
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vLocalTangent = mat3(gbufferModelViewInverse) * viewTangent;

        vTangentW = at_tangent.w;
	}
#endif

#ifdef RENDER_FRAG
	vec3 ApplyNormalMap(inout float lmcoordY, const in vec2 texcoord, const in vec3 localNormal, const in vec3 localTangent) {
	    #if MATERIAL_NORMALS == NORMALMAP_LAB
	        vec3 texNormal = texture(normals, texcoord).rgg;

	        if (any(greaterThan(texNormal.rg, EPSILON2))) {
	            texNormal.xy = texNormal.xy * 2.0 - 1.0;
	            texNormal.z = sqrt(max(1.0 - dot(texNormal.xy, texNormal.xy), EPSILON));
	        }
	    #elif MATERIAL_NORMALS == NORMALMAP_OLD
	        vec3 texNormal = texture(normals, texcoord).rgb;

	        if (any(greaterThan(texNormal, EPSILON3)))
	            texNormal = normalize(texNormal * 2.0 - 1.0);
	    #endif

	    vec3 localBinormal = normalize(cross(localTangent, localNormal) * vTangentW);

	    // if (!gl_FrontFacing) {
	    //     localTangent = -localTangent;
	    //     localBinormal = -localBinormal;
	    // }
	    
	    mat3 matTBN = mat3(localTangent, localBinormal, localNormal);
	    texNormal = matTBN * texNormal;

	    // apply sun/moon NoL to SkyLight
	    float skyLight = saturate((lmcoordY - (0.5/16.0)) * (16.0/15.0));

	    vec3 localLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
	    skyLight *= max(dot(localLightDir, texNormal), 0.0) * 0.7 + 0.7;

	    lmcoordY = saturate(skyLight) * (15.0/16.0) + (0.5/16.0);

	    return texNormal;
	}
#endif
