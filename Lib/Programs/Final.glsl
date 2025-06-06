#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


in vec2 texcoord;

#ifndef DIMENSION_NETHER
	//uniform sampler2D shadowcolor1;
#endif


#include "/Lib/Uniform/GbufferTransforms.glsl"


float printNumbers(int Num, vec2 lowerLeft, float scale, ivec2 pixelShift)
{
	const int numTexSize = 100;
	float number = 0.0;

	vec2 tcoord = texcoord.st;

	vec2 pixel = pixelSize * scale;

	tcoord -= lowerLeft  + pixelShift * pixel;

	if (tcoord.x >= 0.0
	  &&tcoord.x <= 5.0 * pixel.x
	  &&tcoord.y >= 0.0
	  &&tcoord.y <= 7.0 * pixel.y)
	{
		tcoord  += vec2(6.0, 0.0) * Num * pixel;

		vec2 pixelCoord = tcoord * screenSize * vec2(1.0, -1.0) / numTexSize;
		pixelCoord /= scale;

		number += texture(colortex12, pixelCoord).a;
	}

	return number;
}


float counter(float x, vec2 lowerLeft, float scale, ivec2 pixelShift)
{
	float result = 0.0;

	vec2 tcoord = texcoord.st - lowerLeft - pixelShift * pixelSize * scale;

	if (tcoord.x >= 0.0
	 && tcoord.x <= 0.3
	 && tcoord.y >= 0.0
	 && tcoord.y <= pixelSize.y * scale * 7.0)
	{
		uint bitsData = floatBitsToUint(x);

		int S = 0;
		int E = -127;
		int I = 0;
		float F = 0.0;

		uint tmp1 = bitsData;
		for (int i = 0; i <= 31; i++)
		{
			int a = int(tmp1 % 2);
			if (i == 31) {
				S += a;
			}else if (i >= 23 && i <= 30) {
				E += a * int(exp2(i - 23));
			}

			tmp1 = uint(tmp1 / 2);
		}

		uint tmp2 = bitsData;
		for (int i = 0; i <= 22; i++)
		{
			int a = int(tmp2 % 2);
			int p = i - 23 + E;
			if (p >=0)
			{
				I += a * int(exp2(p));
			}else{
				F += a * exp2(p);
			}
			tmp2 = uint(tmp2 / 2);
		}

		if (E >=0){
			I += int(exp2(E));
		}else{
			F += exp2(E);
		}


		if(S == 1)
		{
			result += printNumbers(10, lowerLeft, scale, pixelShift);
			pixelShift.x += 6;
		}

		int ic = int(floor(log2(I) / log2(10.0))) + 1;

		if (ic <= 0)
		{
			result += printNumbers(0, lowerLeft, scale, pixelShift);
			pixelShift.x += 6;
		}else{
			for(int i = ic; i >=1; i--)
			{
				int Num = int(floor(I / pow(10.0, i-1)));
				result += printNumbers(Num, lowerLeft, scale, pixelShift);
				pixelShift.x += 6;
				I = int(mod(I, pow(10.0, i-1)));
			}
		}

		if(F != 0.0){
			result += printNumbers(12, lowerLeft, scale, pixelShift);
			pixelShift.x += 2;

			for(int i = 1; i <=5; i++)
			{
				int Num = int(floor(mod(F * pow(10.0, i), 10.0)));
				result += printNumbers(Num, lowerLeft, scale, pixelShift);
				pixelShift.x += 6;

			}
		}
	}

	return result;
}


const float overlap = 0.2;

const float rgOverlap = 0.1 * overlap;
const float rbOverlap = 0.01 * overlap;
const float gbOverlap = 0.04 * overlap;

const mat3 coneOverlap = mat3(1.0, 			rgOverlap, 	rbOverlap,
							  rgOverlap, 	1.0, 		gbOverlap,
							  rbOverlap, 	rgOverlap, 	1.0);

