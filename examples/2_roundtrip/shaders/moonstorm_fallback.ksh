   moonstorm_fallback   	   MatrixPVW                                                                                SAMPLER    +         ALPHA_RANGE                        IMAGE_PARAMS                                IMAGE_PARAMS2                                PosUVColour.vsg  uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
	PS_COLOUR.rgba = vec4( DIFFUSE.rgb * DIFFUSE.a, DIFFUSE.a ); // premultiply the alpha
}

    moonstorm_fallback.psD  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

uniform vec2 ALPHA_RANGE;
uniform vec4 IMAGE_PARAMS;
uniform vec4 IMAGE_PARAMS2;


////////// Parameters

// These two have nothing to do with alpha, just using the uniforms in the SetAlphaRange() call
#define RES_W                           ALPHA_RANGE.x
#define RES_H                           ALPHA_RANGE.y

#define TIME                            IMAGE_PARAMS.x
#define WORLD_SCROLL_X                  IMAGE_PARAMS.y
#define WORLD_SCROLL_Y                  IMAGE_PARAMS.z
#define INTENSITY                       IMAGE_PARAMS.w

#define BRIGHTNESS                      IMAGE_PARAMS2.x
#define DUST_LAYER_INTENSITY            IMAGE_PARAMS2.y


////////// Customization

#if defined ( GOGGLES )
    #define ALPHA_MAX                   .64
    #define CENTER_SOFTNESS             .265
#else
    #define ALPHA_MAX                   .9
    #define CENTER_SOFTNESS             .075
#endif

#define CENTER_COLOR                    vec3(.1,    .7,     .7)
#define CORNER_COLOR                    vec3(.36,   .275,   .55)
#define DUST_COLOR                      vec3(.65,   .89,    .95)

#define CENTER_STROBE_FREQUENCY         7.
#define CENTER_STROBE_DISTANCE          .02

#define WIND_INTENSITY                  .1
#define WIND_FREQUENCY                  .34

// Note: Dust layer is composited from red and green channels of tex0
#define DUST_TEXTURE_Y_SCALE_R          .26
#define DUST_TEXTURE_Y_SCALE_G          .5
#define DUST_TEXTURE_SCROLL_SPEED_R     1.45
#define DUST_TEXTURE_SCROLL_SPEED_G     1.8
#define DUST_SCROLL_SCALE_R             5.5
#define DUST_SCROLL_SCALE_G             7.

#define DUST_TAPER_MULTIPLIER           1.45

#define DUST_TEXTURE_OPACITY            .5

#define CELL_NOISE_1_SCALE              .84
#define CELL_NOISE_2_SCALE              .97
#define CELL_NOISE_1_TIME_SCALE         vec2(.03, .08)
#define CELL_NOISE_2_TIME_SCALE         vec2(-.03, -.045)


////////// Constants

#define HALF_PI                         1.5707963268


//


vec4 generateBase(vec2 pt, out float normalizedDistFromCenter)
{
    float inverseAspectRatio = RES_H / RES_W;
    float halfInverseAspectRatio = inverseAspectRatio * .5;
    pt.y *= inverseAspectRatio;
    
    float distFromCenter = distance(pt, vec2(.5, halfInverseAspectRatio));
    float gradientLerpDivisor = halfInverseAspectRatio / sqrt(.25 + (halfInverseAspectRatio * halfInverseAspectRatio)); // .25 == .5^2 == normalized screen_width*0.5 squared
    normalizedDistFromCenter = distFromCenter / gradientLerpDivisor;

    float alphaThresholdBase = 0.05 + (1. - INTENSITY) * .14;

    float threshold = alphaThresholdBase;

	return vec4(CENTER_COLOR, (distFromCenter - threshold) / CENTER_SOFTNESS);
}

float cellNoise(vec2 pt)
{
    vec4 samp = texture2D( SAMPLER[0], pt );
    return samp.b;
}

void main()
{
    vec2 screen_pos = PS_TEXCOORD.xy;

    float normalizedDistFromCenter;
    gl_FragColor = generateBase(screen_pos, normalizedDistFromCenter);


    // Dust layer

	float dustTextureSampleX = screen_pos.x;
    float dustTextureSampleY1 = (screen_pos.y - TIME * DUST_TEXTURE_SCROLL_SPEED_R) * DUST_TEXTURE_Y_SCALE_R;
    
    vec2 dustSampleCoord1 = vec2(dustTextureSampleX, dustTextureSampleY1);
    float dustSample1 = texture2D( SAMPLER[0], dustSampleCoord1 ).r;
    

    // Cell noise layer
    
    float cellNoise1 = cellNoise(screen_pos * CELL_NOISE_1_SCALE + vec2(TIME * CELL_NOISE_1_TIME_SCALE.x, TIME * CELL_NOISE_1_TIME_SCALE.y));


    // Combined base + dust + cell noise

	float combinedDustTextureChannels = dustSample1;
    float combinedCellNoise = cellNoise1;

    gl_FragColor = mix(
        gl_FragColor,
        vec4(DUST_COLOR, max(gl_FragColor.a, combinedDustTextureChannels)),
        combinedCellNoise
        );

    #if defined ( GOGGLES )
        float add_alpha_post = - (1. - normalizedDistFromCenter) * (1. - normalizedDistFromCenter) * .75;
    #else
        float add_alpha_post = (1. - normalizedDistFromCenter) * combinedDustTextureChannels * .75;
    #endif
    
    gl_FragColor = vec4(
        gl_FragColor.rgb * BRIGHTNESS,
		min(gl_FragColor.a, min(INTENSITY, ALPHA_MAX))
            + add_alpha_post
        );
}                       