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
#include "../lib/gamma-management.fxh"
#include "../lib/scanline-functions.fxh"

#include "shared-objects.fxh"

void linearizeAndBobVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float interlaced : TEXCOORD1,
    out float2 v_step : TEXCOORD2
) {
    PostProcessVS(id, position, texcoord);
	// texcoord.x = (id == 2) ? 2.0 : 0.0;
	// texcoord.y = (id == 1) ? 2.0 : 0.0;
	// position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    const float2 input_video_size = content_size;
    
    //  Detect interlacing: 1.0 = true, 0.0 = false.
    interlaced = enable_interlacing;
    v_step = float2(0.0, 1.0 / input_video_size.y);
}

void linearizeAndBobPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float interlaced : TEXCOORD1,
    in const float2 v_step : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Linearize the input based on CRT gamma and bob interlaced fields.
    //  Bobbing ensures we can immediately blur without getting artifacts.
    //  Note: TFF/BFF won't matter for sources that double-weave or similar.
    if (bool(interlaced))
    {
        //  Sample the current line and an average of the previous/next line;
        //  tex2D_linearize will decode CRT gamma.  Don't bother branching:
        float curr_scanline_idx = get_curr_scanline_idx(texcoord.y, content_size.y);
        float curr_scanline_start_y = curr_scanline_idx * scanline_num_pixels / content_size.y;
        float3 in_field_interpolated_line = get_bobbed_scanline_sample(
            samplerCrop, texcoord,
            curr_scanline_start_y, v_step.y,
            get_input_gamma()
        );

        float prev_scanline_start_y = curr_scanline_start_y - scanline_num_pixels * v_step.y;
        float next_scanline_starty_y = curr_scanline_start_y + scanline_num_pixels * v_step.y;
        float3 prev_interpolated_line = get_bobbed_scanline_sample(
            samplerCrop, texcoord,
            prev_scanline_start_y, v_step.y,
            get_input_gamma()
        );
        float3 next_interpolated_line = get_bobbed_scanline_sample(
            samplerCrop, texcoord,
            next_scanline_starty_y, v_step.y,
            get_input_gamma()
        );
        
        float3 out_field_interpolated_line = 0.5 * (prev_interpolated_line + next_interpolated_line);

        //  Select the correct color, and output the result:
        const float wrong_field = curr_line_is_wrong_field(curr_scanline_idx);
        const float3 selected_color = lerp(in_field_interpolated_line, out_field_interpolated_line, wrong_field);

        color = encode_output(float4(selected_color, 1.0), get_intermediate_gamma());
    }
    else
    {
        float curr_scanline_idx = get_curr_scanline_idx(texcoord.y, content_size.y);
        float curr_scanline_start_y = curr_scanline_idx * scanline_num_pixels / content_size.y;
        float3 in_field_interpolated_line = get_bobbed_scanline_sample(
            samplerCrop, texcoord,
            curr_scanline_start_y, v_step.y,
            get_input_gamma()
        );

        color = encode_output(float4(in_field_interpolated_line, 1.0), get_intermediate_gamma());
    }
}

void scanWithElectronBeams(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    
    out float4 color : SV_Target
) {
    const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
    
    //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
    //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
    //  vertex shader calculations, so static versions can be constant-folded.
    // const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
    // const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;
    
    const float wrong_field = curr_line_is_wrong_field(texcoord.y, orig_linearized_size.y);


    // If we're in the current field, draw the beam
    //   wrong_field is always 0 when we aren't interlacing
    if (!wrong_field) {
        // Double the intensity when interlacing to maintain the same apparent brightness
        const float interlacing_factor = enable_interlacing * float(
            scanline_deinterlacing_mode != 1 &&
            scanline_deinterlacing_mode != 2
        );
        const float contrib_factor = interlacing_factor + 1.0;


        // float beam_center_0 = get_beam_center(texel_0, scanline_idx_0);
        // const float2 beam_coord_0 = float2(texcoord.x, beam_center_0 / orig_linearized_size.y);
        const float3 scanline_color_0 = tex2D_linearize(samplerOrigLinearized, texcoord, get_intermediate_gamma()).rgb;
        
        /*
        const float3 beam_dist_0 = 0;
        const float3 scanline_contrib_0 = get_beam_strength(
            beam_dist_0,
            scanline_color_0, sigma_range, shape_range
        );
        */

        float3 scanline_intensity = contrib_factor * scanline_color_0;

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

void beamMisaslignmentPS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_TARGET
) {
    const float2 scanline_texture_size = tex2Dsize(samplerVerticalScanlines);
    const float2 scanline_texture_size_inv = 1.0 / scanline_texture_size;

    const float3 offset_sample = sample_rgb_scanline(
        samplerVerticalScanlines, texcoord,
        scanline_texture_size, scanline_texture_size_inv
    );

    color = float4(offset_sample, 1);
}