const mat3 coneOverlapInverse = mat3(	1.0 + (rgOverlap + rbOverlap), 			-rgOverlap, 	-rbOverlap,
									  	-rgOverlap, 		1.0 + (rgOverlap + gbOverlap), 		-gbOverlap,
									  	-rbOverlap, 		-rgOverlap, 	1.0 + (rbOverlap + rgOverlap));

vec3 SEUSTonemap(vec3 color)
{
	color = color * coneOverlap;



	const float p = TONEMAP_CURVE * 5.0;
	color = pow(color, vec3(p));
	color = color / (1.0 + color);
	color = pow(color, vec3(1.0 / p));


	color = color * coneOverlapInverse;
	color = saturate(color);

	return color;
}

/////////////////////////////////////////////////////////////////////////////////

vec3 HableTonemap(vec3 color)
{

	color = color * coneOverlap;

	color *= 1.25;

	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.00;
	const float F = 0.30;

	color = pow(color, vec3(TONEMAP_CURVE * 5.0));

   	vec3 result = pow((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F), vec3(1.0 / (TONEMAP_CURVE * 5.0)))-E/F;
   	result = saturate(result);


   	result = result * coneOverlapInverse;

   	return result;
}

/////////////////////////////////////////////////////////////////////////////////

vec3 UchimuraTonemap(vec3 color) {
    const float P = 1.0;  // max display brightness Default:1.2
    const float a = 0.85;  // contrast Default:0.625
    const float m = 0.175; // linear section start Default:0.1
    const float l = 0.15;  // linear section length Default:0.0
    const float c = 1.425; // black Default:1.33
    const float b = 0.0;  // pedestal


    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = 1.0 - smoothstep(0.0, m, color);
    vec3 w2 = step(m + l0, color);
    vec3 w1 = 1.0 - w0 - w2;

	vec3 T = m * pow(color / vec3(m), vec3(c)) + vec3(b);
    vec3 S = P - (P - S1) * exp(CP * (color - S0));
    vec3 L = m + a * (color - m);

	color = color * coneOverlap;

    color = T * w0 + L * w1 + S * w2;

	color = color * coneOverlapInverse;
    color = saturate(color);

	return color;
}

/////////////////////////////////////////////////////////////////////////////////

vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786f) - 0.000090537f;
    vec3 b = v * (1.0f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

vec3 ACESTonemap2(vec3 color)
{
	color *= 1.4;
	color = color * coneOverlap;
	color = pow(color, vec3(TONEMAP_CURVE));

    color = RRTAndODTFit(color);

	color = color * coneOverlapInverse;

    return color;
}

/////////////////////////////////////////////////////////////////////////////////

vec3 LottesTonemap(vec3 color)
{
	color *= 5.0;  // Default: 5.0



	// float peak = max(max(color.r, color.g), color.b);
	float peak = Luminance(color);
	vec3 ratio = color / peak;


	//Tonemap here
	const float contrast = 1.0; // Default: 1.1
	const float shoulder = 1.0;
	const float b = 1.0;	//Clipping point
	const float c = 3.0;	//Speed of compression. Default: 5.0

	peak = pow(peak, 1.6);

	float x = peak;
	float z = pow(x, contrast);
	peak = z / (pow(z, shoulder) * b + c);

	peak = pow(peak, 1.0 / 1.6);

	vec3 tonemapped = peak * ratio;


	float tonemappedMaximum = Luminance(tonemapped);
	vec3 crosstalk = vec3(5.0, 0.5, 5.0) * 2.0;
	float saturation = 0.75;  // Default: 1.1
	float crossSaturation = 1280.0;  // Default: 1114.0

	ratio = pow(ratio, vec3(saturation / crossSaturation));
	ratio = mix(ratio, vec3(1.0), pow(vec3(tonemappedMaximum), crosstalk));
	ratio = pow(ratio, vec3(crossSaturation));

	vec3 outputColor = peak * ratio;

	return outputColor;
}

vec3 ACESTonemap(vec3 color){
	const float a = 2.51f;  // Default: 2.51f
	const float b = 0.03f;  // Default: 0.03f
	const float c = 2.43f;  // Default: 2.43f
	const float d = 0.59f;  // Default: 0.59f
	const float e = 0.14f;  // Default: 0.14f

	const float p = 1.3;

	color = color * coneOverlap;

	color = pow(color, vec3(p));

	color = (color * (a * color + b)) / (color * (c * color + d) + e);

	color = pow(color, vec3(1.0 / p));

	color = color * coneOverlapInverse;

	color = saturate(color);



	return color;
}

vec3 None(vec3 color){
	return color;
}

#ifdef DIMENSION_NETHER
	vec3 Default(vec3 color){
		return UchimuraTonemap(color);
	}
#else
	vec3 Default(vec3 color){
		return ACESTonemap2(color);
	}
#endif

float AverageExposure(){
	return CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a);
}


