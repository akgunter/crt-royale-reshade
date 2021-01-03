#ifndef _NEW_PHOSPHOR_MASK_RESIZING_H
#define _NEW_PHOSPHOR_MASK_RESIZING_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
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


float4 lanczos_downsample_horiz(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes
) {
    const float2 tex_uv_delta = float2(tex_invsize.x, 0);
    const int num_samples = 1 + num_sinc_lobes * ceil(downsizing_factor);

    const float2 tex_uv_scaled = tex_uv * float2(downsizing_factor, 1);

    const int stop_x_idx = num_sinc_lobes * ceil(downsizing_factor);
    const int start_x_idx = -stop_x_idx;
    const float sinc_dx = 2.0 * num_sinc_lobes / float(num_samples - 1);

    float w_sum = 0;
    float4 acc = float4(0, 0, 0, 0);
    for(int i = start_x_idx; i <= stop_x_idx; i++) {
        const float2 coord = tex_uv_scaled + i * tex_uv_delta;
        const float sinc_x = i * sinc_dx;
        const float weight = i == 0 ? 1 : num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x);
        w_sum += weight;
        acc += tex2D(tex, coord) * weight;
    }

    return acc / w_sum;
}

float4 lanczos_downsample_vert(
    const sampler2D tex, const float2 tex_invsize,
    const float2 tex_uv, const float downsizing_factor, const int num_sinc_lobes
) {

    const float2 tex_uv_delta = float2(0, tex_invsize.y);
    const int num_samples = 1 + num_sinc_lobes * ceil(downsizing_factor);

    const float2 tex_uv_scaled = tex_uv * float2(1, downsizing_factor);

    const int stop_x_idx = num_sinc_lobes * ceil(downsizing_factor);
    const int start_x_idx = -stop_x_idx;
    const float sinc_dx = 2.0 * num_sinc_lobes / float(num_samples - 1);

    float w_sum = 0;
    float4 acc = float4(0, 0, 0, 0);
    for(int i = start_x_idx; i <= stop_x_idx; i++) {
        const float2 coord = tex_uv_scaled + i * tex_uv_delta;
        const float sinc_x = i * sinc_dx;
        const float weight = i == 0 ? 1 : num_sinc_lobes * sin(pi*sinc_x) * sin(pi*sinc_x/float(num_sinc_lobes)) / (pi*pi * sinc_x*sinc_x);
        w_sum += weight;
        acc += tex2D(tex, coord) * weight;
    }

    return acc / w_sum;
}

#endif  //  _NEW_PHOSPHOR_MASK_RESIZING_H