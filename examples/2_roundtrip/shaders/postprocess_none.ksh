   postprocess_none      SAMPLER    +         postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_none.ps%  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];

#define SRC_IMAGE        SAMPLER[0]

varying vec2 PS_TEXCOORD0;

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb;

	gl_FragColor = vec4(base_colour.rgb, 1.0);
}

            