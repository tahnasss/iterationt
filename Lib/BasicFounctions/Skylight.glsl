

vec3 camera = vec3(0.0, max((cameraPosition.y - 63.0) * 0.001 + atmosphereModel.bottom_radius, 0.5), 0.0);

colorSunlight = GetSunAndSkyIrradiance(atmosphereModel, colortex11, colortex10, camera, worldSunVector, -worldSunVector, colorMoonlight, colorSunSkylight, colorMoonSkylight);

colorSunlight *= 1.0 - curve(saturate((1.0 - saturate(SdotU)) * 20.0 - 18.98));
colorMoonlight *= 1.0 - curve(saturate((1.0 - saturate(MdotU)) * 5.0 - 4.745));

colorShadowlight = colorSunlight + colorMoonlight;
