#define iterationT_VERSION AT // [AT BT]
#define iterationT_VERSION_TYPE AT // [AT BT]


//Renewed modified by Tahnass


const float PI = 3.14159265359;


float saturate(float x){
	return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x){
	return clamp(x, vec2(0.0), vec2(1.0));
}

vec3 saturate(vec3 x){
	return clamp(x, vec3(0.0), vec3(1.0));
}

vec3 LinearToGamma(vec3 c){
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c){
	return pow(c, vec3(2.2));
}

vec3 LinearToCurve(vec3 c){
	return pow(c, vec3(0.25));
}

vec3 CurveToLinear(vec3 c){
	c = c * c;
	return c * c;
}

float LinearToCurve(float c){
	return pow(c, 0.25);
}

float CurveToLinear(float c){
	c = c * c;
	return c * c;
}


float curve(float x){
	return x * x * (3.0 - 2.0 * x);
}

vec3 curve(vec3 x){
	return x * x * (3.0 - 2.0 * x);
}

float remap(float e0, float e1, float x){
	return saturate((x - e0) / (e1 - e0));
}

float atan2(vec2 v){
	return v.x == 0.0 ?
		(1.0 - step(abs(v.y), 0.0)) * sign(v.y) * PI * 0.5 :
		atan(v.y / v.x) + step(v.x, 0.0) * sign(v.y) * PI;
}

float Luminance(vec3 c){
	return dot(c, vec3(0.2125, 0.7154, 0.0721));
}

void DoNightEye(inout vec3 c){
	float luminance = Luminance(c);
	c = mix(c, luminance * vec3(0.7771, 1.0038, 1.6190), vec3(0.5));
}



float Pack2x8(vec2 x){
    return dot(floor(x * 255.0), vec2(1.0, 256.0) / 65535.0);
}

vec2 Unpack2x8(float x){
    x *= 65535.0;
	float a = fract(x / 256.0) * 256.0;
	return vec2(a / 255.0, (x - a) / 65280.0);
}

vec4 PackRGBE16(vec3 x){
    const float r16 = 1.0 / 65535.0;
    float exponentPart = floor(log2(max(max(x.r, x.g), x.b)));
    vec3 mantissaPart = saturate((32768.0 * r16) * x / exp2(exponentPart));
    exponentPart = saturate((exponentPart + 32767.0) * r16);
    return vec4(mantissaPart, exponentPart);
}

vec3 UnpackRGBE16(vec4 x){
    float exponentPart = exp2(x.a * 65535.0 - 32767.0);
    vec3 mantissaPart = (131070.0 / 65536.0) * x.rgb;

    return exponentPart * mantissaPart;
}

vec4 PackRGB16E8P8(vec4 x){
    float exponentPart = floor(log2(max(max(x.r, x.g), x.b)));
    vec3 mantissaPart = saturate(32768.0 / 65535.0 * x.rgb / exp2(exponentPart));
    exponentPart = saturate((exponentPart + 127.0) / 255.0);

    return vec4(mantissaPart, Pack2x8(vec2(exponentPart, saturate(x.a))));
}

vec4 UnpackRGB16E8P8(vec4 x){
    vec2 u8 = Unpack2x8(x.a);
	float exponentPart = exp2(u8.x * 255.0 - 127.0);
    vec3 mantissaPart = (131070.0 / 65536.0) * x.rgb;

    return vec4(exponentPart * mantissaPart, u8.y);
}

vec3 DecodeNormalTex(vec3 texNormal){
	vec3 normal = texNormal.xyz * 2.0 - 1.0;
	#if TEXTURE_PBR_FORMAT == 1
		normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
	#endif
	normal.xy = max(abs(normal.xy) - 1.0 / 255.0, 0.0) * sign(normal.xy);
	return normal;
}

vec2 OctWrap(vec2 v) {
	return (1.0 - abs(v.yx)) * (step(0.0, v.xy) * 2.0 - 1.0);
}

vec2 EncodeNormal(vec3 n){ // Signed Octahedron.
	n.xy /= (abs(n.x) + abs(n.y) + abs(n.z));
	n.xy = n.z >= 0.0 ? n.xy : OctWrap(n.xy);

	return n.xy * 0.5 + 0.5;
}

vec3 DecodeNormal(vec2 en){ // Signed Octahedron.
	vec2 n = en * 2.0 - 1.0;

    float nz = 1.0 - abs(n.x) - abs(n.y);
	return normalize(vec3(nz >= 0 ? n : OctWrap(n), nz));
}

