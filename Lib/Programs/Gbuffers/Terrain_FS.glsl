//Terrain_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform mat4 shadowModelViewInverse;

uniform float frameTimeCounter;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform float wetness;
uniform int renderStage;

#ifdef DIMENSION_END
	#include "/Lib/Uniform/ShadowModelViewEnd.glsl"
#endif

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

uniform float alphaTestRef;

in vec4 color;
in vec2 texcoord;
in vec3 viewPos;
in vec3 worldPos;
in mat3 tbn;
in vec2 blockLight;
flat in float materialIDs;
in float noWetItem;
flat in float textureResolution;


vec4 GetTexture(in sampler2D tex, in vec2 coord, float dist)
{
	#ifdef PARALLAX
		vec4 t = vec4(0.0f);
		if (dist < 20.0f){
			t = texture2DLod(tex, coord, 0);
		}else{
			t = texture2D(tex, coord);
		}
		return t;
	#else
		return texture2D(tex, coord);
	#endif
}

vec2 OffsetCoord(vec2 coord, vec2 offset, vec2 atlasTiles){
	vec2 interTileCoord = min(fract(coord + offset), 0.999999);
	return (floor(coord) + interTileCoord) / atlasTiles;
}

float BilinearHeightSample(vec2 coord, vec2 atlasTiles, float textureTexel){
	vec2 fpc = fract(coord * atlasSize + 0.5);
	coord *= atlasTiles;

	vec4 sh;
	sh = vec4(
		texture2D(normals, OffsetCoord(coord, vec2(-textureTexel,  textureTexel), atlasTiles)).a,
		texture2D(normals, OffsetCoord(coord, vec2( textureTexel,  textureTexel), atlasTiles)).a,
		texture2D(normals, OffsetCoord(coord, vec2( textureTexel, -textureTexel), atlasTiles)).a,
		texture2D(normals, OffsetCoord(coord, vec2(-textureTexel, -textureTexel), atlasTiles)).a
	);
	sh += step(sh, vec4(1e-3));
	return mix(
		mix(sh.w, sh.z, fpc.x),
		mix(sh.x, sh.y, fpc.x),
		fpc.y
	);
}

vec3 heightBasedNormal(vec2 coord, vec2 atlasTiles, float textureTexel) {
	vec2 fpc = fract(coord * atlasSize + 0.5);
    coord *= atlasTiles;

    vec4 sh;
    sh = vec4(
        texture2D(normals, OffsetCoord(coord, vec2(-textureTexel,  textureTexel), atlasTiles)).a,
        texture2D(normals, OffsetCoord(coord, vec2( textureTexel,  textureTexel), atlasTiles)).a,
        texture2D(normals, OffsetCoord(coord, vec2( textureTexel, -textureTexel), atlasTiles)).a,
        texture2D(normals, OffsetCoord(coord, vec2(-textureTexel, -textureTexel), atlasTiles)).a
    );

    vec3 normal = vec3((sh.w + sh.y - sh.z - sh.x) * fpc.y + (sh.z - sh.w),
                       (sh.w + sh.y - sh.z - sh.x) * fpc.x + (sh.x - sh.w),
                       textureTexel / PARALLAX_DEPTH * 8.0);
    normal.xy *= -1.0;

    return normal;
}

vec2 CalculateParallaxCoord(vec2 coord, vec2 atlasTiles, float textureTexel, inout vec3 offsetCoord){
	vec2 parallaxCoord = coord;

	vec3 viewVector = normalize(viewPos.xyz) * tbn;
	viewVector /= -viewVector.z;

	#ifdef SMOOTH_PARALLAX
		float sampleHeight = BilinearHeightSample(coord, atlasTiles, textureTexel);
	#else
		float sampleHeight = texture2D(normals, coord).a;
	#endif

	if (sampleHeight < 1.0){
		vec3 stepSize = viewVector / (PARALLAX_QUALITY);
        stepSize.xy *= PARALLAX_DEPTH * 0.1;

		vec2 tilesCoord = coord * atlasTiles;
        int currRefinements = 0;
        for (float i = 2.0 / PARALLAX_QUALITY; i < 2.0; i += 2.0 / PARALLAX_QUALITY){
            offsetCoord += stepSize * i;
            parallaxCoord = OffsetCoord(tilesCoord, offsetCoord.xy, atlasTiles);

            #ifdef SMOOTH_PARALLAX
                sampleHeight = BilinearHeightSample(parallaxCoord, atlasTiles, textureTexel);
            #else
                sampleHeight = texture2D(normals, parallaxCoord).a;
            #endif

            if (sampleHeight > offsetCoord.z){
                if (currRefinements < PARALLAX_MAX_REFINEMENTS){
                    offsetCoord -= stepSize * i;
                    stepSize *= 0.5;
                    currRefinements++;
                }
                else {
                    break;
                }
            }
        }
    }
    return parallaxCoord;
}


