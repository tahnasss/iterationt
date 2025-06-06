vec4 textureSmooth(sampler2D tex, vec2 coord){
	vec2 res = vec2(64.0);

	coord *= res;
	coord += 0.5;

	vec2 whole = floor(coord);
	vec2 part  = fract(coord);

	part.x = part.x * part.x * (3.0 - 2.0 * part.x);
	part.y = part.y * part.y * (3.0 - 2.0 * part.y);

	coord = whole + part;

	coord -= 0.5;
	coord /= res;

	return texture2D(tex, coord);
}

float AlmostIdentity(float x, float m, float n){
	if (x > m) return x;

	float a = 2.0 * n - m;
	float b = 2.0 * m - 3.0 * n;
	float t = x / m;

	return (a * t + b) * t * t + n;
}


float GetWaves(vec3 position) {
    float wavesTime = frameTimeCounter * 0.0045;

	position *= WAVE_SCALE;
    vec2 p = position.xz;
    p.xy -= position.y;

    p.xy -= wavesTime * 3.875;
	p.x = -p.x;

    float weight = 1.0;
    float weights = weight;

    float allwaves = 0.0f;

    float wave = textureSmooth(noisetex, (p * vec2(2.0, 1.2)) + vec2(0.0, p.x * 2.1)).y;
            p *= 0.475;
            p.y -= wavesTime * 7.75;
            p.x -= wavesTime * 5.16;
    allwaves += wave;

    weight = 4.1;
    weights += weight;
        wave = textureSmooth(noisetex, (p * vec2(2.0, 1.4)) + vec2(0.0, -p.x * 2.1)).y;
            p *= 0.67;
            p.x += wavesTime * 7.75;
        wave *= weight;
    allwaves += wave;

    weight = 17.25;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0, 0.75)) + vec2(0.0, p.x * 1.1)).z);
            p *= 0.67;
            p.x -= wavesTime * 2.82;
        wave *= weight;
    allwaves += wave;

    weight = 15.25;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0, 0.75)) + vec2(0.0, -p.x * 1.7)).z);
            p *= 0.52;
            p.x += wavesTime;
        wave *= weight;
    allwaves += wave;

    weight = 29.25;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0, 0.8)) + vec2(0.0, -p.x * 1.7)).w * 2.0 - 1.0);
            p *= 0.5;
            p.x += wavesTime;
        wave = 1.0 - AlmostIdentity(wave, 0.2, 0.1);
        wave *= weight;
    allwaves += wave;

    weight = 15.25;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0, 0.8)) + vec2(0.0, p.x * 1.7)).w * 2.0 - 1.0);
        wave = 1.0 - AlmostIdentity(wave, 0.2, 0.1);
        wave *= weight;
    allwaves += wave;

    allwaves /= weights;

    return allwaves;
}


vec3 GetWavesNormal(vec3 position){
	const float waveHeight = 15.0 * WAVE_HEIGHT;
	const float sampleDistance = 12.0;

	position.xz -= 0.005 * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01 * sampleDistance, 0.0, 0.0));
	float wavesUp   = GetWaves(position + vec3(0.0, 0.0, 0.01 * sampleDistance));

	vec3 wavesNormal;

	wavesNormal = vec3(wavesCenter - wavesLeft, wavesCenter - wavesUp, 1.0);

	wavesNormal.rg *= waveHeight / sampleDistance;

	return normalize(wavesNormal);
}
