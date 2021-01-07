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
#include "../lib/phosphor-mask-resizing.fxh"

#include "../lib/texture-settings.fxh"
#include "shared-objects.fxh"


void newPixelShader7(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    
    out float4 color : SV_Target
) {
    const float2 scanline_texture_size = tex2Dsize(samplerVerticalScanlines);
    // const float2 output_size = tex2Dsize(samplerMaskedScanlines);
    const float2 output_size = TEX_MASKEDSCANLINES_SIZE;

    //  Our various input textures use different coords.
    const float2 scanline_texture_size_inv = 1.0 / scanline_texture_size;

    //  This pass: Sample (misconverged?) scanlines to the final horizontal
    //  resolution, apply halation (bouncing electrons), and apply the phosphor
    //  mask.  Fake a bloom if requested.  Unless we fake a bloom, the output
    //  will be dim from the scanline auto-dim, mask dimming, and low gamma.

    //  Horizontally sample the current row (a vertically interpolated scanline)
    //  and account for horizontal convergence offsets, given in units of texels.
    const float3 scanline_color_dim = sample_rgb_scanline_horizontal(
        samplerVerticalScanlines, texcoord,
        scanline_texture_size, scanline_texture_size_inv);
    const float auto_dim_factor = levels_autodim_temp;

    const float2 true_tile_size = get_downsizing_factor_and_true_tile_size().yz;
    const float2 tiles_per_screen = content_size / true_tile_size;

    float3 phosphor_mask_sample;
    if(mask_sample_mode_desired > 0.5)
    {
        const float2 tile_uv_wrap = texcoord * tiles_per_screen;
        phosphor_mask_sample = samplePhosphorMask(tile_uv_wrap).rgb;
    }
    else
    {
        const float2 tile_uv_wrap = frac(texcoord * tiles_per_screen);
        const float2 tile_uv_crop = tile_uv_wrap * true_tile_size / TEX_MASKHORIZONTAL_SIZE;
        // const float2 tile_uv_crop = frac(texcoord * ceil(content_size / mask_size));

        //  Sample the resized mask, and avoid tiling artifacts:
        phosphor_mask_sample = tex2D(samplerMaskResizeHorizontal, tile_uv_crop).rgb;
    }

    //  Sample the halation texture (auto-dim to match the scanlines), and
    //  account for both horizontal and vertical convergence offsets, given
    //  in units of texels horizontally and same-field scanlines vertically:
    const float3 halation_color = tex2D_linearize(samplerBlurHorizontal, texcoord, get_intermediate_gamma()).rgb;

    //  Apply halation: Halation models electrons flying around under the glass
    //  and hitting the wrong phosphors (of any color).  It desaturates, so
    //  average the halation electrons to a scalar.  Reduce the local scanline
    //  intensity accordingly to conserve energy.
    const float halation_intensity_dim_scalar = dot(halation_color, auto_dim_factor / float3(3, 3, 3));
    const float3 halation_intensity_dim = halation_intensity_dim_scalar * float3(1, 1, 1);
    const float3 electron_intensity_dim = lerp(scanline_color_dim, halation_intensity_dim, halation_weight);

    //  Apply the phosphor mask:
    const float3 phosphor_emission_dim = electron_intensity_dim * phosphor_mask_sample;
    
    #ifdef PHOSPHOR_BLOOM_FAKE
        //  The BLOOM_APPROX pass approximates a blurred version of a masked
        //  and scanlined image.  It's usually used to compute the brightpass,
        //  but we can also use it to fake the bloom stage entirely.  Caveats:
        //  1.) A fake bloom is conceptually different, since we're mixing in a
        //      fully blurred low-res image, and the biggest implication are:
        //  2.) If mask_amplify is incorrect, results deteriorate more quickly.
        //  3.) The inaccurate blurring hurts quality in high-contrast areas.
        //  4.) The bloom_underestimate_levels parameter seems less sensitive.
        //  Reverse the auto-dimming and amplify to compensate for mask dimming:
		#define PHOSPHOR_BLOOM_FAKE_WITH_SIMPLE_BLEND
        #ifdef PHOSPHOR_BLOOM_FAKE_WITH_SIMPLE_BLEND
            static const float blur_contrast = 1.05;
        #else
            static const float blur_contrast = 1.0;
        #endif
        const float mask_amplify = get_mask_amplify();
        const float undim_factor = 1.0/auto_dim_factor;
        const float3 phosphor_emission =
            phosphor_emission_dim * undim_factor * mask_amplify;
        //  Get a phosphor blur estimate, accounting for convergence offsets:
        const float3 electron_intensity = electron_intensity_dim * undim_factor;
        const float3 phosphor_blur_approx_soft = tex2D_linearize(
            samplerBloomApprox, texcoord, get_intermediate_gamma()).rgb;
        const float3 phosphor_blur_approx = lerp(phosphor_blur_approx_soft,
            electron_intensity, 0.1) * blur_contrast;
        //  We could blend between phosphor_emission and phosphor_blur_approx,
        //  solving for the minimum blend_ratio that avoids clipping past 1.0:
        //      1.0 >= total_intensity
        //      1.0 >= phosphor_emission * (1.0 - blend_ratio) +
        //              phosphor_blur_approx * blend_ratio
        //      blend_ratio = (phosphor_emission - 1.0)/
        //          (phosphor_emission - phosphor_blur_approx);
        //  However, this blurs far more than necessary, because it aims for
        //  full brightness, not minimal blurring.  To fix it, base blend_ratio
        //  on a max area intensity only so it varies more smoothly:
        const float3 phosphor_blur_underestimate =
            phosphor_blur_approx * bloom_underestimate_levels;
        const float3 area_max_underestimate =
            phosphor_blur_underestimate * mask_amplify;
        #ifdef PHOSPHOR_BLOOM_FAKE_WITH_SIMPLE_BLEND
            const float3 blend_ratio_temp =
                (area_max_underestimate - float3(1.0, 1.0, 1.0)) /
                (area_max_underestimate - phosphor_blur_underestimate);
        #else
            //  Try doing it like an area-based brightpass.  This is nearly
            //  identical, but it's worth toying with the code in case I ever
            //  find a way to make it look more like a real bloom.  (I've had
            //  some promising textures from combining an area-based blend ratio
            //  for the phosphor blur and a more brightpass-like blend-ratio for
            //  the phosphor emission, but I haven't found a way to make the
            //  brightness correct across the whole color range, especially with
            //  different bloom_underestimate_levels values.)
            const float desired_triad_size = lerp(mask_triad_size_desired,
                output_size.x/mask_num_triads_desired,
                mask_specify_num_triads);
            const float bloom_sigma = get_min_sigma_to_blur_triad(
                desired_triad_size, bloom_diff_thresh);
            const float center_weight = get_center_weight(bloom_sigma);
            const float3 max_area_contribution_approx =
                max(float3(0.0, 0.0, 0.0), phosphor_blur_approx -
                center_weight * phosphor_emission);
            const float3 area_contrib_underestimate =
                bloom_underestimate_levels * max_area_contribution_approx;
            const float3 blend_ratio_temp =
                ((float3(1.0, 1.0, 1.0) - area_contrib_underestimate) /
                area_max_underestimate - float3(1.0, 1.0, 1.0)) / (center_weight - 1.0);
        #endif
        //  Clamp blend_ratio in case it's out-of-range, but be SUPER careful:
        //  min/max/clamp are BIZARRELY broken with lerp (optimization bug?),
        //  and this redundant sequence avoids bugs, at least on nVidia cards:
        const float3 blend_ratio_clamped = max(clamp(blend_ratio_temp, 0.0, 1.0), 0.0);
        const float3 blend_ratio = lerp(blend_ratio_clamped, float3(1.0,1.0,1.0), bloom_excess);
        //  Blend the blurred and unblurred images:
        const float3 phosphor_emission_unclipped =
            lerp(phosphor_emission, phosphor_blur_approx, blend_ratio);
        //  Simulate refractive diffusion by reusing the halation sample.
        const float3 pixel_color = lerp(phosphor_emission_unclipped,
            halation_color, diffusion_weight);
    #else
        const float3 pixel_color = phosphor_emission_dim;
    #endif
    //  Encode if necessary, and output.
    
    color = encode_output(float4(pixel_color, 1.0), get_intermediate_gamma());
}