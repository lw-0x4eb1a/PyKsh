   minimapocean   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         MINIMAP_OCEAN_EDGE_COLOR0                                MINIMAP_OCEAN_EDGE_PARAMS0                                MINIMAP_OCEAN_EDGE_COLOR1                                MINIMAP_OCEAN_EDGE_PARAMS1                                MINIMAP_OCEAN_EDGE_SHADOW_COLOR                                 MINIMAP_OCEAN_EDGE_SHADOW_PARAMS                                MINIMAP_OCEAN_EDGE_FADE_PARAMS                                MINIMAP_OCEAN_EDGE_NOISE_PARAMS                                OCEAN_WORLD_EXTENTS                                ocean_combined.vs  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;

varying vec3 PS_POS;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;
}

    minimapocean.psz  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[3];

#define BASE_TEXTURE SAMPLER[0]
#define MASK_TEXTURE SAMPLER[1]
#define PAPER_TEXTURE SAMPLER[2]


uniform vec4 MINIMAP_OCEAN_EDGE_COLOR0;
uniform vec4 MINIMAP_OCEAN_EDGE_PARAMS0;

uniform vec4 MINIMAP_OCEAN_EDGE_COLOR1;
uniform vec4 MINIMAP_OCEAN_EDGE_PARAMS1;

uniform vec4 MINIMAP_OCEAN_EDGE_SHADOW_COLOR;
uniform vec4 MINIMAP_OCEAN_EDGE_SHADOW_PARAMS;

uniform vec4 MINIMAP_OCEAN_EDGE_FADE_PARAMS;

uniform vec4 MINIMAP_OCEAN_EDGE_NOISE_PARAMS;

uniform vec4 OCEAN_WORLD_EXTENTS;
uniform vec4 OCEAN_UV_PARAMS;

varying vec3 PS_POS;

vec3 Desaturate(vec3 colour, float desaturate_intensity, vec3 test_colour, float threshold, float half_transition_range, float impassable_amount)
{
	float desaturated_colour = 0.3 * colour.r + 0.59 * colour.g + 0.11 * colour.b;
	float desaturate_amount = smoothstep(threshold - half_transition_range, threshold + half_transition_range, impassable_amount);
	return mix(colour, test_colour, desaturate_intensity * desaturate_amount);
}

void main()
{
	vec2 ocean_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy ) * OCEAN_WORLD_EXTENTS.zw;

	vec4 ocean_colour = texture2D( BASE_TEXTURE, ocean_uv );
	float uv_mask_inset = MINIMAP_OCEAN_EDGE_FADE_PARAMS.z;
	float uv_mask_range = 1.0 + 2.0 * uv_mask_inset;
	vec2 ocean_mask_uv = min(max((ocean_uv * uv_mask_range - vec2(uv_mask_inset)), vec2(0)), vec2(1));
	vec4 ocean_mask = texture2D( MASK_TEXTURE, ocean_mask_uv );

	ocean_colour.rgb = ocean_colour.rgb;

	vec2 paper_uv = ocean_uv * MINIMAP_OCEAN_EDGE_NOISE_PARAMS.x;
	vec4 paper_colour = texture2D(PAPER_TEXTURE, paper_uv);

	float desaturate_intensity = 1.0;

	ocean_colour.rgb = Desaturate(ocean_colour.rgb, desaturate_intensity, MINIMAP_OCEAN_EDGE_COLOR0.rgb * paper_colour.rgb, MINIMAP_OCEAN_EDGE_PARAMS0.x, MINIMAP_OCEAN_EDGE_PARAMS0.y, ocean_mask.a);	
	ocean_colour.rgb = Desaturate(ocean_colour.rgb, desaturate_intensity, MINIMAP_OCEAN_EDGE_COLOR1.rgb * paper_colour.rgb, MINIMAP_OCEAN_EDGE_PARAMS1.x, MINIMAP_OCEAN_EDGE_PARAMS1.y, ocean_colour.a);	

	float alpha = smoothstep(MINIMAP_OCEAN_EDGE_FADE_PARAMS.x - MINIMAP_OCEAN_EDGE_FADE_PARAMS.y, MINIMAP_OCEAN_EDGE_FADE_PARAMS.x + MINIMAP_OCEAN_EDGE_FADE_PARAMS.y, 1.0 - ocean_colour.a);	

	vec2 drop_shadow_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy ) * OCEAN_WORLD_EXTENTS.zw + MINIMAP_OCEAN_EDGE_SHADOW_PARAMS.zw;
	vec4 drop_shadow_sample = texture2D( BASE_TEXTURE, drop_shadow_uv );

	float drop_shadow_alpha = smoothstep(MINIMAP_OCEAN_EDGE_SHADOW_PARAMS.x - MINIMAP_OCEAN_EDGE_SHADOW_PARAMS.y, MINIMAP_OCEAN_EDGE_SHADOW_PARAMS.x + MINIMAP_OCEAN_EDGE_SHADOW_PARAMS.y, 1.0 - drop_shadow_sample.a);	

	ocean_colour.rgb = mix(ocean_colour.rgb, MINIMAP_OCEAN_EDGE_SHADOW_COLOR.rgb * paper_colour.rgb, 1.0 - alpha);	

	gl_FragColor = vec4(ocean_colour.rgb * max(alpha, drop_shadow_alpha), 1.0);
}

           
                        	   
      