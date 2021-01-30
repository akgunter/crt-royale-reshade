/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  crt-royale-reshade: A port of TroggleMonkey's crt-royale from libretro to ReShade.
//  Copyright (C) 2020 Alex Gunter <akg7634@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


#include "../lib/bind-shader-params.fxh"
#include "../lib/scanline-functions.fxh"

#include "shared-objects.fxh"


void vertexShader1(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 il_step_multiple : TEXCOORD1,
    out float2 uv_step : TEXCOORD2,
    out float pixel_height_in_scanlines : TEXCOORD3
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    //  Detect interlacing: il_step_multiple indicates the step multiple between
    //  lines: 1 is for progressive sources, and 2 is for interlaced sources.
    const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
    const float y_step = enable_interlacing ? 2 * scanline_num_pixels : 1.0;

    il_step_multiple = float2(1.0, y_step);
    //  Get the uv tex coords step between one texel (x) and scanline (y):
    uv_step = il_step_multiple / orig_linearized_size;
    
    //  We need the pixel height in scanlines for antialiased/integral sampling:
    const float m = enable_interlacing ? il_step_multiple.y * scanline_num_pixels : 1.0;
    pixel_height_in_scanlines = (orig_linearized_size.y / TEX_VERTICALSCANLINES_SIZE.y) / m;
    // pixel_height_in_scanlines = 1.0 / il_step_multiple.y;
}


void pixelShader1(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 il_step_multiple : TEXCOORD1,
    in const float2 uv_step : TEXCOORD2,
    in const float pixel_height_in_scanlines : TEXCOORD3,
    
    out float4 color : SV_Target
) {

    if (enable_interlacing) {
        //  This pass: Sample multiple (misconverged?) scanlines to the final
        //  vertical resolution.  Temporarily auto-dim the output to avoid clipping.

        //  Read some attributes into local variables:
        const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
        
        //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
        //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
        //  vertex shader calculations, so static versions can be constant-folded.
        const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
        const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;

        const float3 convergence_offsets_y = beam_misconvergence ? get_convergence_offsets_y_vector() : float3(0, 0, 0);

        float2 texel_0;
        float scanline_0_idx;
        float2 frame_and_line_field_idx;
        float wrong_field;
        get_scanline_base_params(texcoord.y, orig_linearized_size.y,
            texel_0, scanline_0_idx, frame_and_line_field_idx, wrong_field
        );

        const float raw_beam_center_0 = get_beam_center(texel_0.y, scanline_0_idx, wrong_field);
        const float raw_beam_center_n2 = raw_beam_center_0 - 2*scanline_num_pixels;
        const float raw_beam_center_p2 = raw_beam_center_0 + 2*scanline_num_pixels;

        const float2 beam_coord_n2 = float2(texcoord.x, raw_beam_center_n2 / orig_linearized_size.y);
        const float2 beam_coord_0 = float2(texcoord.x, raw_beam_center_0 / orig_linearized_size.y);
        const float2 beam_coord_p2 = float2(texcoord.x, raw_beam_center_p2 / orig_linearized_size.y);

        const float3 scanline_n2_color = tex2D_linearize(samplerOrigLinearized, beam_coord_n2, get_intermediate_gamma()).rgb;
        const float3 scanline_0_color = tex2D_linearize(samplerOrigLinearized, beam_coord_0, get_intermediate_gamma()).rgb;
        const float3 scanline_p2_color = tex2D_linearize(samplerOrigLinearized, beam_coord_p2, get_intermediate_gamma()).rgb;

        const float3 beam_center_n2 = raw_beam_center_n2 + convergence_offsets_y * scanline_num_pixels;
        const float3 beam_center_0 = raw_beam_center_0 + convergence_offsets_y * scanline_num_pixels;
        const float3 beam_center_p2 = raw_beam_center_p2 + convergence_offsets_y * scanline_num_pixels;

        const float3 beam_dist_n2 = get_dist_from_beam(texel_0.y, beam_center_n2, wrong_field);
        const float3 beam_dist_0 = get_dist_from_beam(texel_0.y, beam_center_0, wrong_field);
        const float3 beam_dist_p2 = get_dist_from_beam(texel_0.y, beam_center_p2, wrong_field);

        const float3 scanline_contrib_n2 = get_beam_strength(
            beam_dist_n2,
            scanline_n2_color, sigma_range, shape_range
        );
        const float3 scanline_contrib_0 = get_beam_strength(
            beam_dist_0,
            scanline_0_color, sigma_range, shape_range
        );
        const float3 scanline_contrib_p2 = get_beam_strength(
            beam_dist_p2,
            scanline_p2_color, sigma_range, shape_range
        );

        float3 scanline_intensity = scanline_contrib_0;
        scanline_intensity += scanline_contrib_n2;
        scanline_intensity += scanline_contrib_p2;

        color = encode_output(float4(scanline_intensity * levels_autodim_temp, 1.0), get_intermediate_gamma());
    }
    else {
        const float4 sample_color = tex2D_linearize(samplerOrigLinearized, texcoord, get_intermediate_gamma());
        color = encode_output(sample_color * levels_autodim_temp, get_intermediate_gamma());
    }
}