float CalculateParallaxShadow(vec2 parallaxCoord, vec2 atlasTiles, float textureTexel, vec3 normal){
	float parallaxShadow = 1.0;

	#ifdef DIMENSION_END
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverseEnd[2].xyz;
	#else
		vec3 shadowVector = mat3(gbufferModelView) * shadowModelViewInverse[2].xyz;
	#endif

	if(dot(shadowVector, normal) > 0.0){

		shadowVector = shadowVector * tbn;
		shadowVector /= shadowVector.z;

		#ifdef SMOOTH_PARALLAX
			float sampleHeight = BilinearHeightSample(parallaxCoord, atlasTiles, textureTexel);
		#else
			float sampleHeight = texture2D(normals, parallaxCoord).a;
		#endif

		vec3 offsetCoord = vec3(0.0, 0.0, sampleHeight);


		if (sampleHeight < 1.0){
			vec3 stepSize = shadowVector / (PARALLAX_SHADOW_QUALITY);
			stepSize.xy *= PARALLAX_DEPTH * 0.1;

			vec2 tilesCoord = parallaxCoord * atlasTiles;
			int currRefinements = 0;
			for (int i = int(sampleHeight * PARALLAX_SHADOW_QUALITY); i < PARALLAX_SHADOW_QUALITY; i++){
				offsetCoord += stepSize;
				vec2 sampleCoord = OffsetCoord(tilesCoord, offsetCoord.xy, atlasTiles);

				#ifdef SMOOTH_PARALLAX
					sampleHeight = BilinearHeightSample(sampleCoord, atlasTiles, textureTexel);
				#else
					sampleHeight = texture2D(normals, sampleCoord).a;
				#endif

				parallaxShadow *= saturate((offsetCoord.z - sampleHeight + 0.04) * 25.0);

				if(parallaxShadow == 0.0) break;
			}
		}
	}
	return parallaxShadow;
}

#include "/Lib/IndividualFounctions/Ripple.glsl"

void SampleAnisotropic(in vec2 atlasTiles, out vec4 albedoTex, out vec3 normalTex, out vec4 specularTex){
	albedoTex = vec4(0.0);
	normalTex = vec3(0.0);
	specularTex = vec4(0.0);

	vec2 coord = texcoord * atlasTiles;

	//https://www.shadertoy.com/view/4lXfzn
	mat2 qd = inverse(mat2(dFdxCoarse(coord), dFdyCoarse(coord)));
	qd = transpose(qd) * qd;

	float d = determinant(qd);
	float t = qd[0][0] + qd[1][1];

	float D = sqrt(abs(t * t - 4.0 * d));
	float V = (t - D) * 0.5;

	vec2 A = inversesqrt(V) * normalize(vec2(-qd[0][1], qd[0][0] - V));
	A = min(A, 1.0);

	const float x = ANISOTROPIC_FILTERING_QUALITY;
	float c = 0.0;

	for (float i = 0.5 - x * 0.5; i < x * 0.5; i++){
		vec2 sampleCoord = i * A / x;
		sampleCoord = OffsetCoord(coord, sampleCoord, atlasTiles);

		vec4 albedoSample = texture2D(texture, sampleCoord);

		if (albedoSample.a > 0.0){
			albedoTex += albedoSample;

			#ifdef MC_NORMAL_MAP
				normalTex += texture2D(normals, sampleCoord).rgb;
			#endif

			#ifdef MC_SPECULAR_MAP
				specularTex += texture2D(specular, sampleCoord);
			#endif

			c++;
		}
	}
	c = 1.0 / max(c, 1.0);
	albedoTex *= c;
	albedoTex.a = texture2D(texture, texcoord).a;

	#ifdef MC_NORMAL_MAP
		normalTex = DecodeNormalTex(normalTex * c);
	#else
		normalTex = vec3(0.0, 0.0, 1.0);
	#endif

	#ifdef MC_SPECULAR_MAP
		specularTex *= c;
		#if TEXTURE_PBR_FORMAT == 1
			specularTex.b = specularTex.a;
		#endif
	#endif
}


