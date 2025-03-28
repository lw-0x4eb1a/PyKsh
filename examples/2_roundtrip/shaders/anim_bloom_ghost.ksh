   anim_bloom_ghost	      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                             
   TIMEPARAMS                                FLOAT_PARAMS                            SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                COLOUR_XFORM                                                                                PARAMS                            anim.vs�  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;
uniform vec3 FLOAT_PARAMS;

attribute vec4 POS2D_UV;                  // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

#if defined( FADE_OUT )
    uniform mat4 STATIC_WORLD_MATRIX;
    varying vec2 FADE_UV;
#endif

#if defined( UI_HOLO )
	varying vec3 PS_TEXCOORD1;
#endif

#if defined( HOLO )
	float filmSkipRand() // This should match the function with the same name in anim.ps
	{
		float steps = 12.;
		float c = fract(sin(ceil(TIMEPARAMS.x * steps) / steps) * 10000.);
		return (c * -.36) * step(.78, c);
	}
#endif

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	if(FLOAT_PARAMS.z > 0.0)
	{
		float world_x = MatrixW[3][0];
		float world_z = MatrixW[3][2];
		world_pos.y += sin(world_x + world_z + TIMEPARAMS.x * 3.0) * 0.025;
	}

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	#if defined( HOLO )
		float filmSkipOffset = sin(filmSkipRand()) * .4;
		gl_Position.y += filmSkipOffset;
	#endif

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;

#if defined( FADE_OUT )
	vec4 static_world_pos = STATIC_WORLD_MATRIX * vec4( POSITION.xyz, 1.0 );
    vec3 forward = normalize( vec3( MatrixV[2][0], 0.0, MatrixV[2][2] ) );
    float d = dot( static_world_pos.xyz, forward );
    vec3 pos = static_world_pos.xyz + ( forward * -d );
    vec3 left = cross( forward, vec3( 0.0, 1.0, 0.0 ) );

    FADE_UV = vec2( dot( pos, left ) / 4.0, static_world_pos.y / 8.0 );
#endif

#if defined( UI_HOLO )
	PS_TEXCOORD1 = gl_Position.xyw;
#endif
}

    anim_bloom_ghost.ps*  #if defined( GL_ES )
precision mediump float;
#endif

#define BLOOM_STRENGTH 0.4

uniform mat4 MatrixW;


#if defined( TRIPLE_ATLAS )
   uniform sampler2D SAMPLER[6];
#else
   uniform sampler2D SAMPLER[4];
#endif

#ifndef LIGHTING_H
#define LIGHTING_H

#if !defined( UI_CC )
// Lighting
varying vec3 PS_POS;
#endif

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

#if defined( UI_CC )
vec3 CalculateLightingContribution(vec2 pos)
{
	vec2 uv = ( pos - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}
#else
vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}
#endif

#endif //LIGHTING.h


varying vec3 PS_TEXCOORD;

uniform mat4 COLOUR_XFORM;
uniform vec3 PARAMS;
uniform vec4 HAUNTPARAMS;
uniform vec3 CAMERARIGHT;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y
#define BLOOM_TOGGLE PARAMS.z

#if defined( FADE_OUT )
    uniform vec3 EROSION_PARAMS; 
    varying vec2 FADE_UV;

    #define ERODE_SAMPLER SAMPLER[2]
    #define EROSION_MIN EROSION_PARAMS.x
    #define EROSION_RANGE EROSION_PARAMS.y
    #define EROSION_LERP EROSION_PARAMS.z
#endif

void main()
{
    vec4 colour;

#if defined( TRIPLE_ATLAS )
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else if( PS_TEXCOORD.z < 1.5 )
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[5], PS_TEXCOORD.xy );
    }
