#ifndef _NEW_PHOSPHOR_MASK_RESIZING_H
#define _NEW_PHOSPHOR_MASK_RESIZING_H

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


//////////////////////////////////  INCLUDES  //////////////////////////////////

#include "user-settings.fxh"
#include "derived-settings-and-constants.fxh"
#include "bind-shader-params.fxh"

////////////////////////////  TILE SIZE CALCULATION  ///////////////////////////

//  The larger the resized tile, the fewer samples we'll need for downsizing.
//  See if we can get a static min tile size > mask_min_allowed_tile_size:
static const float mask_min_allowed_tile_size = macro_ceil(
    mask_min_allowed_triad_size * mask_triads_per_tile);

float2 get_resized_mask_tile_size(const float2 estimated_viewport_size,
    const float2 estimated_mask_resize_output_size,
    const bool solemnly_swear_same_inputs_for_every_pass)
{
    //  Requires:   The following global constants must be defined according to
    //              certainraints:
    //              1.) mask_resize_num_triads: Must be high enough that our
    //                  mask sampling method won't have artifacts later
    //                  (long story; see derived-settings-and-constants.h)
    //              2.) mask_resize_src_lut_size: Texel size of our mask LUT
    //              3.) mask_triads_per_tile: Num horizontal triads in our LUT
    //              4.) mask_min_allowed_triad_size: User setting (the more
    //                  restrictive it is, the faster the resize will go)
    //              5.) mask_min_allowed_tile_size_x < mask_resize_src_lut_size.x
    //              6.) mask_triad_width_{runtime, static}
    //              7.) mask_num_triads_across_{runtime, static}
    //              8.) mask_size_param must be 0.0/1.0 (false/true)
    //              The function parameters must be defined as follows:
    //              1.) estimated_viewport_size == (final viewport size);
    //                  If mask_size_param is 1.0/true and the viewport
    //                  estimate is wrong, the number of triads will differ from
    //                  the user's preference by about the same factor.
    //              2.) estimated_mask_resize_output_size: Must equal the
    //                  output size of the MASK_RESIZE pass.
    //                  Exception: The x component may be estimated garbage if
    //                  and only if the caller throws away the x result.
    //              3.) solemnly_swear_same_inputs_for_every_pass: Set to false,
    //                  unless you can guarantee that every call across every
    //                  pass will use the same sizes for the other parameters.
    //              When calling this across multiple passes, always use the
    //              same y viewport size/scale, and always use the same x
    //              viewport size/scale when using the x result.
    //  Returns:    Return the final size of a manually resized mask tile, after
    //              constraining the desired size to avoid artifacts.  Under
    //              unusual circumstances, tiles may become stretched vertically
    //              (see wall of text below).
    //  Stated tile properties must be correct:
    static const float tile_aspect_ratio_inv =
        mask_resize_src_lut_size.y/mask_resize_src_lut_size.x;
    static const float tile_aspect_ratio = 1.0/tile_aspect_ratio_inv;
    static const float2 tile_aspect = float2(1.0, tile_aspect_ratio_inv);
    //  If mask_size_param is 1.0/true and estimated_viewport_size.x is
    //  wrong, the user preference will be misinterpreted:
    const float desired_tile_size_x = mask_triads_per_tile * lerp(
        mask_triad_width,
        estimated_viewport_size.x / mask_num_triads_across,
        mask_size_param);
    // if(get_mask_sample_mode() > 0.5)
    if (false)
    {
        //  We don't need constraints unless we're sampling MASK_RESIZE.
        return desired_tile_size_x * tile_aspect;
    }
    //  Make sure we're not upsizing:
    const float temp_tile_size_x =
        min(desired_tile_size_x, mask_resize_src_lut_size.x);
    //  Enforce min_tile_size and max_tile_size in both dimensions:
    const float2 temp_tile_size = temp_tile_size_x * tile_aspect;
    static const float2 min_tile_size =
        mask_min_allowed_tile_size * tile_aspect;
    const float2 max_tile_size =
        estimated_mask_resize_output_size / mask_resize_num_tiles;
    const float2 clamped_tile_size =
        clamp(temp_tile_size, min_tile_size, max_tile_size);
    //  Try to maintain tile_aspect_ratio.  This is the tricky part:
    //  If we're currently resizing in the y dimension, the x components
    //  could be MEANINGLESS.  (If estimated_mask_resize_output_size.x is
    //  bogus, then so is max_tile_size.x and clamped_tile_size.x.)
    //  We can't adjust the y size based on clamped_tile_size.x.  If it
    //  clamps when it shouldn't, it won't clamp again when later passes
    //  call this function with the correct sizes, and the discrepancy will
    //  break the sampling coords in MASKED_SCANLINES.  Instead, we'll limit
    //  the x size based on the y size, but not vice versa, unless the
    //  caller swears the parameters were the same (correct) in every pass.
    //  As a result, triads could appear vertically stretched if:
    //  a.) mask_resize_src_lut_size.x > mask_resize_src_lut_size.y: Wide
    //      LUT's might clamp x more than y (all provided LUT's are square)
    //  b.) true_viewport_size.x < true_viewport_size.y: The user is playing
    //      with a vertically oriented screen (not accounted for anyway)
    //  c.) mask_resize_viewport_scale.x < masked_resize_viewport_scale.y:
    //      Viewport scales are equal by default.
    //  If any of these are the case, you can fix the stretching by setting:
    //      mask_resize_viewport_scale.x = mask_resize_viewport_scale.y *
    //          (1.0 / min_expected_aspect_ratio) *
    //          (mask_resize_src_lut_size.x / mask_resize_src_lut_size.y)
    const float x_tile_size_from_y =
        clamped_tile_size.y * tile_aspect_ratio;
    const float y_tile_size_from_x = lerp(clamped_tile_size.y,
        clamped_tile_size.x * tile_aspect_ratio_inv,
        float(solemnly_swear_same_inputs_for_every_pass));
    const float2 reclamped_tile_size = float2(
        min(clamped_tile_size.x, x_tile_size_from_y),
        min(clamped_tile_size.y, y_tile_size_from_x));
    //  We need integer tile sizes in both directions for tiled sampling to
    //  work correctly.  Use floor (to make sure we don't round up), but be
    //  careful to avoid a rounding bug where floor decreases whole numbers:
    const float2 final_resized_tile_size =
        floor(reclamped_tile_size + float2(FIX_ZERO(0.0), FIX_ZERO(0.0)));
    return final_resized_tile_size;
}

