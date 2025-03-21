   road   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         GROUND_REPEAT_VEC                        LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs_  uniform mat4 MatrixPVW;
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

    road.ps(  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]

uniform vec2 GROUND_REPEAT_VEC;

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
	vec2 noise_uv = PS_POS.xz / GROUND_REPEAT_VEC.x;

	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );

	vec4 base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD.xy );
	base_colour.rgb /= base_colour.a;
	base_colour.rgb *= noise.rgb;

	gl_FragColor.rgb = base_colour.rgb * CalculateLightingContribution();
	gl_FragColor.a = noise.a * base_colour.a;
	gl_FragColor.rgb *= gl_FragColor.a;
}
                       