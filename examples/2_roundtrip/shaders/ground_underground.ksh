   ground_underground   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         GROUND_PARAMS                                NOISE_REPEAT_SIZE                     LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs�  #define ENABLE_UNDERGROUND_FADE
uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0;

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;
}

 	   ground.ps  #define ENABLE_UNDERGROUND_FADE
#if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]

#if defined(ENABLE_UNDERGROUND_FADE)
uniform vec4 GROUND_PARAMS;
#endif

uniform float NOISE_REPEAT_SIZE;

varying vec2 PS_TEXCOORD;

// Already defined by lighting.h
// varying vec3 PS_POS

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


void main()
{

	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	vec4 base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	base_colour.rgb *= texture2D( NOISE_TEXTURE, noise_uv ).rgb;

	base_colour.rgb *= CalculateLightingContribution();

#if defined(ENABLE_UNDERGROUND_FADE)
	float height_factor = 1.0 - max(min(abs(PS_POS.y) * GROUND_PARAMS.x, 1.0), 0.0);
	base_colour *= height_factor;
#endif

	if(base_colour.a < 0.105)
	{
		discard;
	}

	base_colour.rgb *= base_colour.a;


	gl_FragColor = base_colour;
}

                          