vec3 xyY_2_XYZ(vec3 xyY) {
	vec3 XYZ   = vec3(0.0);
	     XYZ.r = xyY.r * xyY.b / max(xyY.g, 1e-10);
	     XYZ.g = xyY.b;
	     XYZ.b = (1.0 - xyY.r - xyY.g) * xyY.b / max(xyY.g, 1e-10);

	return XYZ;
}

mat3 ChromaticAdaptation( vec2 src_xy, vec2 dst_xy ) {
	// Von Kries chromatic adaptation

	// Bradford
	const mat3 ConeResponse = mat3(
		 vec3(0.8951,  0.2664, -0.1614),
		vec3(-0.7502,  1.7135,  0.0367),
		 vec3(0.0389, -0.0685,  1.0296)
	);
	const mat3 InvConeResponse = mat3(
		vec3(0.9869929, -0.1470543,  0.1599627),
		vec3(0.4323053,  0.5183603,  0.0492912),
		vec3(-0.0085287,  0.0400428,  0.9684867)
	);

	vec3 src_XYZ = xyY_2_XYZ( vec3( src_xy, 1 ) );
	vec3 dst_XYZ = xyY_2_XYZ( vec3( dst_xy, 1 ) );

	vec3 src_coneResp = src_XYZ * ConeResponse;
	vec3 dst_coneResp = dst_XYZ *  ConeResponse;

	mat3 VonKriesMat = mat3(
		vec3(dst_coneResp[0] / src_coneResp[0], 0.0, 0.0),
		vec3(0.0, dst_coneResp[1] / src_coneResp[1], 0.0),
		vec3(0.0, 0.0, dst_coneResp[2] / src_coneResp[2])
	);

	return (ConeResponse * VonKriesMat) * InvConeResponse;
}

const mat3 sRGB_2_XYZ_MAT = mat3( // Linear sRGB to XYZ color space
	vec3(0.4124564, 0.3575761, 0.1804375),
	vec3(0.2126729, 0.7151522, 0.0721750),
	vec3(0.0193339, 0.1191920, 0.9503041)
);

const mat3 XYZ_2_sRGB_MAT = mat3( //XYZ to linear sRGB Color Space
	vec3(3.2409699419, -1.5373831776, -0.4986107603),
	vec3(-0.9692436363,  1.8759675015,  0.0415550574),
	vec3(0.0556300797, -0.2039769589,  1.0569715142)
);

vec2 PlanckianLocusChromaticity(float Temp) {
	float u = ( 0.860117757f + 1.54118254e-4f * Temp + 1.28641212e-7f * Temp*Temp ) / ( 1.0f + 8.42420235e-4f * Temp + 7.08145163e-7f * Temp*Temp );
	float v = ( 0.317398726f + 4.22806245e-5f * Temp + 4.20481691e-8f * Temp*Temp ) / ( 1.0f - 2.89741816e-5f * Temp + 1.61456053e-7f * Temp*Temp );

	float x = 3.0*u / ( 2.0*u - 8.0*v + 4.0 );
	float y = 2.0*v / ( 2.0*u - 8.0*v + 4.0 );

	return vec2(x, y);
}

 vec2 D_IlluminantChromaticity(float Temp) {
	// Accurate for 4000K < Temp < 25000K
	// in: correlated color temperature
	// out: CIE 1931 chromaticity
	// Correct for revision of Plank's law
	// This makes 6500 == D65
	Temp *= 1.000556328;

	float x =	Temp <= 7000 ?
				0.244063 + ( 0.09911e3 + ( 2.9678e6 - 4.6070e9 / Temp ) / Temp ) / Temp :
				0.237040 + ( 0.24748e3 + ( 1.9018e6 - 2.0064e9 / Temp ) / Temp ) / Temp;

	float y = -3 * x*x + 2.87 * x - 0.275;

	return vec2(x,y);
}

