#define TRANSMITTANCE_TEXTURE_WIDTH 256
#define TRANSMITTANCE_TEXTURE_HEIGHT 64

#define SCATTERING_TEXTURE_R_SIZE 32 //z
#define SCATTERING_TEXTURE_MU_SIZE 128 //y
#define SCATTERING_TEXTURE_MU_S_SIZE 32 //x
#define SCATTERING_TEXTURE_NU_SIZE 16 //x

#define IRRADIANCE_TEXTURE_WIDTH 64
#define IRRADIANCE_TEXTURE_HEIGHT 16


struct DensityProfileLayer {
  float width;
  float exp_term;
  float exp_scale;
  float linear_term;
  float constant_term;
};

struct DensityProfile {
  DensityProfileLayer layers[2];
};

struct AtmosphereParameters {
  vec3              solar_irradiance;
  float             sun_angular_radius;
  float             bottom_radius;
  float             top_radius;
  DensityProfile    rayleigh_density;
  vec3              rayleigh_scattering;
  DensityProfile    mie_density;
  vec3              mie_scattering;
  vec3              mie_extinction;
  float             mie_phase_function_g;
  DensityProfile    absorption_density;
  vec3              absorption_extinction;
  vec3              ground_albedo;
  float             mu_s_min;
};

const AtmosphereParameters atmosphereModel = AtmosphereParameters(
    vec3(1.68194,1.85149,1.91198), //solar_irradiance 620 540 440
    0.005, //sun_angular_radius

    6360.0, //bottom_radius
    6420.0, //Length top_radius

    DensityProfile(DensityProfileLayer[2](  // rayleigh_density
        DensityProfileLayer(0.000000,0.000000,0.000000,0.000000,0.000000),
        DensityProfileLayer(0.000000,1.000000,-0.125000,0.000000,0.000000)
    )),
    vec3(0.008396,0.014590,0.033100), //rayleigh_scattering 620 540 440

    DensityProfile(DensityProfileLayer[2](  // mie_density
        DensityProfileLayer(0.000000,0.000000,0.000000,0.000000,0.000000),
        DensityProfileLayer(0.000000,1.000000,-0.833333,0.000000,0.000000)
    )),
    vec3(0.003996), //mie_scattering
    vec3(0.004440), //mie_extinction
    0.8, //mie_phase_function_g

    DensityProfile(DensityProfileLayer[2]( //absorption_density
        DensityProfileLayer(25.000000,0.000000,0.000000,0.066667,-0.666667),
        DensityProfileLayer(0.000000,0.000000,0.000000,-0.066667,2.666667)
    )),
    vec3(0.0020031,0.0016555,0.0000847), //absorption_extinction 620 540 440

    vec3(0.1), //ground_albedo
    -0.5 // mu_s_min
);



//////////Utility functions///////////////////////
//////////Utility functions///////////////////////

float ClampCosine(float mu){
    return clamp(mu, -1.0, 1.0);
}

float ClampDistance(float d){
    return max(d, 0.0);
}

float ClampRadius(AtmosphereParameters atmosphere, float r){
    return clamp(r, atmosphere.bottom_radius, atmosphere.top_radius);
}

float SafeSqrt(float a){
    return sqrt(max(a, 0.0));
}

vec3 RenderSunDisc(vec3 worldDir, vec3 sunDir){
	float d = dot(worldDir, sunDir);

	float size = 5e-5;
	float hardness = 4e4;

    float disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	return vec3(1.1114, 0.9756, 0.9133) * disc;
}

float RenderMoonDisc(vec3 worldDir, vec3 moonDir){
	float d = dot(worldDir, moonDir);

	float size = 5e-5;
	float hardness = 1e5;

	return pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);
}

float RenderMoonDiscReflection(vec3 worldDir, vec3 moonDir){
	float d = dot(worldDir, moonDir);

	float size = 0.0025;
	float hardness = 300.0;

	return pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);
}



//////////Intersections///////////////////////////
//////////Intersections///////////////////////////

float DistanceToTopAtmosphereBoundary(
    AtmosphereParameters atmosphere,
    float r,
    float mu
    ){
        float discriminant = r * r * (mu * mu - 1.0) + atmosphere.top_radius * atmosphere.top_radius;
        return ClampDistance(-r * mu + SafeSqrt(discriminant));
}

float DistanceToBottomAtmosphereBoundary(
    AtmosphereParameters atmosphere,
    float r,
    float mu
    ){
        float discriminant = r * r * (mu * mu - 1.0) + atmosphere.bottom_radius * atmosphere.bottom_radius;
        return ClampDistance(-r * mu - SafeSqrt(discriminant));
}

