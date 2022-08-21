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

void simulateInterlacingVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float interlaced : TEXCOORD1,
    out float2 v_step : TEXCOORD2
) {
    PostProcessVS(id, position, texcoord);
    
    interlaced = enable_interlacing;
    v_step = float2(0.0, 1.0 / content_size.y);
}

void simulateInterlacingPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float interlaced : TEXCOORD1,
    in const float2 v_step : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Sample the current line and an average of the previous/next line;
    //  tex2D_linearize will decode CRT gamma.  Don't bother branching:
    float curr_scanline_idx = get_curr_scanline_idx(texcoord, texcoord.y, content_size.y);
    float curr_scanline_start_y = (
        curr_scanline_idx * scanline_num_pixels_fromtexcoord(texcoord) + TEXCOORD_OFFSET
    ) / content_size.y;
    float3 in_field_interpolated_line = get_averaged_scanline_sample(
        samplerCrop, texcoord,
        curr_scanline_start_y, v_step.y,
        get_input_gamma()
    );
    
    const float wrong_field = interlaced * curr_line_is_wrong_field(curr_scanline_idx);
    const float3 selected_color = lerp(in_field_interpolated_line, 0, wrong_field);

    color = encode_output(float4(selected_color, 1.0), get_intermediate_gamma());
}

void simulateEletronBeamsVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 v_step : TEXCOORD1,
    out float2 gauss_adj_factor : TEXCOORD2
) {
    PostProcessVS(id, position, texcoord);
    
    v_step = float2(0.0, 1.0 / tex2Dsize(samplerInterlaced).y);

    const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
    const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;
    const float3 beam_strength_0 = get_gaussian_beam_strength(
        0.0, float3(1, 1, 1),
        sigma_range, shape_range
    ).r;

    const float max_embedding_dist = scanline_max_embedding_dist;
    const float beam_dist_factor = 1 + float(enable_interlacing);
    const float target_num_pixels = 50;

    const float delta_target = 2 * max_embedding_dist / (beam_dist_factor * target_num_pixels);
    const float delta_left = 2 * max_embedding_dist / (beam_dist_factor * scanline_num_pixels_left);
    const float delta_right = 2 * max_embedding_dist / (beam_dist_factor * scanline_num_pixels_right);

    const float min_dist_target = -(max_embedding_dist - delta_target/2.0);
    const float min_dist_left = -(max_embedding_dist - delta_left/2.0);
    const float min_dist_right = -(max_embedding_dist - delta_right/2.0);

    float target_gauss_beam_integral = 0.0;
    for (int i = 0; i < target_num_pixels; i++) {
        const float d = min_dist_target + delta_target*i;
        target_gauss_beam_integral += get_gaussian_beam_strength(
            d, float3(1, 1, 1),
            sigma_range, shape_range
        ).r;
    }
    target_gauss_beam_integral *= delta_target;

    float approx_gauss_beam_integral_left = 0.0;
    for (int i = 0; i < scanline_num_pixels_left; i++) {
        const float d = min_dist_left + delta_left*i;
        approx_gauss_beam_integral_left += get_gaussian_beam_strength(
            d, float3(1, 1, 1),
            sigma_range, shape_range
        ).r;
    }
    approx_gauss_beam_integral_left *= delta_left;

    float approx_gauss_beam_integral_right = 0.0;
    for (int i = 0; i < scanline_num_pixels_right; i++) {
        const float d = min_dist_right + delta_right*i;
        approx_gauss_beam_integral_right += get_gaussian_beam_strength(
            d, float3(1, 1, 1),
            sigma_range, shape_range
        ).r;
    }
    approx_gauss_beam_integral_right *= delta_right;

    gauss_adj_factor = target_gauss_beam_integral / float2(
        approx_gauss_beam_integral_left,
        approx_gauss_beam_integral_right
    );
    // gauss_adj_factor = float2(1.0, 1.0);
}


