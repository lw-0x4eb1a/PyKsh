   shade      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         AMBIENTLIGHT                            SHADESTRENGTH                     shade.vs5  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;

void main()
{
	mat4 mtxPVW = MatrixP * MatrixV * MatrixW;

	gl_Position = mtxPVW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD.xy = TEXCOORD0.xy;
}
    shade.psd  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];

#define BASE_TEXTURE SAMPLER[0]

uniform vec3 AMBIENTLIGHT;
uniform float SHADESTRENGTH;

varying vec2 PS_TEXCOORD;

void main()
{
	vec4 base_colour = texture2D(BASE_TEXTURE, PS_TEXCOORD.xy);

	// Multiply with the ambient term
	float soften = SHADESTRENGTH;
	base_colour.r = 1.0 - ((1.0 - base_colour.r) * soften);
	base_colour.g = 1.0 - ((1.0 - base_colour.g) * soften);
	base_colour.b = 1.0 - ((1.0 - base_colour.b) * soften);

	base_colour.rgb *= AMBIENTLIGHT.rgb;

	gl_FragColor = base_colour;
}
                          