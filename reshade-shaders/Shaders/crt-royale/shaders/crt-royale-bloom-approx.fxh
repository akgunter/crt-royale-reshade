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
#include "../lib/scanline-functions.fxh"
#include "../lib/blur-functions.fxh"
#include "../lib/bloom-functions.fxh"

#include "shared-objects.fxh"


float4 linear_downsample(
    const sampler2D tex,
    const float2 texcoord,
    const int total_num_samples,
    const float2 delta_uv
) {
    const float delta_d = rcp(total_num_samples + 1.0);
    const float i_offset = (total_num_samples + 1) * 0.5;

    float3 acc = 0;
    float w_sum = 0;
    for(int i = 0; i <= total_num_samples; i++) {
        const float d = (i + 1.0) * delta_d;
        const float2 coord = texcoord + delta_uv * (i - i_offset);
        // const float weight = triangle_wave(d, 1);
        const float weight = 1;
 
        acc += tex2D(tex, coord).rgb * weight;
        w_sum += weight;
    }
    
    return float4(acc / w_sum, 1);
}

void approximateBloomVertPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 delta_uv = blur_radius * float2(0.0, rcp(TEX_BEAMCONVERGENCE_HEIGHT));

    color = linear_downsample(
        samplerBeamConvergence, texcoord,
        BLOOMAPPROX_DOWNSIZING_FACTOR_INTERNAL,
        delta_uv
    );
}

void approximateBloomHorizPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 delta_uv = blur_radius * float2(rcp(TEX_BEAMCONVERGENCE_WIDTH), 0.0);

    color = linear_downsample(
        samplerBloomApproxVert, texcoord,
        BLOOMAPPROX_DOWNSIZING_FACTOR_INTERNAL,
        delta_uv
    );
}