#else
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
#endif

    if( colour.a >= ALPHA_TEST )
    {

		gl_FragColor.rgba = colour.rgba * COLOUR_XFORM;
		gl_FragColor.rgb = min(gl_FragColor.rgb, gl_FragColor.a);

#if defined( FADE_OUT )
        float height = texture2D( ERODE_SAMPLER, FADE_UV.xy ).a;
        float erode_val = clamp( ( height - EROSION_MIN ) / EROSION_RANGE, 0.0, 1.0 );
        gl_FragColor.rgba = mix( gl_FragColor.rgba, gl_FragColor.rgba * erode_val, EROSION_LERP );
#endif

        vec3 light = CalculateLightingContribution();

        gl_FragColor.rgb *= max( light.rgb, vec3( LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE ) );
		gl_FragColor.rgb *= BLOOM_STRENGTH;

#if defined( HAUNT )
		// first part should move to the vertex shader
  	  	float xp = PS_POS.x;
  	  	float yp = PS_POS.y;
  	  	float zp = PS_POS.z;

#if 1	// do it in local space (so moving objects don't expose a world space pattern)
		float objx = MatrixW[3][0];
		xp -= objx;
		float objz = MatrixW[3][2];
		zp -= objz;
		// Add in a random base to desynchronise identical objects
		xp += HAUNTPARAMS.y;
		zp += HAUNTPARAMS.y;
		yp += HAUNTPARAMS.y;
#endif

		const float PI = 3.1415;
		const float TWO_PI = 2.0 * PI;

		xp *= 5.;
		yp *= 5.;
		zp *= 5.;

		float time = HAUNTPARAMS.x * 3.0;

		float cx = CAMERARIGHT.x;
		float cz = CAMERARIGHT.z;

		float resx = cx * xp;
		float resz = cz * zp;

		float x = resx+resz;
		float y = yp;

		// scale the effect
		x *= 5.0 * HAUNTPARAMS.w;	
		y *= 5.0 * HAUNTPARAMS.w;

		float strength = HAUNTPARAMS.z;
		float rnd = sin(HAUNTPARAMS.y);
#if defined(BLOOM)
		// Hmmm, still unsure if it looks better with bloom at a different rate. It adds some obfuscation to the pattern
		time *= -2.0;
#else
		time *= 3.0;
#endif
		float pix = 
        (
              (sin((x + time * 7.0) / (12.0+rnd)))
            + (cos((y + time * 1.5)  / (7.0-rnd)))
            + (sin((x + y + 3.0 * time ) / (16.0 + 0.3 * sin(time / 100.0))))
            + (sin(sqrt((x * x + y * y)) / (8.0+rnd)))
        ) / 4.0;

		// either this:
		pix = 0.5 + 0.5 * sin(pix * PI);
		// or this
		//pix = 0.5 + 0.5 * pix;
		//pix = 0.5 + 0.5 * sin(pix * TWO_PI);

		float orig_a = gl_FragColor.a;
		// pix is the new alpha
		// Take the alpha out of the source pixel
		gl_FragColor.rgb /= orig_a;	

		// approx saturation
		float avg = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
		float sat = avg;

//if (pix > 0.8) pix = 0.8;
//if (pix < 0.95) pix = 0.0;

		float r = gl_FragColor.r;
		float g = gl_FragColor.g;
		float b = gl_FragColor.b;
		float r2 = r * 3.0;
		float g2 = g * 3.0;
		float b2 = b * 3.0;
		vec3 rgb2 = vec3(r2,g2,b2);

		//gl_FragColor.rgb = 0.01 * gl_FragColor.rgb + vec3(sat,sat,sat);
		pix = pix * strength;
		gl_FragColor.rgb = (1.0-pix) * gl_FragColor.rgb + pix * rgb2;

		// Multiply in the original alpha
		gl_FragColor.r *= orig_a;
		gl_FragColor.g *= orig_a;
		gl_FragColor.b *= orig_a;

#if defined(BLOOM)
		// This condition isn't needed but if I take it out opengl errs out because sampler accesses are optimized out
//		if ((HAUNTPARAMS.y > 0.5))	// 1 in the bloompass. Could also multiply instead
		{
			float v = pix;
			v *= 0.5;
			v *= orig_a;
			v *= strength;
			// To stop OpenGL on crapping out on unused samplers.....
			gl_FragColor = gl_FragColor * 0.0001 + vec4(v,v,v,orig_a) * 0.9999;
		}
#endif
		// To see the plasma

#endif  
    }
    else
    {
        discard;
    }
}

                                   