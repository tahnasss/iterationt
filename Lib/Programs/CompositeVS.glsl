#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/BasicFounctions/PrecomputedAtmosphere.glsl"


out vec2 texcoord;

out vec3 worldShadowVector;
out vec3 shadowVector;
out vec3 worldSunVector;
out vec3 worldMoonVector;

out vec3 colorShadowlight;
out vec3 colorSunlight;
out vec3 colorMoonlight;

out vec3 colorSkylight;
out vec3 colorSunSkylight;
out vec3 colorMoonSkylight;

out vec3 colorTorchlight;

out float timeNoon;
out float timeMidnight;

#ifdef VS_SUN_VISIBILITY
	#ifdef LENS_FLARE
		#include "/Lib/Uniform/GbufferTransforms.glsl"

		#ifdef FLARE_SHADOWBASED
			#include "/Lib/Uniform/ShadowTransforms.glsl"
			uniform sampler2D shadowtex0;
		#endif

		out vec2 sunCoord;
		out float sunVisibility;
	#endif

	vec2 ProjectSky(vec3 dir, float tileSize) {
		float tileSizeDivide = 0.5 * tileSize - 1.5;

		vec2 coord;
		if (abs(dir.x) > abs(dir.y) && abs(dir.x) > abs(dir.z)) {
			dir /= abs(dir.x);
			coord.x = dir.y * tileSizeDivide + tileSize * 0.5;
			coord.y = dir.z * tileSizeDivide + tileSize * (dir.x < 0.0 ? 0.5 : 1.5);
		} else if (abs(dir.y) > abs(dir.x) && abs(dir.y) > abs(dir.z)) {
			dir /= abs(dir.y);
			coord.x = dir.x * tileSizeDivide + tileSize * 1.5;
			coord.y = dir.z * tileSizeDivide + tileSize * (dir.y < 0.0 ? 0.5 : 1.5);
		} else {
			dir /= abs(dir.z);
			coord.x = dir.x * tileSizeDivide + tileSize * 2.5;
			coord.y = dir.y * tileSizeDivide + tileSize * (dir.z < 0.0 ? 0.5 : 1.5);
		}

		return coord * pixelSize;
	}
#endif

void main(){
	gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);
	texcoord = gl_Vertex.xy;

	worldShadowVector = shadowModelViewInverse[2].xyz;
	shadowVector = mat3(gbufferModelView) * worldShadowVector;
	//worldSunVector = worldTime > 12785 && worldTime < 23215 ? -worldShadowVector : worldShadowVector;
	worldSunVector = worldShadowVector * (step(sunAngle, 0.5) * 2.0 - 1.0);
	worldMoonVector = -worldSunVector;

	float SdotU = dot(vec3(0.0, 1.0, 0.0), worldSunVector);
	float MdotU = dot(vec3(0.0, 1.0, 0.0), worldMoonVector);


	#ifdef VS_SUN_VISIBILITY
		#ifdef LENS_FLARE
			#ifdef CAVE_MODE
				sunVisibility = 0.0;
			#else
				vec3 sunViewPos = shadowVector * 1e5;
				sunCoord = ScreenPos_From_ViewPos_Raw(sunViewPos).xy;


				float tileSize = min(SKY_IMAGE_RESOLUTION, min(floor(screenSize.x * 0.5) / 1.5, floor(screenSize.y * 0.5)));
				vec2 skyImageCoord = ProjectSky(worldShadowVector, tileSize);

				float dirVisibility = remap(-0.2, -0.6, shadowVector.z);

				float cloudVisibility = saturate(texture(colortex7, skyImageCoord).a * 1.5 - 0.5);
				cloudVisibility = mix(cloudVisibility, 1.0, curve(saturate((1.0 - saturate(SdotU)) * 12.0 - 11.0)) * saturate(1.0 - wetness * 1.5));
				cloudVisibility = max(1.0 - RAIN_SHADOW, cloudVisibility);


				float effectVisibility = 1.0 - blindness;

				#ifdef FLARE_SHADOWBASED
					vec3 cameraShadowPos = ShadowPos_From_WorldPos_Distorted(worldShadowVector * 0.5 + gbufferModelViewInverse[3].xyz);
					float shadowVisibility = step(cameraShadowPos.z, textureLod(shadowtex0, cameraShadowPos.xy, 0.0).x);

					sunVisibility =	dirVisibility * shadowVisibility * cloudVisibility * effectVisibility;
				#else
					float screenVisibility = smoothstep(0.5, 0.45, abs(sunCoord.x - 0.5)) *
											 smoothstep(0.5, 0.45, abs(sunCoord.y - 0.5));
					float depthVisibility = step(1.0, texture(depthtex0, sunCoord).x);

					sunVisibility =	dirVisibility * screenVisibility * depthVisibility * cloudVisibility * effectVisibility;
				#endif
			#endif
		#endif
	#endif

	timeNoon = 1.0 - pow(1.0 - (clamp(SdotU, 0.2, 0.99) - 0.2) / 0.8, 6.0);
	timeMidnight = curve(curve(saturate(MdotU * 20.0f + 0.4)));
	timeMidnight = 1.0 - pow(1.0 - timeMidnight, 2.0);


	#ifdef ATMO_HORIZON
		float minAltitude = 800.0;
	#else
		float minAltitude = 100.0;
	#endif
	vec3 camera = vec3(0.0, max(cameraPosition.y, minAltitude) * 0.001 + atmosphereModel.bottom_radius, 0.0);


	colorSunlight = GetSunAndSkyIrradiance(atmosphereModel, colortex11, colortex10, camera, worldSunVector, -worldSunVector, colorMoonlight, colorSunSkylight, colorMoonSkylight);

	colorSunlight *= 1.0 - curve(saturate((1.0 - saturate(SdotU)) * 30.0 - 29.0));
	colorMoonlight *= 1.0 - curve(saturate((1.0 - saturate(MdotU)) * 5.0 - 4.0));
	#ifdef COLD_MOONLIGHT
		DoNightEye(colorMoonlight);
	#endif

	colorShadowlight = colorSunlight + colorMoonlight;
	colorSkylight = colorSunSkylight + colorMoonSkylight;

	colorTorchlight = Blackbody(TORCHLIGHT_COLOR_TEMPERATURE);
}
