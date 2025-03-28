   postprocess_moonpulsegrading      SAMPLER    +         MOONPULSE_GRADING_PARAMS                                postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_moonpulsegrading.psu	  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];
#define SRC_IMAGE SAMPLER[0]

varying vec2 PS_TEXCOORD0;

//

uniform vec4 MOONPULSE_GRADING_PARAMS;

//#define ANGLE_TO_PLAYER			MOONPULSE_GRADING_PARAMS.x	//	[0..2PI]	// Not used in this shader, just keeping it here for symmetry with postprocess_moonpulse.ps
#define DIST_TO_PLAYER				MOONPULSE_GRADING_PARAMS.y	//	Player world distance from pulse center
#define GLOW_INTENSITY				MOONPULSE_GRADING_PARAMS.z	//	[0..1]
#define WAVE_PROGRESS				MOONPULSE_GRADING_PARAMS.w	//	[0..1]

//

vec3 desaturate(vec3 col, float weight)
{
    float luminosity = (col.x + col.y + col.z) / 3.;
    return mix(col, vec3(luminosity, luminosity, luminosity), weight);
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb;



	////////// Constants

	const float pi									= 	3.1415927;

	const float proximity_threshold					= 	40.;
	const float desaturation_intensity_max			= 	.41;



	////////// Shared coefficients

	float proximity_weight							= 	clamp(DIST_TO_PLAYER / proximity_threshold, 0., 1.);
	float one_minus_proximity_weight				= 	1. - proximity_weight;
    float one_minus_proximity_weight_limited		= 	min(one_minus_proximity_weight, GLOW_INTENSITY);
	
	float close_proximity_wave_coefficient			=	one_minus_proximity_weight * sin(WAVE_PROGRESS * pi);



	////////// Color grading

    float contrast		=	1.
						+	.4		* GLOW_INTENSITY
						+	.65		* one_minus_proximity_weight_limited
						+	.145	* close_proximity_wave_coefficient * GLOW_INTENSITY;

    float brightness	=	.16		* one_minus_proximity_weight_limited
						-	.24		* close_proximity_wave_coefficient * GLOW_INTENSITY;

	float contrast_remap = (1. - contrast) * 0.5;
    mat4 mat_contrast = mat4(		contrast,			0.,					0.,					0.,
									0.,					contrast,			0.,					0.,
									0.,					0.,					contrast,			0.,
									contrast_remap,		contrast_remap,		contrast_remap,		1.);

    mat4 mat_brightness = mat4(		1.,					0.,					0.,					0.,
									0.,					1.,					0.,					0.,
									0.,					0.,					1.,					0.,
									brightness, 		brightness, 		brightness, 		1.);

	base_colour = (
		mat_brightness
		* mat_contrast
        * vec4(desaturate(base_colour, desaturation_intensity_max * GLOW_INTENSITY), 1.)
		).rgb;

	
	
	gl_FragColor = vec4(base_colour, 1.);
}
               