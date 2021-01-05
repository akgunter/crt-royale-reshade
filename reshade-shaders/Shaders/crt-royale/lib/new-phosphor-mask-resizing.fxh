#ifndef _NEW_PHOSPHOR_MASK_RESIZING_H
#define _NEW_PHOSPHOR_MASK_RESIZING_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

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

void get_phosphor_mask_parameters(
    const float2 mask_size,
    const float2 viewport_size
) {
    const float downsizing_factor = mask_size.x / (mask_triad_size_desired * mask_triads_per_tile);
    const float2 true_tile_size = floor(mask_size / downsizing_factor) * downsizing_factor;
    const float2 tiles_per_screen = viewport_size / true_tile_size;

}

float4 lanczos_downsample_horiz(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes
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
        const float weight = i == 0 ?
            lanczos_weight_at_center :
            num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x);
        w_sum += weight;
        acc += tex2D(tex, coord) * weight;
    }

    return acc / w_sum;
}

float4 lanczos_downsample_vert(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes
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
        const float weight = i == 0 ?
            lanczos_weight_at_center :
            num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x);
        w_sum += weight;
        acc += tex2D(tex, coord) * weight;
    }

    return acc / w_sum;
}

#endif  //  _NEW_PHOSPHOR_MASK_RESIZING_H