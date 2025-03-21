   postprocess_lunacy      SAMPLER    +         OVERLAY_BLEND                     LUNACY_INTENSITY                     postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_lunacy.ps�  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[3];

#define SRC_IMAGE        SAMPLER[0]
#define OVERLAY_IMAGE    SAMPLER[1]
#define OVERLAY_BUFFER   SAMPLER[2]

uniform float OVERLAY_BLEND;
uniform float LUNACY_INTENSITY;

varying vec2 PS_TEXCOORD0;

vec3 Overlay (vec3 a, vec3 b) {
    vec3 r = vec3(0.0,0.0,0.0);

    if(a.g > 0.5)
    {
    	r = 1.0-(1.0-2.0*(a-0.5))*(1.0-b);
    }
    else
    {
    	r = (2.0*a)*b;
    }

    return r;
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb; // rgb all 0:1 - colour space
	vec3 overlay = texture2D( OVERLAY_IMAGE, PS_TEXCOORD0.xy ).rgb;
	vec3 overlay_buffer = texture2D(OVERLAY_BUFFER, PS_TEXCOORD0.xy).rgb + vec3(0.5, 0.5, 0.5);

    gl_FragColor = vec4(mix(base_colour.rgb, Overlay(base_colour.rgb, overlay.rgb + overlay_buffer.rgb) * LUNACY_INTENSITY, overlay_buffer.g * OVERLAY_BLEND), 1.0 );
}

                  