bool RayIntersectsGround(
    AtmosphereParameters atmosphere,
    float r,
    float mu
    ){
        return mu < 0.0 && r * r * (mu * mu - 1.0) + atmosphere.bottom_radius * atmosphere.bottom_radius >= 0.0;
}



//////////Density at altitude/////////////////////
//////////Density at altitude/////////////////////

float GetLayerDensity(
    DensityProfileLayer layer,
    float altitude
    ){
        float density = layer.exp_term * exp(layer.exp_scale * altitude) +
                        layer.linear_term * altitude + layer.constant_term;
        return clamp(density, float(0.0), float(1.0));
}

float GetProfileDensity(
    DensityProfile profile,
    float altitude
    ){
        return altitude < profile.layers[0].width ?
            GetLayerDensity(profile.layers[0], altitude) :
            GetLayerDensity(profile.layers[1], altitude);
}



//////////Coord Transforms////////////////////////
//////////Coord Transforms////////////////////////

float GetTextureCoordFromUnitRange(float x, int texture_size) {
    return 0.5 / float(texture_size) + x * (1.0 - 1.0 / float(texture_size));
}

vec4 GetScatteringTextureUvwzFromRMuMuSNu(
    AtmosphereParameters atmosphere,
    float r,
    float mu,
    float mu_s,
    float nu,
    bool ray_r_mu_intersects_ground
    ){
        float H = sqrt(atmosphere.top_radius * atmosphere.top_radius - atmosphere.bottom_radius * atmosphere.bottom_radius);

        float rho = SafeSqrt(r * r - atmosphere.bottom_radius * atmosphere.bottom_radius);
        float u_r = GetTextureCoordFromUnitRange(rho / H, SCATTERING_TEXTURE_R_SIZE);

        float r_mu = r * mu;
        float discriminant = r_mu * r_mu - r * r + atmosphere.bottom_radius * atmosphere.bottom_radius;
        float u_mu;

        if (ray_r_mu_intersects_ground){
            float d = -r_mu - SafeSqrt(discriminant);
            float d_min = r - atmosphere.bottom_radius;
            float d_max = rho;
            u_mu = 0.5 - 0.5 * GetTextureCoordFromUnitRange(d_max == d_min ? 0.0 : (d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2);
        }else{
            float d = -r_mu + SafeSqrt(discriminant + H * H);
            float d_min = atmosphere.top_radius - r;
            float d_max = rho + H;
            u_mu = 0.5 + 0.5 * GetTextureCoordFromUnitRange((d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2);
        }

        float d = DistanceToTopAtmosphereBoundary(atmosphere, atmosphere.bottom_radius, mu_s);
        float d_min = atmosphere.top_radius - atmosphere.bottom_radius;
        float d_max = H;
        float a = (d - d_min) / (d_max - d_min);
        float D = DistanceToTopAtmosphereBoundary(atmosphere, atmosphere.bottom_radius, atmosphere.mu_s_min);
        float A = (D - d_min) / (d_max - d_min);
        float u_mu_s = GetTextureCoordFromUnitRange(max(1.0 - a / A, 0.0) / (1.0 + a), SCATTERING_TEXTURE_MU_S_SIZE);
        float u_nu = (nu + 1.0) / 2.0;
        return vec4(u_nu, u_mu_s, u_mu, u_r);
}



//////////Transmittance Lookup////////////////////
//////////Transmittance Lookup////////////////////

vec2 GetTransmittanceTextureUvFromRMu(
    AtmosphereParameters atmosphere,
    float r,
    float mu
    ){
        float H = sqrt(atmosphere.top_radius * atmosphere.top_radius - atmosphere.bottom_radius * atmosphere.bottom_radius);

        float rho = SafeSqrt(r * r - atmosphere.bottom_radius * atmosphere.bottom_radius);

        float d = DistanceToTopAtmosphereBoundary(atmosphere, r, mu);
        float d_min = atmosphere.top_radius - r;
        float d_max = rho + H;
        float x_mu = (d - d_min) / (d_max - d_min);
        float x_r = rho / H;
        return vec2(GetTextureCoordFromUnitRange(x_mu, TRANSMITTANCE_TEXTURE_WIDTH),
                    GetTextureCoordFromUnitRange(x_r, TRANSMITTANCE_TEXTURE_HEIGHT));
}

vec3 GetTransmittanceToTopAtmosphereBoundary(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    float r,
    float mu
    ){
        vec2 uv = GetTransmittanceTextureUvFromRMu(atmosphere, r, mu);
        return vec3(texture(transmittance_texture, uv));
}

vec3 GetTransmittance(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    float r,
    float mu,
    float d,
    bool ray_r_mu_intersects_ground
    ){
        float r_d = ClampRadius(atmosphere, sqrt(d * d + 2.0 * r * mu * d + r * r));
        float mu_d = ClampCosine((r * mu + d) / r_d);

        if (ray_r_mu_intersects_ground) {
            return min(
            GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r_d, -mu_d) /
                GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r, -mu),
            vec3(1.0));
        } else {
            return min(
            GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r, mu) /
                GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r_d, mu_d),
            vec3(1.0));
        }
}