void main(){
//anisotropic filtering & parallax
	float parallaxShadow = 1.0;

	float textureResolutionFixed = exp2(round(log2(textureResolution)));
	vec2 atlasTiles = atlasSize / textureResolutionFixed;

    #ifdef PARALLAX
		float textureTexel = 0.5 / textureResolutionFixed;

        vec3 offsetCoord = vec3(0.0, 0.0, 1.0);

        vec2 parallaxCoord = CalculateParallaxCoord(texcoord, atlasTiles, textureTexel, offsetCoord);

		vec4 albedoTex = texture2D(texture, parallaxCoord);

		float alphaRef = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ? 0.0 : 0.1;
		if (albedoTex.a < alphaRef) discard;

		vec3 normalTex;
		#ifdef PARALLAX_BASED_NORMAL
			if (offsetCoord.z < 1.0){
				#ifdef SMOOTH_PARALLAX
					vec3 parallaxNormal = heightBasedNormal(parallaxCoord, atlasTiles, textureTexel);
					normalTex = parallaxNormal;
				#else
					const float eps = 1e-2;
					float epsz = 1.0 / atlasSize.y;
					vec2 tilesCoord = parallaxCoord * atlasTiles;
					float rD = texture2D(normals, OffsetCoord(tilesCoord, vec2(eps / atlasTiles.x, 0.0), atlasTiles)).a;
					float lD = texture2D(normals, OffsetCoord(tilesCoord,-vec2(eps / atlasTiles.x, 0.0), atlasTiles)).a;
					float uD = texture2D(normals, OffsetCoord(tilesCoord, vec2(0.0, eps / atlasTiles.y), atlasTiles)).a;
					float dD = texture2D(normals, OffsetCoord(tilesCoord,-vec2(0.0, eps / atlasTiles.y), atlasTiles)).a;
				   normalTex = vec3((lD - rD), (dD - uD), step(abs(lD - rD) + abs(dD - uD), 1e-3));
				#endif
			}else
		#endif
		{
			#ifdef MC_NORMAL_MAP
				normalTex = DecodeNormalTex(texture2D(normals, parallaxCoord).rgb);
			#else
				normalTex = vec3(0.0, 0.0, 1.0);
			#endif
		}


		#ifdef MC_SPECULAR_MAP
			vec4 specularTex = texture2D(specular, parallaxCoord);
			#if TEXTURE_PBR_FORMAT == 1
				specularTex.b = specularTex.a;
			#endif
		#else
			vec4 specularTex = vec4(0.0);
		#endif
	#else
		vec4 albedoTex = texture2D(texture, texcoord);

		float alphaRef = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ? 0.0 : 0.1;
		if (albedoTex.a < alphaRef) discard;

		#if ANISOTROPIC_FILTERING_QUALITY > 0
			vec3 normalTex;
			vec4 specularTex;
			SampleAnisotropic(atlasTiles, albedoTex, normalTex, specularTex);
		#else
			#ifdef MC_NORMAL_MAP
				vec3 normalTex = DecodeNormalTex(texture2D(normals, texcoord).rgb);
			#else
				vec3 normalTex = vec3(0.0, 0.0, 1.0);
			#endif

			#ifdef MC_SPECULAR_MAP
				vec4 specularTex = texture2D(specular, texcoord);
				#if TEXTURE_PBR_FORMAT == 1
					specularTex.b = specularTex.a;
				#endif
			#else
				vec4 specularTex = vec4(0.0);
			#endif
		#endif
    #endif


//albedo
	vec4 albedo = albedoTex * color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//wet effect
	float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

	#ifdef DIMENSION_MAIN
		float wet = max(wetness, SURFACE_WETNESS);
		GetModulatedRainSpecular(wet, worldPos);

		#ifdef RAIN_SPLASH_EFFECT
			vec2 rainNormal = GetRainNormal(worldPos, wet);
		#endif

		wet *= saturate(NdotU * 0.5 + 0.5);
		wet *= saturate(blockLight.y * 10.0 - 9.0);
	#else
		float wet = SURFACE_WETNESS;
		GetModulatedRainSpecular(wet, worldPos);

		wet *= saturate(NdotU * 0.5 + 0.5);
	#endif

	wet *= (1.0f - noWetItem);

	float wetFact = saturate(wet * 1.5);

	specularTex.a = wetFact;


//normal
	normalTex = mix(normalize(normalTex), vec3(0.0, 0.0, 1.0), wetFact);
	#ifdef DIMENSION_MAIN
		#ifdef RAIN_SPLASH_EFFECT
			rainNormal *= wet * NdotU * 0.7;
			normalTex = normalTex + vec3(rainNormal, 0.0);
		#endif
	#endif

	vec3 viewNormal = tbn * normalize(normalTex);

	#ifdef TERRAIN_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos.xyz);
		viewNormal = normalize(viewNormal + tbn[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal.xyz);



	#ifndef DIMENSION_NETHER
		#ifdef PARALLAX
			#ifdef PARALLAX_SHADOW
				if(albedo.a > 0.0) parallaxShadow = CalculateParallaxShadow(parallaxCoord, atlasTiles, textureTexel, viewNormal);
			#endif
		#endif
	#endif

	//redstone_wire
	if (materialIDs == 30.0){
		float power = color.r;
		power = saturate(power * 1.1 - 0.1) * (1.0 - step(power, 0.3));
		specularTex.b = power;
	}

    if (albedo.a < alphaTestRef) discard;
	
	gl_FragData[0] = vec4(albedo.rgb, 1.0);
    gl_FragData[1] = vec4(normalEnc, blockLight);
    gl_FragData[2] = vec4(Pack2x8(specularTex.rg), Pack2x8(specularTex.ba), (materialIDs + 0.1) / 255.0, parallaxShadow);
}
/* DRAWBUFFERS:036 */
