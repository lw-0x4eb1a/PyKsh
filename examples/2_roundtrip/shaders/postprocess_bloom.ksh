   postprocess_bloom      SAMPLER    +         postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_bloom.psV  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[2];

#define SRC_IMAGE        SAMPLER[0]
#define BLOOM_BUFFER     SAMPLER[1]

varying vec2 PS_TEXCOORD0;

void main()
{
    gl_FragColor = vec4(texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb + texture2D( BLOOM_BUFFER, PS_TEXCOORD0.xy ).rgb, 1.0);
}

            