vec3 GetTransmittanceToSun(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    float r,
    float mu_s
    ){
        float sin_theta_h = atmosphere.bottom_radius / r;
        float cos_theta_h = -sqrt(max(1.0 - sin_theta_h * sin_theta_h, 0.0));

        return GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r, mu_s) *
            smoothstep(-sin_theta_h * atmosphere.sun_angular_radius,
                       sin_theta_h * atmosphere.sun_angular_radius,
                       mu_s - cos_theta_h);
}



//////////Scattering Lookup///////////////////////
//////////Scattering Lookup///////////////////////

vec3 GetExtrapolatedSingleMieScattering(
    AtmosphereParameters atmosphere,
    vec4 scattering
    ){
        if (scattering.r <= 0.0){
            return vec3(0.0);
        }
        return scattering.rgb * scattering.a / scattering.r *
            (atmosphere.rayleigh_scattering.r / atmosphere.mie_scattering.r) *
            (atmosphere.mie_scattering / atmosphere.rayleigh_scattering);
}

vec3 GetCombinedScattering(
    AtmosphereParameters atmosphere,
    sampler3D scattering_texture,
    float r,
    float mu,
    float mu_s,
    float nu,
    bool ray_r_mu_intersects_ground,
    out vec3 single_mie_scattering
    ){
        vec4 uvwz = GetScatteringTextureUvwzFromRMuMuSNu(atmosphere, r, mu, mu_s, nu, ray_r_mu_intersects_ground);
        float tex_coord_x = uvwz.x * float(SCATTERING_TEXTURE_NU_SIZE - 1);
        float tex_x = floor(tex_coord_x);
        float lerp = tex_coord_x - tex_x;
        vec3 uvw0 = vec3((tex_x + uvwz.y) / float(SCATTERING_TEXTURE_NU_SIZE), uvwz.z, uvwz.w);
        vec3 uvw1 = vec3((tex_x + 1.0 + uvwz.y) / float(SCATTERING_TEXTURE_NU_SIZE), uvwz.z, uvwz.w);

        vec4 combined_scattering = texture(scattering_texture, uvw0) * (1.0 - lerp) + texture(scattering_texture, uvw1) * lerp;

        vec3 scattering = vec3(combined_scattering);
        single_mie_scattering = GetExtrapolatedSingleMieScattering(atmosphere, combined_scattering);

        return scattering;
}



//////////Irradiance Lookup///////////////////////
//////////Irradiance Lookup///////////////////////

vec3 GetIrradiance(
    AtmosphereParameters atmosphere,
    sampler2D irradiance_texture,
    float r,
    float mu_s
    ){
        float x_r = (r - atmosphere.bottom_radius) / (atmosphere.top_radius - atmosphere.bottom_radius);
        float x_mu_s = mu_s * 0.5 + 0.5;
        vec2 uv = vec2(GetTextureCoordFromUnitRange(x_mu_s, IRRADIANCE_TEXTURE_WIDTH),
                       GetTextureCoordFromUnitRange(x_r, IRRADIANCE_TEXTURE_HEIGHT));

        return vec3(texture(irradiance_texture, uv));
}



//////////Rendering///////////////////////////////
//////////Rendering///////////////////////////////

const mat3 LMS = mat3(1.6218, -0.4493, 0.0325, -0.0374, 1.0598, -0.0742, -0.0283, -0.1119, 1.0491);


