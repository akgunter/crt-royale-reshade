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


#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/scanline-functions.fxh"
#include "../lib/bloom-functions.fxh"
#include "../lib/blur-functions.fxh"


void vertexShader8(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float bloom_sigma_runtime : TEXCOORD1
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    float2 output_size = tex2Dsize(samplerOutput8);
    //  Calculate a runtime bloom_sigma in case it's needed:
    const float2 estimated_viewport_size = content_size;
    const float2 estimated_mask_resize_output_size = tex2Dsize(samplerOutput6);
    const float mask_tile_size_x = get_resized_mask_tile_size(estimated_viewport_size, estimated_mask_resize_output_size, true).x;
    bloom_sigma_runtime = get_min_sigma_to_blur_triad(
        mask_tile_size_x / mask_triads_per_tile, bloom_diff_thresh_);
}

void pixelShader8(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float bloom_sigma_runtime : TEXCOORD1,

    out float4 color : SV_Target
) {
    //  Sample the masked scanlines:
    const float3 intensity_dim = tex2D_linearize(samplerOutput7, texcoord, get_intermediate_gamma()).rgb;
    //  Get the full intensity, including auto-undimming, and mask compensation:
    const float auto_dim_factor = levels_autodim_temp;
    const float undim_factor = 1.0/auto_dim_factor;
    const float mask_amplify = get_mask_amplify();
    const float3 intensity = intensity_dim * undim_factor * mask_amplify * levels_contrast;

    //  Sample BLOOM_APPROX to estimate what a straight blur of masked scanlines
    //  would look like, so we can estimate how much energy we'll receive from
    //  blooming neighbors:
    const float3 phosphor_blur_approx = levels_contrast * tex2D_linearize(samplerOutput2, texcoord, get_intermediate_gamma()).rgb;

    //  Compute the blur weight for the center texel and the maximum energy we
    //  expect to receive from neighbors:
    const float bloom_sigma = get_final_bloom_sigma(bloom_sigma_runtime);
    const float center_weight = get_center_weight(bloom_sigma);
    const float3 max_area_contribution_approx =
        max(float3(0.0, 0.0, 0.0), phosphor_blur_approx - center_weight * intensity);
    //  Assume neighbors will blur 100% of their intensity (blur_ratio = 1.0),
    //  because it actually gets better results (on top of being very simple),
    //  but adjust all intensities for the user's desired underestimate factor:
    const float3 area_contrib_underestimate = bloom_underestimate_levels * max_area_contribution_approx;
    const float3 intensity_underestimate = bloom_underestimate_levels * intensity;
    //  Calculate the blur_ratio, the ratio of intensity we want to blur:
    #ifdef BRIGHTPASS_AREA_BASED
        //  This area-based version changes blur_ratio more smoothly and blurs
        //  more, clipping less but offering less phosphor differentiation:
        const float3 phosphor_blur_underestimate = bloom_underestimate_levels *
            phosphor_blur_approx;
        const float3 soft_intensity = max(intensity_underestimate,
            phosphor_blur_underestimate * mask_amplify);
        const float3 blur_ratio_temp =
            ((float3(1.0, 1.0, 1.0) - area_contrib_underestimate) /
            soft_intensity - float3(1.0, 1.0, 1.0)) / (center_weight - 1.0);
    #else
        const float3 blur_ratio_temp =
            ((float3(1.0, 1.0, 1.0) - area_contrib_underestimate) /
            intensity_underestimate - float3(1.0, 1.0, 1.0)) / (center_weight - 1.0);
    #endif
    const float3 blur_ratio = clamp(blur_ratio_temp, 0.0, 1.0);
    //  Calculate the brightpass based on the auto-dimmed, unamplified, masked
    //  scanlines, encode if necessary, and return!
    const float3 brightpass = intensity_dim *
        lerp(blur_ratio, float3(1.0, 1.0, 1.0), bloom_excess);
    
    color = encode_output(float4(brightpass, 1.0), get_intermediate_gamma());
}