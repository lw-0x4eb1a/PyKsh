   postprocess_moonpulse      SAMPLER    +         MOONPULSE_PARAMS                                postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_moonpulse.ps  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];
#define SRC_IMAGE SAMPLER[0]

varying vec2 PS_TEXCOORD0;

//

uniform vec4 MOONPULSE_PARAMS;

#define ANGLE_TO_PLAYER				MOONPULSE_PARAMS.x	//	[0..2PI]
#define DIST_TO_PLAYER				MOONPULSE_PARAMS.y	//	Player world distance from pulse center
#define GLOW_INTENSITY				MOONPULSE_PARAMS.z	//	[0..1]
#define WAVE_PROGRESS				MOONPULSE_PARAMS.w	//	[0..1]

//

vec2 rotate(vec2 uv, vec2 around_pt, float radians)
{
    return vec2(cos(radians) * (uv.x - around_pt.x) + sin(radians) * (uv.y - around_pt.y) + around_pt.x,
                cos(radians) * (uv.y - around_pt.y) - sin(radians) * (uv.x - around_pt.x) + around_pt.y);
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb;



	////////// Constants

	const float proximity_threshold					= 	40.;

	const float glow_hardness_mult					= 	.12;
	const float glow_intensity_mult					= 	2.8;

	const float wave_hardness_mult					= 	2.5;
	const float wave_intensity_mult					= 	1.65;
	const float wave_base_width						= 	.5;
	const float wave_arc_amplitude_min				= 	.013;
	const float wave_arc_amplitude_max				= 	.076;
	const float half_world_reference_size			= 	800.;



	////////// Shared coefficients

	float proximity_weight							= 	clamp(DIST_TO_PLAYER / proximity_threshold, 0., 1.);

	

	////////// Directional glow
	
	vec2 rotated_uv					=	rotate(PS_TEXCOORD0.xy, vec2(.5, .5), ANGLE_TO_PLAYER);
	
    float glow_mask_offset			=	mix(-.15, .005, proximity_weight);
    float glow_mask					=	clamp((rotated_uv.y * glow_hardness_mult - glow_mask_offset) * glow_intensity_mult, 0., 1.) * GLOW_INTENSITY * (.25 + .75 * proximity_weight);



	////////// Wave
	
	float wave_offset				=	mix(3., -3., WAVE_PROGRESS);
	float wave_arc_amplitude		=	mix(wave_arc_amplitude_max, wave_arc_amplitude_min, max(DIST_TO_PLAYER / half_world_reference_size, 1.));

	float wave_arc_coefficient		=	abs(rotated_uv.x - .5) * 2.;
	float wave_y_reference_pt		=	(rotated_uv.y - wave_arc_coefficient * wave_arc_coefficient * wave_arc_amplitude) * wave_hardness_mult;

	float wave_add_mask				=	wave_y_reference_pt - wave_offset;
    float wave_sub_mask				=	wave_y_reference_pt - (wave_offset + wave_base_width * proximity_weight);

	float wave_mask					=	((clamp(wave_add_mask, 0., 1.) - clamp(wave_sub_mask, 0., 1.)) * proximity_weight) * wave_intensity_mult;



	////////// Compositing
	
	float combined_masks = max(glow_mask, wave_mask);
	
	float proximity_color_weight = .65 + proximity_weight * .35;
    base_colour = mix(base_colour, vec3(.64 * proximity_color_weight, .9 * proximity_color_weight, .98 * proximity_color_weight), combined_masks);

    gl_FragColor = vec4(base_colour, 1.0 );
}
               