vec3 GetSunAndSkyIrradiance(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    sampler2D irradiance_texture,
    vec3 point,
    vec3 sun_direction,
    vec3 moon_direction,
    out vec3 moon_irradiance,
    out vec3 sun_sky_irradiance,
    out vec3 moon_sky_irradiance
    ){
        float r = length(point);
        float sun_mu_s = dot(point, sun_direction) / r;
        float moon_mu_s = dot(point, moon_direction) / r;

        sun_sky_irradiance = GetIrradiance(atmosphere, irradiance_texture, r, sun_mu_s) * LMS;
        moon_sky_irradiance = GetIrradiance(atmosphere, irradiance_texture, r, moon_mu_s) * NIGHT_BRIGHTNESS * LMS;

        vec3 sun_irradiance = atmosphere.solar_irradiance * 0.6;
        moon_irradiance = sun_irradiance * GetTransmittanceToSun(atmosphere, transmittance_texture, r, moon_mu_s) * NIGHT_BRIGHTNESS * LMS;
        sun_irradiance *= GetTransmittanceToSun(atmosphere, transmittance_texture, r, sun_mu_s);

        return sun_irradiance * LMS;
}


vec3 GetSkyRadiance(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    sampler3D scattering_texture,
    sampler2D irradiance_texture,
    vec3 camera,
    vec3 view_ray,
    vec3 sun_direction,
    vec3 moon_direction,
    bool horizon,
    out vec3 transmittance,
    out bool ray_r_mu_intersects_ground
    ){
        float r = length(camera);
        float rmu = dot(camera, view_ray);
        float distance_to_top_atmosphere_boundary = -rmu - sqrt(rmu * rmu - r * r + atmosphere.top_radius * atmosphere.top_radius);

        if (distance_to_top_atmosphere_boundary > 0.0){
            camera = camera + view_ray * distance_to_top_atmosphere_boundary;
            r = atmosphere.top_radius;
            rmu += distance_to_top_atmosphere_boundary;
        } else if (r > atmosphere.top_radius) {
            transmittance = vec3(1.0);
            return vec3(0.0);
        }

        float mu = rmu / r;
        float sun_mu_s = dot(camera, sun_direction) / r;
        float sun_nu = dot(view_ray, sun_direction);

        float moon_mu_s = dot(camera, moon_direction) / r;
        float moon_nu = dot(view_ray, moon_direction);


        ray_r_mu_intersects_ground = RayIntersectsGround(atmosphere, r, mu);


        transmittance = ray_r_mu_intersects_ground ? vec3(0.0) : GetTransmittanceToTopAtmosphereBoundary(atmosphere, transmittance_texture, r, mu);

        vec3 sun_single_mie_scattering;
        vec3 sun_scattering;

        vec3 moon_single_mie_scattering;
        vec3 moon_scattering;

        horizon = horizon && ray_r_mu_intersects_ground;

        sun_scattering = GetCombinedScattering(atmosphere, scattering_texture, r, mu, sun_mu_s, sun_nu, horizon, sun_single_mie_scattering);
        moon_scattering = GetCombinedScattering(atmosphere, scattering_texture, r, mu, moon_mu_s, moon_nu, horizon, moon_single_mie_scattering);


        vec3 groundDiffuse = vec3(0.0);
        #ifdef ATMO_HORIZON
        if (horizon){
            vec3 planet_surface = camera + view_ray * DistanceToBottomAtmosphereBoundary(atmosphere, r, mu);

            float r = length(planet_surface);
            float sun_mu_s = dot(planet_surface, sun_direction) / r;
            float moon_mu_s = dot(planet_surface, moon_direction) / r;

            vec3 sky_irradiance = GetIrradiance(atmosphere, irradiance_texture, r, sun_mu_s);
            sky_irradiance += GetIrradiance(atmosphere, irradiance_texture, r, moon_mu_s) * NIGHT_BRIGHTNESS;
            vec3 sun_irradiance = atmosphere.solar_irradiance * GetTransmittanceToSun(atmosphere, transmittance_texture, r, sun_mu_s);

            float d = distance(camera, planet_surface);
            vec3 surface_transmittance = GetTransmittance(atmosphere, transmittance_texture, r, mu, d, ray_r_mu_intersects_ground);

            groundDiffuse = mix(sky_irradiance * 0.1, sun_irradiance * 0.008, wetness * 0.6) * surface_transmittance;
        }
        #endif


        vec3 rayleigh = sun_scattering * RayleighPhaseFunction(sun_nu)
                     + moon_scattering * RayleighPhaseFunction(moon_nu) * NIGHT_BRIGHTNESS;

        vec3 mie = sun_single_mie_scattering * MiePhaseFunction(atmosphere.mie_phase_function_g, sun_nu)
                + moon_single_mie_scattering * MiePhaseFunction(atmosphere.mie_phase_function_g, moon_nu) * NIGHT_BRIGHTNESS;

        rayleigh = mix(rayleigh,  vec3(Luminance(rayleigh)) * atmosphere.solar_irradiance, wetness * 0.5);

        return (rayleigh + mie + groundDiffuse) * (1.0 - wetness * 0.4) * LMS;
}