void simulateEletronBeamsPS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 v_step : TEXCOORD1,
    in const float2 gauss_adj_factor_lr : TEXCOORD2,
    
    out float4 color : SV_Target
) {
    const float2 orig_linearized_size = tex2Dsize(samplerInterlaced);

    const float wrong_field = curr_line_is_wrong_field(texcoord, texcoord.y, orig_linearized_size.y);

    const float coord_is_left = float(texcoord.x <= 0.5);
    const float gauss_adj_factor = coord_is_left * gauss_adj_factor_lr.x + (1 - coord_is_left) * gauss_adj_factor_lr.y;

    // Digital shape
    //   Beam will be perfectly rectangular
    if (beam_shape_mode == 0) {
        // If we're in the current field, draw the beam
        //   wrong_field is always 0 when we aren't interlacing
        // Double the intensity when interlacing to maintain the same apparent brightness
        const float interlacing_brightness_factor = 1 + enable_interlacing * float(
            scanline_deinterlacing_mode != 1 &&
            scanline_deinterlacing_mode != 2
        );

        // const float3 scanline_color = tex2D_linearize(samplerInterlaced, texcoord, get_intermediate_gamma()).rgb;
        const float3 scanline_color = sample_single_scanline_horizontal(
            samplerInterlaced,
            texcoord, orig_linearized_size,
            1 / orig_linearized_size
        );

        const float3 scanline_intensity = (1 - wrong_field) * interlacing_brightness_factor * scanline_color;

        // Temporarily auto-dim the output to avoid clipping.
        color = encode_output(float4(scanline_intensity * levels_autodim_temp, 1.0), get_intermediate_gamma());
    }
    // else if (beam_shape_mode == 1) {

    // }
    // Gaussian Shape
    //   Beam will be a distorted Gaussian, dependent on color brightness and hyperparameters
    //   Will only consider contribution from nearest scanline
    else if (beam_shape_mode == 3) {
        //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
        //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
        //  vertex shader calculations, so static versions can be constant-folded.
        const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
        const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;

        // Find the texel position of the current scanline
        const float curr_line_texel_v = floor(texcoord.y * orig_linearized_size.y + under_half);
        const float curr_scanline_idx = get_curr_scanline_idx(texcoord, texcoord.y, orig_linearized_size.y);
        const float curr_scanline_start_v = curr_scanline_idx * scanline_num_pixels_fromtexcoord(texcoord);

        // Find the center of the current scanline
        //   For odd sizes, this is a texel. For even, this is between two texels
        const float half_num_pixels = scanline_num_pixels_fromtexcoord(texcoord) / 2;
        const float half_size = floor(half_num_pixels + under_half);
        const float num_pixels_is_even = float(half_size >= half_num_pixels);
        const float curr_scanline_center_v = curr_scanline_start_v + half_num_pixels - 0.5;

        /*
        // Find the center of the current scanline
        const float half_num_pixels = scanline_num_pixels_fromtexcoord(texcoord) / 2;
        const float half_size = floor(half_num_pixels + under_half);
        const float num_pixels_is_even = float(half_size >= half_num_pixels);
        const float upper_center = curr_scanline_start_v + half_size;
        // Lower on screen means larger y-coordinate
        const float curr_line_is_below_center = float(curr_line_texel_v > upper_center);
        const float shift_center = num_pixels_is_even * curr_line_is_below_center;
        
        const float curr_scanline_center_v = upper_center + shift_center;
        // const float curr_scanline_center_y = (curr_scanline_center_v + TEXCOORD_OFFSET) / orig_linearized_size.y;
        */

        // Find the center of the nearest in-field scanline
        const float curr_line_is_below_center = float(curr_line_texel_v > curr_scanline_center_v);
        const float source_offset_direction = lerp(-1, 1, curr_line_is_below_center);
        const float source_offset = source_offset_direction * wrong_field * scanline_num_pixels_fromtexcoord(texcoord);

        const float source_scanline_center_v = curr_scanline_center_v + source_offset;
        const float source_scanline_start_v = curr_scanline_start_v + source_offset;
        // const float source_scanline_center_y = (source_scanline_center_v + TEXCOORD_OFFSET) / orig_linearized_size.y;
        // const float2 source_scanline_center_xy = float2(texcoord.x, source_scanline_center_y);
        const float source_scanline_start_y = (source_scanline_start_v + TEXCOORD_OFFSET) / orig_linearized_size.y;
        const float2 source_scanline_start_xy = float2(texcoord.x, source_scanline_start_y);

        // Sample the nearest in-field scanline
        const float3 scanline_color = sample_single_scanline_horizontal(
            samplerInterlaced,
            source_scanline_start_xy, orig_linearized_size,
            1 / orig_linearized_size
        );
        // const float3 scanline_color = float3(1, 1, 1);

        // const float4 scanline_color = decode_input(
        //     tex2D(samplerInterlaced, source_scanline_center_xy),
        //     get_intermediate_gamma()
        // );

        // Calculate the beam strength based upon distance from the scanline
        //   and intensity of the sampled color
        // const float max_beam_dist = max(1, max_beam_dist_factor*half_size - 1);
        // const float max_beam_dist = max(1, beam_dist_factor*half_num_pixels);
        // const float min_beam_dist = num_pixels_is_even * 0.5;
        const float beam_dist_factor = 1 + float(enable_interlacing);
        const float pixel_delta = 2 * scanline_max_embedding_dist / (beam_dist_factor * scanline_num_pixels_fromtexcoord(texcoord));
        const float max_beam_dist = scanline_max_embedding_dist - pixel_delta/2.0;
        const float beam_dist_denom = half_num_pixels / scanline_max_embedding_dist;


        /*
        // For even-sized scanlines, offset by 0.5; so we take distance at the center of the texel
        // TODO: Applying to odd-sized scanlines instead helps with color mismatch. Not sure why.
        const float beam_dist_v_offset = num_pixels_is_even * 0.5;
        // const float beam_dist_v_offset = (1-num_pixels_is_even) * 0.5;
        // const float beam_dist_v_offset = 0.0;
        const float beam_dist_v_raw = curr_line_texel_v - source_scanline_center_v;
        const float beam_dist_v_root = round(abs(beam_dist_v_raw) - beam_dist_v_offset);
        const float beam_dist_v = sign(beam_dist_v_raw) * (beam_dist_v_root + beam_dist_v_offset);
        // const float beam_dist_v = abs(curr_line_texel_v - source_scanline_center_v);
        const float beam_dist_y = beam_power_adj_fromtexcoord(texcoord) * beam_dist_v / max_beam_dist;
        */
        const float beam_dist_v = curr_line_texel_v - source_scanline_center_v;
        const float beam_dist_y = scanline_max_embedding_dist * beam_dist_v / beam_dist_denom;
        // const float eq_dist = float(abs(abs(beam_dist_y) - max_beam_dist) <= 1e-5);
        
        // const float prev_dist_offset_v = source_offset_direction * 
        //     float(beam_dist_v > 0) * max(0.5, sign(beam_dist_y));
        // const float prev_dist_offset_y = prev_dist_offset_v / max_beam_dist;
        // const float prev_dist_y = beam_dist_y + prev_dist_offset_y;

        /*
        const float3 beam_strength = get_lowres_gaussian_beam_strength(
            beam_dist_y, scanline_color,
            sigma_range, shape_range
        ) * (1 - wrong_field);
        */
        
        const float3 beam_strength = get_linear_beam_strength(
            beam_dist_y, scanline_color,
            sigma_range, shape_range,
            num_pixels_is_even, texcoord
        );
        // const float3 beam_strength = scanline_color;

        const float interlacing_brightness_factor = 1 + enable_interlacing * float(
            scanline_deinterlacing_mode != 1 &&
            scanline_deinterlacing_mode != 2
        );

        // Output the corrected color
        // if (eq_dist) {
        //     color = encode_output(float4(1, 0, 0, 1), get_intermediate_gamma());
        // }
        // else {
        color = encode_output(float4(beam_strength * interlacing_brightness_factor, 1), get_intermediate_gamma());
        // }
        
        // color = encode_output(float4(scanline_color, 1), get_intermediate_gamma());
        // color = encode_output(float4(beam_dist_y, beam_dist_y, beam_dist_y, 1.0), get_intermediate_gamma());
    }
    // Gaussian Shape
    //   Beam will be a distorted Gaussian, dependent on color brightness and hyperparameters
    //   Will consider contributions from current scanline and two neighboring in-field scanlines
    else {
        //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
        //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
        //  vertex shader calculations, so static versions can be constant-folded.
        const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
        const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;

        // Find the texel position of the current scanline
        const float curr_line_texel_v = floor(texcoord.y * orig_linearized_size.y + under_half);
        const float curr_scanline_idx = get_curr_scanline_idx(texcoord, texcoord.y, orig_linearized_size.y);
        const float curr_scanline_start_v = curr_scanline_idx * scanline_num_pixels_fromtexcoord(texcoord);

        // Find the center of the current scanline
        const float half_num_pixels = scanline_num_pixels_fromtexcoord(texcoord) / 2;
        const float half_size = floor(half_num_pixels + under_half);
        const float num_pixels_is_even = float(half_size >= half_num_pixels);
        const float upper_center = curr_scanline_start_v + half_size;
        // Lower on screen means larger y-coordinate
        const float curr_line_is_below_center = float(curr_line_texel_v > upper_center);
        const float shift_center = num_pixels_is_even * curr_line_is_below_center;
        const float bounding_scanline_offset_v = (2 - wrong_field) * scanline_num_pixels_fromtexcoord(texcoord);

        const float3 scanline_offsets_v = float3(
            -bounding_scanline_offset_v,
            0,
            bounding_scanline_offset_v
        );
        const float3 scanline_centers_v = upper_center + shift_center + scanline_offsets_v;
        const float3 scanline_centers_y = (
            scanline_centers_v + TEXCOORD_OFFSET
        ) / orig_linearized_size.y;

        const float2 upper_scanline_center_xy = float2(texcoord.x, scanline_centers_y.x);
        const float2 curr_scanline_center_xy = float2(texcoord.x, scanline_centers_y.y);
        const float2 lower_scanline_center_xy = float2(texcoord.x, scanline_centers_y.z);

        const float3 upper_scanline_color = sample_single_scanline_horizontal(
            samplerInterlaced,
            upper_scanline_center_xy, orig_linearized_size,
            1 / orig_linearized_size
        );
        const float3 curr_scanline_color = sample_single_scanline_horizontal(
            samplerInterlaced,
            curr_scanline_center_xy, orig_linearized_size,
            1 / orig_linearized_size
        );
        const float3 lower_scanline_color = sample_single_scanline_horizontal(
            samplerInterlaced,
            lower_scanline_center_xy, orig_linearized_size,
            1 / orig_linearized_size
        );        

        // Calculate the beam strength based upon distance from the scanline
        //   and intensity of the sampled color
        const float scanlines_wider_than_1 = float(scanline_num_pixels_fromtexcoord(texcoord) > 1);
        const float max_beam_dist_factor = 1 + float(enable_interlacing);
        const float max_beam_dist = max(1, max_beam_dist_factor*half_size - 1);

        const float3 beam_dists_v = abs(curr_line_texel_v - scanline_centers_v);
        const float3 beam_dists_y = beam_dists_v / max_beam_dist;

        const float3 upper_beam_strength = get_gaussian_beam_strength(
            beam_dists_y.x, upper_scanline_color,
            sigma_range, shape_range
        );
        const float3 curr_beam_strength = get_gaussian_beam_strength(
            beam_dists_y.y, curr_scanline_color,
            sigma_range, shape_range
        );
        const float3 lower_beam_strength = get_gaussian_beam_strength(
            beam_dists_y.z, lower_scanline_color,
            sigma_range, shape_range
        );
        const float3 beam_strength = (
            upper_beam_strength +
            (1 - wrong_field) * curr_beam_strength +
            lower_beam_strength
        );

        // Output the corrected color
        color = encode_output(float4(beam_strength * levels_autodim_temp, 1), get_intermediate_gamma());   
    }
}

void beamConvergencePS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_TARGET
) {
    const float2 scanline_texture_size = tex2Dsize(samplerElectronBeams);
    const float2 scanline_texture_size_inv = 1.0 / scanline_texture_size;

    const float3 offset_sample = sample_rgb_scanline(
        samplerElectronBeams, texcoord,
        scanline_texture_size, scanline_texture_size_inv
    );

    color = float4(offset_sample, 1);
}