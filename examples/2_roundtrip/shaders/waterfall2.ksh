
   waterfall2	   	   MatrixPVW                                                                                MatrixW                                                                                UV_OFFSET_LAYER_01                        UV_OFFSET_LAYER_02                        SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                WATERFALL_FADE_PARAMS                                WATERFALL_NOISE_PARAMS0                                WATERFALL_NOISE_PARAMS1                                waterfall2.vs'  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;
uniform vec2 UV_OFFSET_LAYER_01;
uniform vec2 UV_OFFSET_LAYER_02;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec3 PS_TEXCOORD1;
varying vec2 PS_TEXCOORD_LAYER_01;
varying vec2 PS_TEXCOORD_LAYER_02;
varying vec3 PS_POS;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD0 = TEXCOORD0;
	PS_TEXCOORD1 = gl_Position.xyw;
	PS_TEXCOORD_LAYER_01.x = TEXCOORD0.x + UV_OFFSET_LAYER_01.x;
	PS_TEXCOORD_LAYER_01.y = TEXCOORD0.y + UV_OFFSET_LAYER_01.y;
	PS_TEXCOORD_LAYER_02.x = TEXCOORD0.x + UV_OFFSET_LAYER_02.x;
	PS_TEXCOORD_LAYER_02.y = TEXCOORD0.y + UV_OFFSET_LAYER_02.y;

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;	
}

    waterfall2.psN  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[5];

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE1 SAMPLER[1]
#define NOISE_TEXTURE2 SAMPLER[2]
#define MASK_TEXTURE SAMPLER[4]

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


varying vec2 PS_TEXCOORD0;
varying vec3 PS_TEXCOORD1;
varying vec2 PS_TEXCOORD_LAYER_01;
varying vec2 PS_TEXCOORD_LAYER_02;

uniform vec4 WATERFALL_FADE_PARAMS;
uniform vec4 WATERFALL_NOISE_PARAMS0;
uniform vec4 WATERFALL_NOISE_PARAMS1;

void main()
{
	vec2 ss_uv = (PS_TEXCOORD1.xy / PS_TEXCOORD1.z) * 0.5 + 0.5;
	vec4 base_colour = texture2D( BASE_TEXTURE, ss_uv );	

	float decoding_factor = 0.5;
	base_colour.rgb = base_colour.rgb * decoding_factor;

	vec4 noise_sample01 = texture2D(NOISE_TEXTURE1, PS_TEXCOORD_LAYER_01.xy * vec2(WATERFALL_NOISE_PARAMS0.x, 1.0));
	vec4 noise_sample02 = texture2D(NOISE_TEXTURE2, PS_TEXCOORD_LAYER_02.xy * vec2(WATERFALL_NOISE_PARAMS1.x, 1.0));

	float noise_01 = noise_sample01.r * WATERFALL_NOISE_PARAMS0.z;
	float noise_02 = noise_sample02.r * WATERFALL_NOISE_PARAMS1.z;

	float noise_alpha_01 = smoothstep(WATERFALL_NOISE_PARAMS0.w, WATERFALL_NOISE_PARAMS0.w + 0.1, 1.0 - PS_TEXCOORD0.y);
	float noise_alpha_02 = smoothstep(WATERFALL_NOISE_PARAMS1.w, WATERFALL_NOISE_PARAMS1.w + 0.1, 1.0 - PS_TEXCOORD0.y);

	float mixed_noise = max(noise_01 * noise_alpha_01, noise_02 * noise_alpha_02);

	float darkening_01 = 1.0 - noise_sample01.g * noise_alpha_01;
	float darkening_02 = 1.0 - noise_sample02.g * noise_alpha_02;

    float darkening = min(darkening_01, darkening_02);

    vec3 lit_noise = CalculateLightingContribution() * mixed_noise; 

    float alpha = base_colour.a;
	base_colour.rgb = base_colour.rgb * darkening + lit_noise;

	vec4 fade_mask = texture2D(MASK_TEXTURE, vec2(PS_TEXCOORD0.x, PS_POS.y * 0.1));

	base_colour.rgb = mix(base_colour.rgb, base_colour.rgb * WATERFALL_FADE_PARAMS.rgb, max(1.0 - PS_TEXCOORD0.y - WATERFALL_FADE_PARAMS.a * fade_mask.g, 0.0));

	gl_FragColor = vec4(base_colour.rgb * alpha, alpha);
}

                                   