vec3 GetSkyRadianceToPoint(
    AtmosphereParameters atmosphere,
    sampler2D transmittance_texture,
    sampler3D scattering_texture,
    vec3 camera,
    vec3 point,
    vec3 sun_direction,
    vec3 moon_direction,
    out vec3 transmittance
    ){
        vec3 view_ray = normalize(point - camera);
        float r = length(camera);
        float rmu = dot(camera, view_ray);
        float distance_to_top_atmosphere_boundary = -rmu - sqrt(rmu * rmu - r * r + atmosphere.top_radius * atmosphere.top_radius);

        if (distance_to_top_atmosphere_boundary > 0.0){
            camera = camera + view_ray * distance_to_top_atmosphere_boundary;
            r = atmosphere.top_radius;
            rmu += distance_to_top_atmosphere_boundary;
        }

        float mu = rmu / r;
        float sun_mu_s = dot(camera, sun_direction) / r;
        float sun_nu = dot(view_ray, sun_direction);
        float moon_mu_s = dot(camera, moon_direction) / r;
        float moon_nu = dot(view_ray, moon_direction);
        float d = length(point - camera);

        #ifdef CLOUD_LOCAL_LIGHTING
            bool ray_r_mu_intersects_ground = RayIntersectsGround(atmosphere, r, mu);
        #else
            bool ray_r_mu_intersects_ground = false;
        #endif

        transmittance = GetTransmittance(atmosphere, transmittance_texture, r, mu, d, ray_r_mu_intersects_ground);

        vec3 sun_single_mie_scattering;
        vec3 sun_scattering = GetCombinedScattering(atmosphere, scattering_texture, r, mu, sun_mu_s, sun_nu, ray_r_mu_intersects_ground, sun_single_mie_scattering);
        vec3 moon_single_mie_scattering;
        vec3 moon_scattering = GetCombinedScattering(atmosphere, scattering_texture, r, mu, moon_mu_s, moon_nu, ray_r_mu_intersects_ground, moon_single_mie_scattering);

        float r_p = ClampRadius(atmosphere, sqrt(d * d + 2.0 * r * mu * d + r * r));
        float mu_p = (r * mu + d) / r_p;
        float sun_mu_s_p = (r * sun_mu_s + d * sun_nu) / r_p;
        float moon_mu_s_p = (r * moon_mu_s + d * moon_nu) / r_p;

        vec3 sun_single_mie_scattering_p;
        vec3 sun_scattering_p = GetCombinedScattering(atmosphere, scattering_texture, r_p, mu_p, sun_mu_s_p, sun_nu, ray_r_mu_intersects_ground, sun_single_mie_scattering_p);
        vec3 moon_single_mie_scattering_p;
        vec3 moon_scattering_p = GetCombinedScattering(atmosphere, scattering_texture, r_p, mu_p, moon_mu_s_p, moon_nu, ray_r_mu_intersects_ground, moon_single_mie_scattering_p);

        sun_scattering = sun_scattering - transmittance * sun_scattering_p;
        sun_single_mie_scattering = sun_single_mie_scattering - transmittance * sun_single_mie_scattering_p;
        moon_scattering = moon_scattering - transmittance * moon_scattering_p;
        moon_single_mie_scattering = moon_single_mie_scattering - transmittance * moon_single_mie_scattering_p;

        sun_single_mie_scattering = sun_single_mie_scattering * smoothstep(0.0, 0.01, sun_mu_s);
        moon_single_mie_scattering = moon_single_mie_scattering * smoothstep(0.0, 0.01, moon_mu_s);

        vec3 rayleigh = sun_scattering * RayleighPhaseFunction(sun_nu)
                     + moon_scattering * RayleighPhaseFunction(moon_nu) * NIGHT_BRIGHTNESS;

        vec3 mie = sun_single_mie_scattering * MiePhaseFunction(atmosphere.mie_phase_function_g, sun_nu)
                + moon_single_mie_scattering * MiePhaseFunction(atmosphere.mie_phase_function_g, moon_nu) * NIGHT_BRIGHTNESS;

        rayleigh = mix(rayleigh, vec3(Luminance(rayleigh)) * atmosphere.solar_irradiance, wetness * 0.5);

        return (rayleigh + mie) * (1.0 - wetness * 0.4) * LMS;
}