vec2 PlanckianIsothermal( float Temp, float Tint ) {
	float u = ( 0.860117757f + 1.54118254e-4f * Temp + 1.28641212e-7f * Temp*Temp ) / ( 1.0f + 8.42420235e-4f * Temp + 7.08145163e-7f * Temp*Temp );
	float v = ( 0.317398726f + 4.22806245e-5f * Temp + 4.20481691e-8f * Temp*Temp ) / ( 1.0f - 2.89741816e-5f * Temp + 1.61456053e-7f * Temp*Temp );

	float ud = ( -1.13758118e9f - 1.91615621e6f * Temp - 1.53177f * Temp*Temp ) / pow( 1.41213984e6f + 1189.62f * Temp + Temp*Temp, 2.0 );
	float vd = (  1.97471536e9f - 705674.0f * Temp - 308.607f * Temp*Temp ) / pow( 6.19363586e6f - 179.456f * Temp + Temp*Temp , 2.0); //don't pow2 this

	vec2 uvd = normalize( vec2( u, v ) );

	// Correlated color temperature is meaningful within +/- 0.05
	u += -uvd.y * Tint * 0.05;
	v +=  uvd.x * Tint * 0.05;

	float x = 3*u / ( 2*u - 8*v + 4 );
	float y = 2*v / ( 2*u - 8*v + 4 );

	return vec2(x,y);
}

vec3 WhiteBalance(vec3 LinearColor) {
	const float WhiteTemp = float(WHITE_BALANCE);
	const float WhiteTint = float(TINT_BALANCE) * 0.25;
	vec2 SrcWhiteDaylight = D_IlluminantChromaticity( WhiteTemp );
	vec2 SrcWhitePlankian = PlanckianLocusChromaticity( WhiteTemp );

	vec2 SrcWhite = WhiteTemp < 4000 ? SrcWhitePlankian : SrcWhiteDaylight;
	const vec2 D65White = vec2(0.31270,  0.32900);

	// Offset along isotherm
	vec2 Isothermal = PlanckianIsothermal( WhiteTemp, WhiteTint ) - SrcWhitePlankian;
	SrcWhite += Isothermal;

	mat3x3 WhiteBalanceMat = ChromaticAdaptation( D65White, SrcWhite );
	WhiteBalanceMat = (sRGB_2_XYZ_MAT * WhiteBalanceMat) * XYZ_2_sRGB_MAT;

	return LinearColor * WhiteBalanceMat;
}


vec3 Lookup(vec3 color, sampler2D lookupTable) {
    float blueColor = color.b * 63.0;

    vec4 quad = vec4(0.0);
    quad.y = floor(floor(blueColor) * 0.125);
    quad.x = floor(blueColor) - (quad.y * 8.0);
	quad.w = floor(ceil(blueColor) * 0.125);
    quad.z = ceil(blueColor) - (quad.w * 8.0);

    vec4 texPos = ((quad * 0.125) + (0.123046875 * color.rg).xyxy + 0.0009765625);

    vec3 newColor1 = texture(lookupTable, texPos.xy).rgb;
    vec3 newColor2 = texture(lookupTable, texPos.zw).rgb;

    return mix(newColor1, newColor2, fract(blueColor));
}

