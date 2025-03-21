   postprocess_zoomblur      SAMPLER    +         SCREEN_PARAMS                                OVERLAY_BLEND                     postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_zoomblur.ps�  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];

uniform vec4 SCREEN_PARAMS;
uniform float OVERLAY_BLEND;

const vec4 ZOOM_BLUR_PARAMS0 = vec4(0.00187500, 0.00375000, 0.00562500, 0.00750000);
const vec4 ZOOM_BLUR_PARAMS1 = vec4(0.00937500, 0.01125000, 0.01312500, 0.01500000);
const vec4 ZOOM_BLUR_PARAMS2 = vec4(0.08333333, 0.14285714, 0.17857143, 0.19047619);
const vec4 ZOOM_BLUR_PARAMS3 = vec4(0.17857143, 0.14285714, 0.08333333, 0.00000000);

#define SRC_IMAGE        SAMPLER[0]

varying vec2 PS_TEXCOORD0;

#define BlendOverlayf(base, blend) 	(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))
#define Blend(base, blend, funcf) 		vec3(funcf(base.r, blend.r), funcf(base.g, blend.g), funcf(base.b, blend.b))
#define BlendOverlay(base, blend) 		Blend(base, blend, BlendOverlayf)

vec3 Overlay (vec3 a, vec3 b) {
    vec3 r = vec3(0.0,0.0,0.0);
    if (a.r > 0.5) { r.r = 1.0-(1.0-2.0*(a.r-0.5))*(1.0-b.r); }
    else { r.r = (2.0*a.r)*b.r; }
    if (a.g > 0.5) { r.g = 1.0-(1.0-2.0*(a.g-0.5))*(1.0-b.g); }
    else { r.g = (2.0*a.g)*b.g; }
    if (a.b > 0.5) { r.b = 1.0-(1.0-2.0*(a.b-0.5))*(1.0-b.b); }
    else { r.b = (2.0*a.b)*b.b; }
    return r;
}

//float random(vec3 scale,float seed){return fract(sin(dot(gl_FragCoord.xyz+seed,scale))*43758.5453+seed);}

vec3 ZoomBlurTap(sampler2D src_image, vec2 toCenter, vec2 uv, float percent, float weight)
{
	return texture2D(src_image,uv+toCenter*percent*SCREEN_PARAMS.zw).rgb * weight;
}

vec3 ZoomBlur(sampler2D src_image, vec3 colour, vec2 uv)
{	
	vec2 center = vec2(SCREEN_PARAMS.x * 0.5, SCREEN_PARAMS.y * 0.5);
	vec2 toCenter=center-uv*SCREEN_PARAMS.xy;
	//TODO(YOG): Put random factor back in maybe through a texture lookup because it definitely looks better.
	float offset=0.0;//random(vec3(12.9898,78.233,151.7182),0.0);
	vec3 taps = vec3(0.0,0.0,0.0);
	
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS0.x, ZOOM_BLUR_PARAMS2.x);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS0.y, ZOOM_BLUR_PARAMS2.y);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS0.z, ZOOM_BLUR_PARAMS2.z);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS0.w, ZOOM_BLUR_PARAMS2.w);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS1.x, ZOOM_BLUR_PARAMS3.x);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS1.y, ZOOM_BLUR_PARAMS3.y);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS1.z, ZOOM_BLUR_PARAMS3.z);
	taps += ZoomBlurTap(src_image, toCenter, uv, ZOOM_BLUR_PARAMS1.w, ZOOM_BLUR_PARAMS3.w);

	return taps.rgb;
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb; // rgb all 0:1 - colour space
	vec3 zoom_colour = ZoomBlur(SRC_IMAGE, base_colour.rgb, PS_TEXCOORD0.xy);
	vec3 blended = mix(base_colour.rgb, zoom_colour.rgb, OVERLAY_BLEND);

    gl_FragColor = vec4( blended.rgb, 1.0 );	
}

                  