uniform mat4 MatrixPVW;
uniform mat4 MatrixW;
uniform mat4 Matrix233;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec3 PS_TEXCOORD1;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	// ↓ Matrix233 is unused, remove comment below to see the difference
	// gl_Position = Matrix233 * gl_Position;
	
	PS_TEXCOORD0.xy = TEXCOORD0;
	PS_TEXCOORD1.xyz = gl_Position.xyw;
}