float BlackBar(float newRatio){
	if (newRatio == 0.0) return 1.0;
	float width = max(-newRatio / aspectRatio * 0.5 + 0.5, 0.0);
	float height = max(-aspectRatio / newRatio * 0.5 + 0.5, 0.0);

	return step(width, texcoord.x)
	 	 * step(texcoord.x, 1.0 - width)
		 * step(height, texcoord.y)
		 * step(texcoord.y, 1.0 - height);
}



/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec3 color = texture(colortex1, texcoord).rgb;

	#if POST_SHARPENING > 0
	{
		vec3 cs = 	(texture(colortex1, texcoord + vec2(pixelSize.x, pixelSize.y) * 0.5).rgb);
		cs += 		(texture(colortex1, texcoord + vec2(pixelSize.x, -pixelSize.y) * 0.5).rgb);
		cs += 		(texture(colortex1, texcoord + vec2(-pixelSize.x, pixelSize.y) * 0.5).rgb);
		cs += 		(texture(colortex1, texcoord + vec2(-pixelSize.x, -pixelSize.y) * 0.5).rgb);
		cs -= 		color;
		cs /= 		3.0;

		color += saturate(clamp(dot(color - cs, vec3(0.333333)), -0.001, 0.001) * 12.3 * float(POST_SHARPENING) * pow(Luminance(color), 0.5) * normalize(color.rgb + 0.00000001));
	}
	#endif

	color = CurveToLinear(color);


	#ifdef MANUAL_EXPOSURE
		float ev = EV_VALUE;
		ev = 1.5e5 * mainOutputFactor / pow(2.0, ev);

		color *= ev;
	#else
		float ae = AverageExposure() * 35.0;
		float ep = ae;

		float curve = AE_CURVE;
		#ifdef AE_CLAMP
			curve *= remap(2.0, 1.0, ae) * 0.5 + 0.5;
		#endif
		curve = mix(curve, 0.95, nightVision);
		#ifdef DIMENSION_NETHER
			curve *= 0.8;
		#endif
		ae = 1.0 / pow(ae, curve);

		float evOffset = AE_OFFSET;
		ae *= evOffset < 0.0 ? 1.0 / pow(2.0, -evOffset) : pow(2.0, evOffset);

		color *= 7.0 * mainOutputFactor * ae;
	#endif


	color = TONEMAP_OPERATOR(color);

	#ifdef ADVANCED_COLOR
		color = pow(length(color), 1.0 / LUMA_GAMMA) * normalize(color + 0.00001);
		color = saturate(color * (1.0 + WHITE_CLIP));

		color = WhiteBalance(color);

		color = saturate(pow(LinearToGamma(color), vec3((1.0 / GAMMA))));
		color = mix(color, vec3(Luminance(color)), vec3(1.0 - SATURATION));
	#else
		color = LinearToGamma(color);
	#endif


	#ifdef LUT
	{
		color = saturate(color);
		color = Lookup(color, colortex8);
	}
	#endif

	color += InterleavedGradientNoise(gl_FragCoord.xy) * (1.0 / 255.0);

	color *= BlackBar(SEREEN_RATIO);

	//color = texelFetch(shadowcolor1, ivec2(gl_FragCoord.xy * 2.0), 0).rgb;

	//color = texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0).rgb;

	//color = vec3(pow(texelFetch(colortex7, ivec2(gl_FragCoord.xy), 0).a, 1000.0));


	#ifdef DEBUG_COUNTER
		color.rgb = saturate(color.rgb);

		if (texcoord.s >= 0.0
		 && texcoord.s <= 300 * pixelSize.x
		 && texcoord.t >= 1.0 - 200 * pixelSize.y
		 && texcoord.t <= 1.0)
		 {
			color.rgb = clamp(color.rgb * 0.5, vec3(0.0), vec3(0.8));
		 }
		 vec2 sc = vec2(70.0 * pixelSize.x, 1.0 - 70.0 * pixelSize.y);

		 color.rgb += counter(ae, sc, 3.0, ivec2(0,0));
		 color.rgb += counter(ep, sc, 3.0, ivec2(0,-10));
	#endif


	gl_FragColor = vec4(color.rgb, 1.0f);
}