float3 get_downsizing_factor_and_true_tile_size() {
    const float triad_size = mask_size_param == 0 ?
        mask_triad_width :
        float(CONTENT_WIDTH) / mask_num_triads_across;

    const uint mask_sample_mode_desired = 0;
    const float2 true_tile_size_float = mask_sample_mode_desired < 1.5 ?
        triad_size * mask_triads_per_tile * float2(1, tile_aspect_inv) :
        content_size;

    const float downsizing_factor = mask_size_xy.x / (triad_size * mask_triads_per_tile);
    const float2 true_tile_size = floor(true_tile_size_float + FIX_ZERO(0.0));

    return float3(downsizing_factor, true_tile_size);
}


float4 lanczos_downsample_horiz(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes,
    const float weight_at_center
) {

    const int downsizing_factor_int = ceil(downsizing_factor);
    const float2 tex_uv_delta = float2(tex_invsize.x, 0);
    const int num_samples = 2 * num_sinc_lobes * downsizing_factor_int + 1;

    const float2 tex_uv_scaled = frac(tex_uv * float2(downsizing_factor, 1));

    const int stop_x_idx = num_sinc_lobes * downsizing_factor_int;
    const int start_x_idx = -stop_x_idx;
    const float sinc_dx = 2.0 * num_sinc_lobes / float(num_samples - 1);

    float w_sum = 0;
    float4 acc = float4(0, 0, 0, 0);
    for(int i = start_x_idx; i <= stop_x_idx; i++) {
        const float2 coord = tex_uv_scaled + i * tex_uv_delta;
        const float sinc_x = i * sinc_dx;
        const float weight = i != 0 ?
            num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x) :
            weight_at_center;

        w_sum += weight;
        acc += tex2Dlod(tex, float4(coord, 0, 0)) * weight;
    }

    return acc / w_sum;
}

float4 lanczos_downsample_vert(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes,
    const float weight_at_center
) {

    const int downsizing_factor_int = ceil(downsizing_factor);
    const float2 tex_uv_delta = float2(0, tex_invsize.y);
    const int num_samples = 2 * num_sinc_lobes * downsizing_factor_int + 1;

    const float2 tex_uv_scaled = frac(tex_uv * float2(1, downsizing_factor));

    const int stop_x_idx = num_sinc_lobes * downsizing_factor_int;
    const int start_x_idx = -stop_x_idx;
    const float sinc_dx = 2.0 * num_sinc_lobes / float(num_samples - 1);

    float w_sum = 0;
    float4 acc = float4(0, 0, 0, 0);
    for(int i = start_x_idx; i <= stop_x_idx; i++) {
        const float2 coord = tex_uv_scaled + i * tex_uv_delta;
        const float sinc_x = i * sinc_dx;
        const float weight = i != 0 ?
            num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x) :
            weight_at_center;

        w_sum += weight;
        acc += tex2Dlod(tex, float4(coord, 0, 0)) * weight;
    }

    return acc / w_sum;
}

float4 samplePhosphorMask(const float2 texcoord) {
    return float4(1, 1, 1, 1);
}

#endif  //  _NEW_PHOSPHOR_MASK_RESIZING_H