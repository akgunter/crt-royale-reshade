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


void pixelShader1(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    
    out float4 color : SV_Target
) {
    const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
    
    //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
    //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
    //  vertex shader calculations, so static versions can be constant-folded.
    const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
    const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;
    
    const float wrong_field = curr_line_is_wrong_field(texcoord.y, orig_linearized_size.y);

    // If we're in the current field, draw the beam
    //   wrong_field is always 0 when we aren't interlacing
    if (!wrong_field) {
        // float beam_center_0 = get_beam_center(texel_0, scanline_idx_0);
        // const float2 beam_coord_0 = float2(texcoord.x, beam_center_0 / orig_linearized_size.y); 
        const float3 scanline_0_color = tex2D_linearize(samplerOrigLinearized, texcoord, get_intermediate_gamma()).rgb;
        
        const float3 beam_dist_0 = 0;
        const float3 scanline_contrib_0 = get_beam_strength(
            beam_dist_0,
            scanline_0_color, sigma_range, shape_range
        );

        // Double the intensity when interlacing to maintain the same apparent brightness
        const float contrib_factor = enable_interlacing + 1.0;
        float3 scanline_intensity = contrib_factor * scanline_0_color;

        // Temporarily auto-dim the output to avoid clipping.
        color = encode_output(float4(scanline_intensity * levels_autodim_temp, 1.0), get_intermediate_gamma());
    }
    // If we're not in the current field, don't draw the beam
    //   It's tempting to add a gaussian here to account for bleeding, but it usually ends up
    //   either doing nothing or making the colors wrong.
    else {
        color = float4(0, 0, 0, 1);
    }
}

void verticalOffsetPS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    
    out float4 color : SV_Target
) {
    if (beam_misconvergence) {
        const float3 convergence_offsets_y = get_convergence_offsets_y_vector();
        const float3 offset_v = (convergence_offsets_y * scanline_num_pixels) / TEX_VERTICALSCANLINES_HEIGHT;

        const float2 r_coord = texcoord + float2(0, offset_v.r);
        const float2 g_coord = texcoord + float2(0, offset_v.g);
        const float2 b_coord = texcoord + float2(0, offset_v.b);

        const float r = tex2D(samplerVerticalScanlines, r_coord).r;
        const float g = tex2D(samplerVerticalScanlines, g_coord).g;
        const float b = tex2D(samplerVerticalScanlines, b_coord).b;

        color = float4(r, g, b, 1);
    }
    else {
        color = tex2D(samplerVerticalScanlines, texcoord);
    }
}