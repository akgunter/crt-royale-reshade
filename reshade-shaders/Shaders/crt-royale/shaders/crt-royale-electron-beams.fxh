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


void calculateBeamDistsVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0
) {
    const float compute_mask_factor = frame_count % 60 == 0 || overlay_active > 0;

	texcoord.x = (id == 2) ? compute_mask_factor*2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}


void calculateBeamDistsPS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 beam_strength : SV_Target
) {
    InterpolationFieldData interpolation_data = precalc_interpolation_field_data(texcoord);

    // We have to subtract off the texcoord offset to make sure we're using domain [0, 1]
    const float color_corrected = texcoord.x - 1.0 / TEX_BEAMDIST_WIDTH;

    // Digital shape
    //   Beam will be perfectly rectangular
	[branch]
    if (beam_shape_mode == 0) {
        // Double the intensity when interlacing to maintain the same apparent brightness
        const float interlacing_brightness_factor = 1 + float(
			enable_interlacing &&
			(scanline_deinterlacing_mode != 1) &&
			(scanline_deinterlacing_mode != 2)
		);
        const float raw_beam_strength = (1 - interpolation_data.scanline_parity * enable_interlacing) * interlacing_brightness_factor * levels_autodim_temp;

        beam_strength = float4(color_corrected * raw_beam_strength, 0, 0, 1);
    }
    // Linear shape
    //   Beam intensity will drop off linarly with distance from center
    //   Works better than gaussian with narrow scanlines (about 1-6 pixels wide)
    //   Will only consider contribution from nearest scanline
    else if (beam_shape_mode == 1) {
		const float beam_dist_y = triangle_wave(texcoord.y, interpolation_data.triangle_wave_freq);

        const bool scanline_is_wider_than_1 = scanline_num_pixels > 1;
        const bool deinterlacing_mode_requires_boost = (
            enable_interlacing &&
            (scanline_deinterlacing_mode != 1) &&
            (scanline_deinterlacing_mode != 2)
        );

        const float interlacing_brightness_factor = (1 + scanline_is_wider_than_1) * (1 + deinterlacing_mode_requires_boost);
		// const float raw_beam_strength = (1 - beam_dist_y) * (1 - interpolation_data.scanline_parity * enable_interlacing) * interlacing_brightness_factor * levels_autodim_temp;
		// const float raw_beam_strength = (1 - beam_dist_y);
		const float raw_beam_strength = saturate(-beam_dist_y * rcp(beam_linear_thickness) + 1);
        const float adj_beam_strength = raw_beam_strength * (1 - interpolation_data.scanline_parity * enable_interlacing) * interlacing_brightness_factor * levels_autodim_temp;

		beam_strength = float4(color_corrected * adj_beam_strength, 0, 0, 1);
    }
    // Gaussian Shape
    //   Beam will be a distorted Gaussian, dependent on color brightness and hyperparameters
    //   Will only consider contribution from nearest scanline
    else if (beam_shape_mode == 2) {
        //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
        //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
        //  vertex shader calculations, so static versions can be constant-folded.
        const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
        const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;

        const float beam_dist_factor = 1 + float(enable_interlacing);
        const float freq_adj = interpolation_data.triangle_wave_freq * rcp(beam_dist_factor);
        // The conditional 0.25*f offset ensures the interlaced scanlines align with the non-interlaced ones as in the other beam shapes
        const float frame_offset = enable_interlacing * (!interpolation_data.field_parity * 0.5 + 0.25) * rcp(freq_adj);
		const float beam_dist_y = triangle_wave(texcoord.y - frame_offset, freq_adj);

        const float interlacing_brightness_factor = 1 + float(
            !enable_interlacing &&
            (scanline_num_pixels > 1)
        ) + float(
            enable_interlacing &&
            (scanline_deinterlacing_mode != 1) &&
            (scanline_deinterlacing_mode != 2)
        );
        const float raw_beam_strength = get_gaussian_beam_strength(
            beam_dist_y, color_corrected,
            sigma_range, shape_range
        ) * interlacing_brightness_factor * levels_autodim_temp;

        beam_strength = float4(raw_beam_strength, 0, 0, 1);
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

        const float beam_dist_factor = (1 + float(enable_interlacing));
        const float freq_adj = interpolation_data.triangle_wave_freq * rcp(beam_dist_factor);
        // The conditional 0.25*f offset ensures the interlaced scanlines align with the non-interlaced ones as in the other beam shapes
        const float frame_offset = enable_interlacing * (!interpolation_data.field_parity * 0.5 + 0.25) * rcp(freq_adj);
		const float curr_beam_dist_y = triangle_wave(texcoord.y - frame_offset, freq_adj);
		const float upper_beam_dist_y = sawtooth_incr_wave(texcoord.y - frame_offset, freq_adj)*2 + 1;
        const float lower_beam_dist_y = 4 - upper_beam_dist_y;

        const float upper_beam_strength = get_gaussian_beam_strength(
            upper_beam_dist_y, color_corrected,
            sigma_range, shape_range
        );
        const float curr_beam_strength = get_gaussian_beam_strength(
            curr_beam_dist_y, color_corrected,
            sigma_range, shape_range
        );
        const float lower_beam_strength = get_gaussian_beam_strength(
            lower_beam_dist_y, color_corrected,
            sigma_range, shape_range
        );
        
        const float interlacing_brightness_factor = 1 + float(
            !enable_interlacing &&
            (scanline_num_pixels > 1)
        ) + float(
            enable_interlacing &&
            (scanline_deinterlacing_mode != 1) &&
            (scanline_deinterlacing_mode != 2)
        );
        const float3 raw_beam_strength = float3(curr_beam_strength, upper_beam_strength, lower_beam_strength) * interlacing_brightness_factor * levels_autodim_temp;

        beam_strength = float4(raw_beam_strength, 1);
    }
}


void simulateEletronBeamsVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float4 runtime_bin_shapes : TEXCOORD1
) {
    PostProcessVS(id, position, texcoord);

    // Mode 0: size of pixel in [0, 1] = pixel_dims / viewport_size
    // Mode 1: size of pixel in [0, 1] = viewport_size / grid_dims
    const float2 runtime_pixel_shape = (pixel_grid_mode == 0) ? pixel_shape * rcp(content_size) : rcp(pixel_grid_resolution);
    const float2 runtime_scanline_shape = float2(1, scanline_num_pixels) * rcp(content_size);
    runtime_bin_shapes = float4(runtime_pixel_shape, runtime_scanline_shape);
}

void simulateEletronBeamsPS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float4 runtime_bin_shapes : TEXCOORD1,
    
    out float4 color : SV_Target
) {
    InterpolationFieldData interpolation_data = calc_interpolation_field_data(texcoord);
    const float ypos = (texcoord.y * interpolation_data.triangle_wave_freq + interpolation_data.field_parity) * 0.5;

	float2 texcoord_scanlined = round_coord(texcoord, 0, runtime_bin_shapes.zw);

    // Sample from the neighboring scanline when in the wrong field
    [branch]
    if (interpolation_data.wrong_field) {
        const float coord_moved_up = texcoord_scanlined.y <= texcoord.y;
        const float direction = lerp(-1, 1, coord_moved_up);
        texcoord_scanlined.y += direction * scanline_num_pixels * rcp(content_size.y);
    }

    // Now we apply pixellation and cropping
    float2 texcoord_pixellated = round_coord(
        texcoord_scanlined,
        pixel_grid_offset * rcp(content_size),
		runtime_bin_shapes.xy
    );
    const float2 texcoord_uncropped = texcoord_pixellated * content_scale + content_offset;
	
	// [branch]
    if (beam_shape_mode < 3) {
		const float4 scanline_color = tex2D_linearize(
            ReShade::BackBuffer,
            texcoord_uncropped,
            get_input_gamma()
        );

        const float beam_strength_r = tex2D(samplerBeamDist, float2(scanline_color.r, ypos)).x;
        const float beam_strength_g = tex2D(samplerBeamDist, float2(scanline_color.g, ypos)).x;
        const float beam_strength_b = tex2D(samplerBeamDist, float2(scanline_color.b, ypos)).x;
        const float4 beam_strength = float4(beam_strength_r, beam_strength_g, beam_strength_b, 1);

        color = beam_strength;
    }
    else {
        const float2 offset = float2(0, scanline_num_pixels) * (1 + enable_interlacing) * rcp(content_size);

		const float4 curr_scanline_color = tex2D_linearize(
            ReShade::BackBuffer,
            texcoord_uncropped,
            get_input_gamma()
        );
        const float4 upper_scanline_color = tex2D_linearize(
            ReShade::BackBuffer,
            texcoord_uncropped - offset,
            get_input_gamma()
        );
        const float4 lower_scanline_color = tex2D_linearize(
            ReShade::BackBuffer,
            texcoord_uncropped + offset,
            get_input_gamma()
        );

        const float curr_beam_strength_r = tex2D(samplerBeamDist, float2(curr_scanline_color.r, ypos)).x;
        const float curr_beam_strength_g = tex2D(samplerBeamDist, float2(curr_scanline_color.g, ypos)).x;
        const float curr_beam_strength_b = tex2D(samplerBeamDist, float2(curr_scanline_color.b, ypos)).x;
        
        const float upper_beam_strength_r = tex2D(samplerBeamDist, float2(upper_scanline_color.r, ypos)).y;
        const float upper_beam_strength_g = tex2D(samplerBeamDist, float2(upper_scanline_color.g, ypos)).y;
        const float upper_beam_strength_b = tex2D(samplerBeamDist, float2(upper_scanline_color.b, ypos)).y;
        
        const float lower_beam_strength_r = tex2D(samplerBeamDist, float2(lower_scanline_color.r, ypos)).z;
        const float lower_beam_strength_g = tex2D(samplerBeamDist, float2(lower_scanline_color.g, ypos)).z;
        const float lower_beam_strength_b = tex2D(samplerBeamDist, float2(lower_scanline_color.b, ypos)).z;

        color = float4(
            curr_beam_strength_r + upper_beam_strength_r + lower_beam_strength_r,
            curr_beam_strength_g + upper_beam_strength_g + lower_beam_strength_g,
            curr_beam_strength_b + upper_beam_strength_b + lower_beam_strength_b,
            1
        );
    }
}

void beamConvergenceVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float run_convergence : TEXCOORD1
) {
    PostProcessVS(id, position, texcoord);
    const uint3 x_flag = convergence_offset_x != 0;
    const uint3 y_flag = convergence_offset_y != 0;
    run_convergence = dot(x_flag, 1) + dot(y_flag, 1);
}

void beamConvergencePS(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float run_convergence : TEXCOORD1,

    out float4 color : SV_TARGET
) {
    // [branch]
    if (!run_convergence) {
        color = tex2D(samplerElectronBeams, texcoord - float2(0, scanline_offset * rcp(content_size.y)));
    }
    else {
        const float3 offset_sample = sample_rgb_scanline(
            samplerElectronBeams, texcoord - float2(0, scanline_offset * rcp(content_size.y)),
            TEX_ELECTRONBEAMS_SIZE, rcp(TEX_ELECTRONBEAMS_SIZE)
        );

        color = float4(offset_sample, 1);
    }
}