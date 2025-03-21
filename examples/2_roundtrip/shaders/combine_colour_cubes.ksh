   combine_colour_cubes      CC_LERP_PARAMS                            CC_LAYER_PARAMS                        INTENSITY_MODIFIER                     SAMPLER    +         ndc.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
}

    combine_colour_cubes.ps�  #if defined( GL_ES )
precision highp float;
#endif

uniform vec3 CC_LERP_PARAMS;
#define CC_LERP0			CC_LERP_PARAMS.x
#define CC_LERP1			CC_LERP_PARAMS.y
#define CC_LERP2			CC_LERP_PARAMS.z

uniform vec2 CC_LAYER_PARAMS;
#define CC_LAYER_PARAMS0			CC_LAYER_PARAMS.x
#define CC_LAYER_PARAMS1			CC_LAYER_PARAMS.y

uniform float INTENSITY_MODIFIER;

uniform sampler2D SAMPLER[6];

#define CC_SRC0		SAMPLER[0]
#define CC_DEST0	SAMPLER[1]
#define CC_SRC1		SAMPLER[2]
#define CC_DEST1	SAMPLER[3]
#define CC_SRC2		SAMPLER[4]
#define CC_DEST2	SAMPLER[5]

varying vec2 PS_TEXCOORD;

#define CUBE_DIMENSION 32.0
#define CUBE_WIDTH ( CUBE_DIMENSION * CUBE_DIMENSION )
#define CUBE_HEIGHT ( CUBE_DIMENSION )

vec3 SampleSourceDest( sampler2D source_cc, sampler2D dest_cc, vec2 uv, float lerp )
{
	vec3 cc_src = texture2D( source_cc, uv ).rgb;
	vec3 cc_dest = texture2D( dest_cc, uv ).rgb;
	vec3 cc_mixed = mix( cc_src, cc_dest, lerp );
	return cc_mixed;
}

void main()
{
	vec2 uv = PS_TEXCOORD.xy;

	vec3 cc0 = SampleSourceDest(CC_SRC0, CC_DEST0, uv, CC_LERP0);
	vec3 cc1 = SampleSourceDest(CC_SRC1, CC_DEST1, uv, CC_LERP1);
	vec3 cc2 = SampleSourceDest(CC_SRC2, CC_DEST2, uv, CC_LERP2);

	vec3 cc_mixed = cc0;
	if(CC_LAYER_PARAMS0 > 0.0)
	{
		cc_mixed = mix(cc_mixed, cc1, CC_LAYER_PARAMS0);
	}
	if(CC_LAYER_PARAMS1 > 0.0)
	{
		cc_mixed = mix(cc_mixed, cc2, CC_LAYER_PARAMS1);
	}

	cc_mixed *= INTENSITY_MODIFIER;

    gl_FragColor = vec4( cc_mixed, 1.0 );
}

                     