   blurh      SAMPLER    +         SAMPLER_PARAMS                                ndc.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
}

    blurh.psV  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
uniform vec4 SAMPLER_PARAMS; // 1 / IMAGE_WIDTH

#define PIXEL_SIZE SAMPLER_PARAMS.z

varying vec2 PS_TEXCOORD;

void main()
{
	vec4 sum = vec4( 0, 0, 0, 0 );

	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x - 4.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.05;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x - 3.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.09;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x - 2.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.12;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x - PIXEL_SIZE,		PS_TEXCOORD.y)) * 0.15;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x,					PS_TEXCOORD.y)) * 0.16;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x + PIXEL_SIZE,		PS_TEXCOORD.y)) * 0.15;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x + 2.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.12;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x + 3.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.09;
	sum += texture2D(SAMPLER[0], vec2(PS_TEXCOORD.x + 4.0 * PIXEL_SIZE,	PS_TEXCOORD.y)) * 0.05;

	gl_FragColor = sum;
}

               