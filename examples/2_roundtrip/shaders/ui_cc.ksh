   ui_cc   	   MatrixPVW                                                                                SAMPLER    +         IMAGE_PARAMS                                PosUVColour.vsg  uniform mat4 MatrixPVW;

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

    ui_cc.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[2];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

uniform vec4 IMAGE_PARAMS;

#define COLOUR_CUBE SAMPLER[1]
#ifndef COLOURCUBE_H
#define COLOURCUBE_H

#ifndef COLOUR_CUBE
	#error If you use colourcube, you must #define the sampler that the colourcube belongs to
#endif

const float CUBE_DIMENSION = 32.0;
const float CUBE_WIDTH = ( CUBE_DIMENSION * CUBE_DIMENSION );
const float CUBE_HEIGHT =( CUBE_DIMENSION );
const float ONE_OVER_CUBE_WIDTH =  1.0 / CUBE_WIDTH;
const float ONE_OVER_CUBE_HEIGHT =  1.0 / CUBE_HEIGHT;

//make sure to premultiply the alpha if its value isn't 1!
vec3 ApplyColourCube(vec3 colour)
{
	vec3 intermediate = colour.rgb * vec3( CUBE_DIMENSION - 1.0, CUBE_DIMENSION - 1.0, CUBE_DIMENSION - 1.0 );

	vec2 floor_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + floor( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g + 0.5, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec2 ceil_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + ceil( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g + 0.5, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec3 floor_col = texture2D( COLOUR_CUBE, floor_uv.xy ).rgb;
	vec3 ceil_col = texture2D( COLOUR_CUBE, ceil_uv.xy ).rgb;
	return mix(floor_col, ceil_col, intermediate.b - floor(intermediate.b) );	
}

#endif //COLOURCUBE.h


void main()
{
    vec4 colour = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
	colour.rgba *= PS_COLOUR.rgba;
	colour.rgba *= IMAGE_PARAMS.rgba;	
	
    gl_FragColor = vec4(ApplyColourCube(colour.rgb) * colour.a, colour.a);
}

                 