//Terrain_VS


#include "/Lib/Settings.glsl"

uniform sampler2D noisetex;


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform float wetness;

uniform vec2 taaJitter;


#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
layout(location = 12) in vec4 mc_midTexCoord;
layout(location = 13) in vec4 at_tangent;
#else
layout(location = 10) in vec4 mc_Entity;
layout(location = 11) in vec4 mc_midTexCoord;
layout(location = 12) in vec4 at_tangent;
#endif


out vec4 v_color;
out vec2 v_texcoord;
out vec4 v_viewPos;
out vec3 v_worldPos;
out mat3 v_tbn;
//out float dist;
out vec2 v_blockLight;
flat out float v_materialIDs;
out float v_noWetItem;


vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	int resolution = 64;

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}



void main(){
    v_color = gl_Color;
    v_texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    v_blockLight.x = clamp(lmcoord.x * 1.066875 - 0.0334375, 0.0, 1.0);
    v_blockLight.y = clamp(lmcoord.y * 1.066875 - 0.0334375, 0.0, 1.0);


    v_viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 position = gbufferModelViewInverse * v_viewPos;
    position.xyz += cameraPosition.xyz;

    int entityID = int(mc_Entity.x);

    #ifdef WAVING_PLANTS
        float tick = frameTimeCounter * ANIMATION_SPEED;

        float lightWeight = clamp(v_blockLight.y * 1.5 - 0.5, 0.0, 1.0);
        	  lightWeight = lightWeight * lightWeight;
              lightWeight = lightWeight * lightWeight;

        float grassWeight = step(gl_MultiTexCoord0.y, mc_midTexCoord.y);


        if (entityID == 7020){
                grassWeight = grassWeight * 0.7;
        }else
        if (entityID == 7021){
                grassWeight = grassWeight * 0.7 + 0.7;
        }

        const float pi = 3.14159265359;



    //grass//
    	if (entityID == 7010 || entityID == 7020 || entityID == 7021)
    	{
    		vec2 angleLight = vec2(0.0f);
    		vec2 angleHeavy = vec2(0.0f);
    		vec2 angle 		= vec2(0.0f);

    		vec3 pn0 = position.xyz;
    			 pn0.x -= frameTimeCounter * ANIMATION_SPEED / 3.0f;

    		vec3 stoch = BicubicTexture(noisetex, pn0.xz / 64.0f).xyz;
    		vec3 stochLarge = BicubicTexture(noisetex, position.xz / (64.0f * 6.0f)).xyz;

    		vec3 pn = position.xyz;
    			 pn.x *= 2.0f;
    			 pn.x -= frameTimeCounter * ANIMATION_SPEED * 15.0f;
    			 pn.z *= 8.0f;

    		vec3 stochLargeMoving = BicubicTexture(noisetex, pn.xz / (64.0f * 10.0f)).xyz;



    		vec3 p = position.xyz;
    		 	 p.x += sin(p.z / 2.0f) * 1.0f;
    		 	 p.xz += stochLarge.rg * 5.0f;

    		float windStrength = mix(0.85f, 1.0f, wetness);
    		float windStrengthRandom = stochLargeMoving.x;
    			  windStrengthRandom = pow(windStrengthRandom, mix(2.0f, 1.0f, wetness));
    			  windStrength *= mix(windStrengthRandom, 0.5f, wetness * 0.25f);
    			  //windStrength = 1.0f;

    		//heavy wind
    		float heavyAxialFrequency 			= 8.0f;
    		float heavyAxialWaveLocalization 	= 0.9f;
    		float heavyAxialRandomization 		= 13.0f;
    		float heavyAxialAmplitude 			= 15.0f;
    		float heavyAxialOffset 				= 15.0f;

    		float heavyLateralFrequency 		= 6.732f;
    		float heavyLateralWaveLocalization 	= 1.274f;
    		float heavyLateralRandomization 	= 1.0f;
    		float heavyLateralAmplitude 		= 6.0f;
    		float heavyLateralOffset 			= 0.0f;

    		//light wind
    		float lightAxialFrequency 			= 5.5f;
    		float lightAxialWaveLocalization 	= 1.1f;
    		float lightAxialRandomization 		= 21.0f;
    		float lightAxialAmplitude 			= 5.0f;
    		float lightAxialOffset 				= 5.0f;

    		float lightLateralFrequency 		= 5.9732f;
    		float lightLateralWaveLocalization 	= 1.174f;
    		float lightLateralRandomization 	= 0.0f;
    		float lightLateralAmplitude 		= 1.0f;
    		float lightLateralOffset 			= 0.0f;

    		float windStrengthCrossfade = clamp(windStrength * 2.0f - 1.0f, 0.0f, 1.0f);
    		float lightWindFade = clamp(windStrength * 2.0f, 0.2f, 1.0f);

    		angleLight.x += sin(frameTimeCounter * ANIMATION_SPEED * lightAxialFrequency 	- p.x * lightAxialWaveLocalization		+ stoch.x * lightAxialRandomization) 	* lightAxialAmplitude 		+ lightAxialOffset;
    		angleLight.y += sin(frameTimeCounter * ANIMATION_SPEED * lightLateralFrequency 	- p.x * lightLateralWaveLocalization 	+ stoch.x * lightLateralRandomization) 	* lightLateralAmplitude  	+ lightLateralOffset;

    		angleHeavy.x += sin(frameTimeCounter * ANIMATION_SPEED * heavyAxialFrequency 	- p.x * heavyAxialWaveLocalization		+ stoch.x * heavyAxialRandomization) 	* heavyAxialAmplitude 		+ heavyAxialOffset;
    		angleHeavy.y += sin(frameTimeCounter * ANIMATION_SPEED * heavyLateralFrequency 	- p.x * heavyLateralWaveLocalization 	+ stoch.x * heavyLateralRandomization) 	* heavyLateralAmplitude  	+ heavyLateralOffset;

    		angle = mix(angleLight * lightWindFade, angleHeavy, vec2(windStrengthCrossfade));
    		angle *= 2.0f;

    		// //Rotate block pivoting from bottom based on angle
    		position.x += (sin((angle.x / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
    		position.z += (sin((angle.y / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
    		position.y += (cos(((angle.x + angle.y) / 180.0f) * 3.141579f) - 1.0f)  * grassWeight * lightWeight	* 0.5f	;
    	}



    //Wheat//
    	if (entityID == 7011)
        {
            {
        		float speed = 0.1;

        		float magnitude = sin((tick * pi / (28.0)) + position.x + position.z) * 0.12 + 0.02;
        			  magnitude *= grassWeight * 0.2f;
        			  magnitude *= lightWeight;
        		float d0 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5 + position.z;
        		float d1 = sin(tick * pi / (152.0 * speed)) * 3.0 - 1.5 + position.x;
        		float d2 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5 + position.x;
        		float d3 = sin(tick * pi / (152.0 * speed)) * 3.0 - 1.5 + position.z;
        		position.x += sin((tick * pi / (28.0 * speed)) + (position.x + d0) * 0.1 + (position.z + d1) * 0.1) * magnitude;
        		position.z += sin((tick * pi / (28.0 * speed)) + (position.z + d2) * 0.1 + (position.x + d3) * 0.1) * magnitude;
        	}

    	//small leaf movement
            {
        		float speed = 0.04;

        		float magnitude = (sin(((position.y + position.x)/2.0 + tick * pi / ((28.0)))) * 0.025 + 0.075) * 0.2;
        			  magnitude *= grassWeight;
        			  magnitude *= lightWeight;
        		float d0 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
        		float d1 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
        		float d2 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
        		float d3 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
        		position.x += sin((tick * pi / (18.0 * speed)) + (-position.x + d0)*1.6 + (position.z + d1)*1.6) * magnitude * (1.0f + wetness * 2.0f);
        		position.z += sin((tick * pi / (18.0 * speed)) + (position.z + d2)*1.6 + (-position.x + d3)*1.6) * magnitude * (1.0f + wetness * 2.0f);
        		position.y += sin((tick * pi / (11.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/3.0) * (1.0f + wetness * 2.0f);
            }
        }


    //Leaves//
    	if (entityID == 7030)
        {
    		float speed = 0.05;


    			  //lightWeight = max(0.0f, 1.0f - (lightWeight * 5.0f));

    		float magnitude = (sin((position.y + position.x + tick * pi / ((28.0) * speed))) * 0.15 + 0.15) * 0.30 * lightWeight * 0.2;
    			  // magnitude *= grassWeight;
    			  magnitude *= lightWeight;
    		float d0 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
    		float d1 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
    		float d2 = sin(tick * pi / (132.0 * speed)) * 3.0 - 1.5;
    		float d3 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5;
    		position.x += sin((tick * pi / (18.0 * speed)) + (-position.x + d0)*1.6 + (position.z + d1)*1.6) * magnitude * (1.0f + wetness * 1.0f);
    		position.z += sin((tick * pi / (17.0 * speed)) + (position.z + d2)*1.6 + (-position.x + d3)*1.6) * magnitude * (1.0f + wetness * 1.0f);
    		position.y += sin((tick * pi / (11.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/2.0) * (1.0f + wetness * 1.0f);

        }
    #endif

    v_worldPos = position.xyz;

    position.xyz -= cameraPosition.xyz;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

    #ifdef TAA
        gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    #endif


    vec3 N = normalize(gl_NormalMatrix * gl_Normal);
    vec3 T = normalize(gl_NormalMatrix * at_tangent.xyz);
    vec3 B = cross(T, N) * sign(at_tangent.w);
    v_tbn = mat3(T, B, N);


    v_materialIDs = 1.0;
    v_noWetItem = 0.0;

    #ifdef MOD_BLOCK_SUPPORT
    #endif

    #ifdef GENERAL_GRASS_FIX
        if (clamp(abs(gl_Normal), vec3(0.01), vec3(0.99)) == abs(gl_Normal)){
            v_materialIDs = 2.0;
        }
    #endif

    switch(entityID){
    //2 grass
        case 7000: case 7010: case 7011: case 7020: case 7021: case 7040:
            v_materialIDs = 2.0;
            v_noWetItem = 0.25;
            break;
    //3 leaves
        case 7030:
            v_materialIDs = 3.0;
            v_noWetItem = 0.125;
            break;
    //25 torch
        case 50:
            v_materialIDs = 25.0;
            break;
    //26 lava
        case 10:
            v_materialIDs = 26.0;
            v_noWetItem = 1.0;
            break;
    //27 glowstone and lamp
        case 89:
            v_materialIDs = 27.0;
            break;
    //28 fire
        case 51:
            v_materialIDs = 28.0;
            v_noWetItem = 1.0;
            break;
    //29 redstone_torch
        case 76:
            v_materialIDs = 29.0;
            break;
    //30 redstone
        case 55:
            v_materialIDs = 30.0;
            break;
    //31 soul_fire
        case 7100:
            v_materialIDs = 31.0;
            break;
    //32 amethyst
        case 7101:
            v_materialIDs = 32.0;
    }
}