vec3 Blackbody(float temperature){
	// https://en.wikipedia.org/wiki/Planckian_locus
	const vec4[2] xc = vec4[2](
		vec4(-0.2661293e9,-0.2343589e6, 0.8776956e3, 0.179910), // 1667k <= t <= 4000k
		vec4(-3.0258469e9, 2.1070479e6, 0.2226347e3, 0.240390)  // 4000k <= t <= 25000k
	);
	const vec4[3] yc = vec4[3](
		vec4(-1.1063814,-1.34811020, 2.18555832,-0.20219683), // 1667k <= t <= 2222k
		vec4(-0.9549476,-1.37418593, 2.09137015,-0.16748867), // 2222k <= t <= 4000k
		vec4( 3.0817580,-5.87338670, 3.75112997,-0.37001483)  // 4000k <= t <= 25000k
	);

	float temperatureSquared = temperature * temperature;
	vec4 t = vec4(temperatureSquared * temperature, temperatureSquared, temperature, 1.0);

	float x = dot(1.0 / t, temperature < 4000.0 ? xc[0] : xc[1]);
	float xSquared = x * x;
	vec4 xVals = vec4(xSquared * x, xSquared, x, 1.0);

	vec3 xyz = vec3(0.0);
	xyz.y = 1.0;
	xyz.z = 1.0 / dot(xVals, temperature < 2222.0 ? yc[0] : temperature < 4000.0 ? yc[1] : yc[2]);
	xyz.x = x * xyz.z;
	xyz.z = xyz.z - xyz.x - 1.0;

    const mat3 xyzToSrgb = mat3(
        3.24097, -0.96924, 0.05563,
        -1.53738, 1.87597, -0.20398,
        -0.49861, 0.04156, 1.05697
    );

	return max(xyzToSrgb * xyz, vec3(0.0));
}



vec2 RaySphereIntersection(vec3 p, vec3 dir, float r){
	float b = dot(p, dir);
	float c = -r * r + dot(p, p);
	float d = b * b - c;

	if (d < 0.0) return vec2(10000.0, -10000.0);

	d = sqrt(d);

	return vec2(-b - d, -b + d);
}


float RayleighPhaseFunction(float nu) {
    return 0.059683104 * (nu * nu + 1.0);
}

float MiePhaseFunction(float g, float nu) {
    float gg = g * g;
    float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
    return k * (1.0 + nu * nu) * pow(1.0 + gg - 2.0 * g * nu, -1.5);
}



float InterleavedGradientNoise(vec2 c){
    return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
}

vec3 rand(vec2 coord){
	float noiseX = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223))) * 43758.5453));
	float noiseY = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*2.0)) * 43758.5453));
	float noiseZ = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*3.0)) * 43758.5453));

	return vec3(noiseX, noiseY, noiseZ);
}

uint triple32(uint x){
    // https://nullprogram.com/blog/2018/07/31/
    x ^= x >> 17;
    x *= 0xed5ad4bbu;
    x ^= x >> 11;
    x *= 0xac4c1b51u;
    x ^= x >> 15;
    x *= 0x31848babu;
    x ^= x >> 14;
    return x;
}

#ifdef ENABLE_RAND
	uint randState = triple32(uint(gl_FragCoord.x + screenSize.x * gl_FragCoord.y) + uint(screenSize.x * screenSize.y) * frameCounter);
	uint RandNext(){
	    return randState = triple32(randState);
	}
	#define RandNext2() uvec2(RandNext(), RandNext())
	#define RandNext3() uvec3(RandNext2(), RandNext())
	#define RandNext4() uvec4(RandNext3(), RandNext())
	#define RandNextF() (float(RandNext()) / float(0xffffffffu))
	#define RandNext2F() (vec2(RandNext2()) / float(0xffffffffu))
	#define RandNext3F() (vec3(RandNext3()) / float(0xffffffffu))
	#define RandNext4F() (vec4(RandNext4()) / float(0xffffffffu))
#endif

float bayer2(vec2 a) {
	a = floor(a);

	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(const vec2 a)   { return bayer2 (0.5   * a) * 0.25     + bayer2(a); }
float bayer8(const vec2 a)   { return bayer4 (0.5   * a) * 0.25     + bayer2(a); }
float bayer16(const vec2 a)  { return bayer4 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer32(const vec2 a)  { return bayer8 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer64(const vec2 a)  { return bayer8 (0.125 * a) * 0.015625 + bayer8(a); }
float bayer128(const vec2 a) { return bayer16(0.125 * a) * 0.015625 + bayer8(a); }
