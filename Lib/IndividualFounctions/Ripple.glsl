vec2 Get3DNoise(in vec3 pos)
{
	vec3 p = floor(pos);
	vec3 f = fract(pos);
		 f = curve(f);

	vec2 uv =  (p.xy + p.z * vec2(17.0f, 37.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f, 37.0f)) + f.xy;
	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	vec2 xy1 = texture2D(noisetex, coord).zw;
	vec2 xy2 = texture2D(noisetex, coord2).zw;
	return mix(xy1, xy2, f.z);
}

void GetModulatedRainSpecular(inout float wet, in vec3 pos)
{
	if (wet < 0.01) return;

	pos.xz *= 0.7;
	pos.y *= 0.2;

	vec3 p = pos;
	float n = Get3DNoise(p).y;
		  n += Get3DNoise(p * 0.5).x * 2.0;
		  n += Get3DNoise(p * 0.25).x * 4.0;

	n /= 7.0;

	wet *= saturate(n) * 0.7 + 0.3;
}

vec2 GetRainAnimationTex(sampler2D tex, vec2 uv, float wet)
{
	float frame = mod(floor(frameTimeCounter * 60.0), 60.0);
	vec2 coord = vec2(uv.x, mod(uv.y / 60.0, 1.0) - frame / 60.0);

	vec2 n = texture2D(tex, coord).rg * vec2(2.0, -2.0) + vec2(-1.0, 1.0);

	n = pow(abs(n), vec2((wet * wet * wet) * -1.2 + 2.0)) * sign(n);

	return n;
}

vec2 BilateralRainTex(sampler2D tex, vec2 uv, float wet)
{
	vec2 n = GetRainAnimationTex(tex, uv.xy, wet);
	vec2 nR = GetRainAnimationTex(tex, vec2(exp2(-7.0), 0.0) + uv.xy, wet);
	vec2 nU = GetRainAnimationTex(tex, vec2(0.0, exp2(-7.0)) + uv.xy, wet);
	vec2 nUR = GetRainAnimationTex(tex, vec2(exp2(-7.0)) + uv.xy, wet);

	vec2 fractCoord = fract(uv.xy * 128.0);

	vec2 lerpX = mix(n, nR, fractCoord.x);
	vec2 lerpX2 = mix(nU, nUR, fractCoord.x);
	vec2 lerpY = mix(lerpX, lerpX2, fractCoord.y);

	return lerpY;
}

vec2 GetRainNormal(in vec3 pos, inout float wet)
{
	if (wetness < 0.01) return vec2(0.0);

	pos.xyz *= 0.5;

	#ifdef RAIN_SPLASH_BILATERAL
	vec2 n1 = BilateralRainTex(gaux1, pos.xz, wet);
	vec2 n2 = BilateralRainTex(gaux2, pos.xz, wet);
	vec2 n3 = BilateralRainTex(gaux3, pos.xz, wet);
	#else
	vec2 n1 = GetRainAnimationTex(gaux1, pos.xz, wet);
	vec2 n2 = GetRainAnimationTex(gaux2, pos.xz, wet);
	vec2 n3 = GetRainAnimationTex(gaux3, pos.xz, wet);
	#endif

	pos.x -= frameTimeCounter * 1.5;
	float downfall = texture2D(noisetex, pos.xz * 0.0025).x;
	downfall = saturate(downfall - 0.25);


	vec2 n = n1;
	n += n2 * saturate(downfall * 2.0);
	n += n3 * saturate(downfall * 2.0 - 1.0);

	float lod = dot(abs(fwidth(pos.xyz)), vec3(1.0));

	n /= lod * 5.0 + 1.0;
	n *= wetness * 4.2;

	wet = saturate(mix(downfall, wet, 1.0 - 0.3 * wetness));

	return n;
}
